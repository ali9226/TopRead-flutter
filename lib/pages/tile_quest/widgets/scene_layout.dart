// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'dart:math' as math;
import 'dart:ui' show DisplayFeature;
import 'package:flutter/material.dart';
import '../game/models.dart';
import '../game/config.dart';
import '../game/layout_patterns.dart';
import '../style.dart';
import 'landscape_board_layout.dart';
import 'compact_board_layout.dart';
import 'tile_surface_style.dart';
import 'playfield.dart';

/// 棋盘、槽位背景和飞牌共用的坐标表；所有矩形均相对游戏场景。
class QuestSceneLayout {
  QuestSceneLayout(
    this.size,
    TileQuestState state, {
    List<DisplayFeature> display_features = const [],
  }) {
    final columns = QuestPlayfield.split_columns(size, display_features);
    folded = columns != null;
    landscape =
        !folded && size.width > size.height * TileQuestStyle.landscape_ratio;
    compact_portrait =
        !landscape &&
        (folded || size.height < TileQuestStyle.compact_window_height);
    final inset = size.width < _narrow_width
        ? _narrow_inset
        : TileQuestStyle.page_inset;
    final full_header = Rect.fromLTWH(
      inset,
      _header_top,
      size.width - inset * 2,
      compact_portrait
          ? TileQuestStyle.compact_header_height
          : TileQuestStyle.header_height,
    );

    if (folded) {
      final board_pane = columns!.first;
      final controls_pane = columns.last;
      header = Rect.fromLTWH(
        board_pane.left + inset,
        _header_top,
        board_pane.width - inset * 2,
        TileQuestStyle.landscape_header_height,
      );
      board = Rect.fromLTWH(
        board_pane.left + TileQuestStyle.board_side_margin,
        header.bottom + TileQuestStyle.landscape_board_gap,
        board_pane.width - TileQuestStyle.board_side_margin * 2,
        size.height -
            header.bottom -
            TileQuestStyle.landscape_board_gap -
            TileQuestStyle.landscape_bottom_spacing,
      );
      final controls_width = controls_pane.width - inset * 2;
      final reserve_height = _reserve_height_for(controls_width);
      final tray_height = _tray_height(controls_width);
      const tools_height = TileQuestStyle.landscape_tools_height;
      final controls_height =
          reserve_height + tray_height + tools_height + _landscape_gap * 2;
      final top = (size.height - controls_height) / 2;
      reserve = Rect.fromLTWH(
        controls_pane.left + inset,
        top,
        controls_width,
        reserve_height,
      );
      tray = Rect.fromLTWH(
        reserve.left,
        reserve.bottom + _landscape_gap,
        controls_width,
        tray_height,
      );
      tools = Rect.fromLTWH(
        reserve.left,
        tray.bottom + _landscape_gap,
        controls_width,
        tools_height,
      );
      tutorial = state.level == 1
          ? Rect.fromLTWH(
              reserve.left,
              top - _tutorial_height - _landscape_gap,
              controls_width,
              _tutorial_height,
            )
          : Rect.zero;
    } else if (landscape) {
      // 横屏不再将九行竖向虚框塞进短边：中央牌岛与辅助牌岛横向排布，
      // 操作区独占右栏，保留完整44px顶栏及尽可能大的游戏区域。
      final controls_width = _landscape_controls_width(size, inset);
      final controls_left = size.width - controls_width - inset;
      final tray_height = _tray_height(controls_width);
      header = Rect.fromLTWH(
        inset,
        _header_top,
        controls_left - inset * 2,
        TileQuestStyle.landscape_header_height,
      );
      final reserve_height = _reserve_height_for(controls_width);
      final tools_height = math.min(
        TileQuestStyle.landscape_tools_height,
        math.max(
          _minimum_tool_height,
          size.height -
              reserve_height -
              tray_height -
              _landscape_gap * 2 -
              TileQuestStyle.landscape_bottom_spacing * 2,
        ),
      );
      final controls_height =
          reserve_height + tray_height + tools_height + _landscape_gap * 2;
      final controls_top = math.max(
        TileQuestStyle.landscape_bottom_spacing,
        (size.height - controls_height) / 2,
      );
      reserve = Rect.fromLTWH(
        controls_left,
        controls_top,
        controls_width,
        reserve_height,
      );
      tray = Rect.fromLTWH(
        controls_left,
        reserve.bottom + _landscape_gap,
        controls_width,
        tray_height,
      );
      tools = Rect.fromLTWH(
        controls_left,
        tray.bottom + _landscape_gap,
        controls_width,
        tools_height,
      );
      board = Rect.fromLTWH(
        TileQuestStyle.board_side_margin,
        header.bottom + TileQuestStyle.landscape_board_gap,
        controls_left -
            TileQuestStyle.landscape_controls_gap -
            TileQuestStyle.board_side_margin,
        math.max(
          _minimum_board_extent,
          size.height -
              header.bottom -
              TileQuestStyle.landscape_board_gap -
              TileQuestStyle.landscape_bottom_spacing,
        ),
      );
      tutorial = state.level == 1
          ? Rect.fromLTWH(
              controls_left,
              math.max(
                _header_top,
                controls_top - _tutorial_height - _landscape_gap,
              ),
              controls_width,
              _tutorial_height,
            )
          : Rect.zero;
    } else {
      header = full_header;
      final controls_width = size.width - inset * 2;
      const tools_height = _tools_height;
      final reserve_height = _reserve_height_for(controls_width);
      final tray_height = _tray_height(controls_width);
      if (compact_portrait) {
        // 托盘保持全宽；备用区与道具同行，为牌阵归还整行高度。
        final reserve_width =
            (controls_width * TileQuestStyle.compact_reserve_fraction).clamp(
              TileQuestStyle.compact_reserve_min_width,
              TileQuestStyle.compact_reserve_max_width,
            );
        final bottom_top = size.height - tools_height - _portrait_bottom;
        reserve = Rect.fromLTWH(inset, bottom_top, reserve_width, tools_height);
        tools = Rect.fromLTWH(
          reserve.right + TileQuestStyle.compact_bottom_gap,
          bottom_top,
          controls_width - reserve_width - TileQuestStyle.compact_bottom_gap,
          tools_height,
        );
        tray = Rect.fromLTWH(
          inset,
          bottom_top - tray_height - _portrait_gap,
          controls_width,
          tray_height,
        );
      } else {
        tools = Rect.fromLTWH(
          inset,
          size.height - tools_height - _portrait_bottom,
          controls_width,
          tools_height,
        );
        tray = Rect.fromLTWH(
          inset,
          tools.top - tray_height - _portrait_gap,
          controls_width,
          tray_height,
        );
        reserve = Rect.fromLTWH(
          inset,
          tray.top - reserve_height - _portrait_gap,
          controls_width,
          reserve_height,
        );
      }
      tutorial = state.level == 1
          ? compact_portrait
                ? Rect.fromLTWH(
                    inset,
                    tools.top,
                    controls_width,
                    _tutorial_height,
                  )
                : Rect.fromLTWH(
                    inset,
                    TileQuestStyle.tutorial_top,
                    controls_width,
                    _tutorial_height,
                  )
          : Rect.zero;
      // 两关使用同一完整逻辑棋盘尺度，教程牌群居中后为提示文字保留空间。
      final board_top = compact_portrait
          ? TileQuestStyle.compact_board_top
          : TileQuestStyle.board_top;
      // 棋盘单独使用更窄的左右留白：牌面本身承担视觉边界，两侧不需要
      // 和其他控件的页面边距一致，可以把省下的宽度全部给牌格。
      final board_margin = size.width < _narrow_width
          ? _narrow_board_margin
          : TileQuestStyle.board_side_margin;
      board = Rect.fromLTWH(
        board_margin,
        board_top,
        size.width - board_margin * 2,
        math.max(
          _minimum_board_extent,
          (compact_portrait ? tray.top : reserve.top) -
              board_top -
              _board_bottom_gap,
        ),
      );
    }

    _landscape_board = landscape
        ? QuestLandscapeBoardLayout(state.tiles)
        : null;
    _compact_board = compact_portrait
        ? QuestCompactBoardLayout(state.tiles)
        : null;
    // 已消除方块仍参与区域变换及边界计算，避免连续消除时缩放或跳动。
    min_x = state.tiles.isEmpty
        ? 0
        : state.tiles.map((tile) => _position(tile).dx).reduce(math.min);
    min_y = state.tiles.isEmpty
        ? 0
        : state.tiles.map((tile) => _position(tile).dy).reduce(math.min);
    final max_x = state.tiles.isEmpty
        ? 1.0
        : state.tiles
              .map((tile) => _position(tile).dx + tile.width)
              .reduce(math.max);
    final max_y = state.tiles.isEmpty
        ? 1.0
        : state.tiles
              .map((tile) => _position(tile).dy + tile.height)
              .reduce(math.max);
    final logical_width = math.max(_minimum_extent, max_x - min_x);
    final logical_height = math.max(_minimum_extent, max_y - min_y);
    // 规则模板的实际占宽为六列，而7×9只是存档/世界校验边界。
    // 教程与所有挑战使用相同参考尺度；手写/旧存档若跨度更大则安全缩小。
    final fitting = landscape
        ? QuestLandscapeBoardLayout.fitting_size(
            Size(logical_width, logical_height),
          )
        : Size(
            math.max(TileQuestLayoutPatterns.footprint_width, logical_width),
            math.max(
              compact_portrait
                  ? QuestCompactBoardLayout.reference_rows
                  : TileQuestConfig.board_logical_height,
              logical_height,
            ),
          );
    unit = math.min(
      board.width / fitting.width,
      board.height / (fitting.height * QuestTileSurfaceStyle.tile_aspect_ratio),
    );
    unit_y = unit * QuestTileSurfaceStyle.tile_aspect_ratio;
    board_origin =
        board.center -
        Offset(logical_width * unit / 2, logical_height * unit_y / 2);
  }

  // 槽背景、静态牌、移动牌只读取下列统一尺寸和坐标。
  static const int slot_count = 7;
  static const int reserve_count = 3;
  static const double tray_padding = 6;
  static const double tray_gap = 3;
  static const double reserve_vertical_padding = 2;
  static const double reserve_right_padding = 5;
  static const double reserve_gap = 4;

  static const double _narrow_width = 350;
  static const double _narrow_inset = 12;
  static const double _header_top = 8;
  static const double _landscape_gap = 9;
  static const double _minimum_tool_height = 44;
  static const double _minimum_extent = 1;
  static const double _minimum_board_extent = 20;
  static const double _tools_height = TileQuestStyle.portrait_tools_height;
  static const double _portrait_bottom = TileQuestStyle.portrait_bottom_spacing;
  static const double _portrait_gap = TileQuestStyle.portrait_controls_gap;
  static const double _tutorial_height = 26;
  static const double _narrow_board_margin = 4;
  static const double _board_bottom_gap = TileQuestStyle.board_bottom_spacing;
  static const double reserve_stack_lift = 6;

  /// 可调整上限集中在样式表；普通手机先铺满，横屏/平板再受上限约束。
  static const double maximum_tray_edge = TileQuestStyle.tray_tile_max_width;

  final Size size;
  late final bool landscape;
  late final bool folded;
  late final bool compact_portrait;
  bool get compact_header => landscape || compact_portrait;
  QuestCompactBoardLayout? _compact_board;
  QuestLandscapeBoardLayout? _landscape_board;
  late final Rect header, tutorial, board, tray, reserve, tools;
  late final double min_x, min_y, unit, unit_y;
  late final Offset board_origin;

  /// 七格共享可用宽度，不再施加二次缩小；超出最大牌宽时整组居中。
  static double _tray_edge(double width) => math.min(
    maximum_tray_edge,
    (width - tray_padding * 2 - tray_gap * (slot_count - 1)) / slot_count,
  );

  static double _tray_height(double width) =>
      _tray_edge(width) * QuestTileSurfaceStyle.tile_aspect_ratio +
      tray_padding * 2;

  /// 先给牌阵保留可读尺度，再把宽屏余量交给七格；手机短横屏仍由高度
  /// 限定牌宽，因此无需为扩大托盘而缩小原本可玩的主牌阵。
  static double _landscape_controls_width(Size size, double inset) {
    final minimum_tray_width =
        TileQuestStyle.readable_tray_tile_width * slot_count +
        tray_padding * 2 +
        tray_gap * (slot_count - 1);
    final board_height =
        size.height -
        _header_top -
        TileQuestStyle.landscape_header_height -
        TileQuestStyle.landscape_board_gap -
        TileQuestStyle.landscape_bottom_spacing;
    final board_unit = math.min(
      TileQuestStyle.readable_tray_tile_width,
      board_height /
          (TileQuestStyle.landscape_reference_rows *
              QuestTileSurfaceStyle.tile_aspect_ratio),
    );
    final available =
        size.width -
        inset -
        TileQuestStyle.board_side_margin -
        TileQuestStyle.landscape_controls_gap -
        QuestLandscapeBoardLayout.reference_width * board_unit;
    final preferred = (size.width * TileQuestStyle.wide_controls_fraction)
        .clamp(
          minimum_tray_width,
          maximum_tray_edge * slot_count +
              tray_padding * 2 +
              tray_gap * (slot_count - 1),
        );
    return math.min(
      preferred,
      math.max(TileQuestStyle.landscape_controls_min_width, available),
    );
  }

  /// 备用牌与七格托盘分别自适应；移出和返回动画读取相应目标矩形即可。
  static double _reserve_edge(double width) => math.min(
    TileQuestStyle.reserve_tile_max_width,
    _tray_edge(width) * TileQuestStyle.reserve_tile_width_scale,
  );

  static double _reserve_height_for(double width) =>
      _reserve_edge(width) * QuestTileSurfaceStyle.tile_aspect_ratio +
      reserve_vertical_padding * 2 +
      reserve_stack_lift * (TileQuestConfig.remove_uses_per_challenge - 1);

  Offset _position(TileQuestTile tile) =>
      _landscape_board?.position(tile) ??
      _compact_board?.position(tile) ??
      Offset(tile.x, tile.y);

  Rect board_tile(TileQuestTile tile) => Rect.fromLTWH(
    board_origin.dx + (_position(tile).dx - min_x) * unit,
    board_origin.dy + (_position(tile).dy - min_y) * unit_y,
    tile.width * unit,
    tile.height * unit_y,
  );

  /// 槽背景与牌都必须使用本矩形，禁止分别按组件高度推算槽位。
  Rect tray_tile(int index) {
    final edge = _tray_edge(tray.width);
    final occupied_width = edge * slot_count + tray_gap * (slot_count - 1);
    return Rect.fromLTWH(
      tray.center.dx - occupied_width / 2 + index * (edge + tray_gap),
      tray.top + tray_padding,
      edge,
      edge * QuestTileSurfaceStyle.tile_aspect_ratio,
    );
  }

  /// 备用槽也共用统一矩形，背景和返回动画不会各自多出边距。
  Rect reserve_tile(int index, {int depth = 0}) {
    final edge = compact_portrait && !folded
        ? math.min(
            TileQuestStyle.compact_reserve_max_edge,
            (reserve.width - reserve_right_padding * 2 - reserve_gap * 2) /
                reserve_count,
          )
        : _reserve_edge(reserve.width);
    final height = edge * QuestTileSurfaceStyle.tile_aspect_ratio;
    return Rect.fromLTWH(
      compact_portrait && !folded
          ? reserve.center.dx -
                (reserve_count * edge + (reserve_count - 1) * reserve_gap) / 2 +
                index * (edge + reserve_gap)
          : reserve.right -
                reserve_right_padding -
                (reserve_count - index) * edge -
                (reserve_count - index - 1) * reserve_gap,
      reserve.bottom -
          reserve_vertical_padding -
          height -
          depth * reserve_stack_lift,
      edge,
      height,
    );
  }

  Rect get reserve_label => compact_portrait && !folded
      ? Rect.fromLTWH(reserve.left, reserve.top, 0, 0)
      : Rect.fromLTWH(
          reserve.left,
          reserve.top,
          math.max(0.0, reserve_tile(0).left - reserve.left - tray_padding),
          reserve.height,
        );

  /// 根据事务快照查找牌的位置，历史动画和最终布局使用同一坐标表。
  Rect location(TileQuestState state, int id) {
    final tray_index = state.tray.indexOf(id);
    if (tray_index >= 0) return tray_tile(tray_index);
    if (state.reserve.contains(id)) {
      return reserve_tile(
        state.reserve_column(id),
        depth: state.reserve_depth(id),
      );
    }
    return board_tile(state.tile_by_id(id));
  }
}
