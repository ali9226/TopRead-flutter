// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../game/models.dart';
import '../game/config.dart';
import '../style.dart';

/// 棋盘、槽位背景和飞牌共用的坐标表；所有矩形均相对游戏场景。
class QuestSceneLayout {
  QuestSceneLayout(this.size, TileQuestState state) {
    final landscape = size.width > size.height * _landscape_ratio;
    final small = size.height < _small_height;
    final inset = size.width < _narrow_width
        ? _narrow_inset
        : TileQuestStyle.page_inset;
    final full_header = Rect.fromLTWH(
      inset,
      _header_top,
      size.width - inset * 2,
      TileQuestStyle.header_height,
    );

    if (landscape) {
      // 横屏保留左棋盘、右操作区；槽位先按宽度确定正方形尺寸。
      final controls_width = size.width * _controls_width_fraction;
      final controls_left = size.width - controls_width - inset;
      final tray_height = _tray_height(controls_width);
      header = Rect.fromLTWH(
        inset,
        _header_top,
        controls_left - inset * 2,
        TileQuestStyle.header_height,
      );
      final controls_top = _header_top;
      final controls_height = size.height - controls_top - _landscape_bottom;
      final reserve_height = _reserve_height_for(controls_width);
      final tools_height = math.min(
        _landscape_tools_height,
        math.max(
          _minimum_extent,
          controls_height - tray_height - reserve_height - _landscape_gap * 2,
        ),
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
        size.height - tools_height - _landscape_bottom,
        controls_width,
        tools_height,
      );
      board = Rect.fromLTWH(
        inset,
        TileQuestStyle.board_top - _landscape_board_offset,
        controls_left - inset * 2,
        math.max(_minimum_board_extent, size.height - _landscape_board_bottom),
      );
      tutorial = Rect.zero;
    } else {
      header = full_header;
      final controls_width = size.width - inset * 2;
      final tools_height = small ? _small_tools_height : _tools_height;
      final reserve_height = _reserve_height_for(controls_width);
      final tray_height = _tray_height(controls_width);
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
      tutorial = state.level == 1
          ? Rect.fromLTWH(
              inset,
              TileQuestStyle.tutorial_top,
              controls_width,
              _tutorial_height,
            )
          : Rect.zero;
      // Both levels reserve the same header/tutorial area. The introductory
      // footprint must never be enlarged just because it contains fewer cards.
      final board_top = TileQuestStyle.board_top;
      board = Rect.fromLTWH(
        inset + _board_inset,
        board_top,
        controls_width - _board_inset * 2,
        math.max(
          _minimum_board_extent,
          reserve.top - board_top - _board_bottom_gap,
        ),
      );
    }

    // 已消除方块仍参与边界计算，避免连续消除时棋盘发生缩放或跳动。
    min_x = state.tiles.isEmpty
        ? 0
        : state.tiles.map((tile) => tile.x).reduce(math.min);
    min_y = state.tiles.isEmpty
        ? 0
        : state.tiles.map((tile) => tile.y).reduce(math.min);
    final max_x = state.tiles.isEmpty
        ? 1.0
        : state.tiles.map((tile) => tile.x + tile.width).reduce(math.max);
    final max_y = state.tiles.isEmpty
        ? 1.0
        : state.tiles.map((tile) => tile.y + tile.height).reduce(math.max);
    final logical_width = math.max(_minimum_extent, max_x - min_x);
    final logical_height = math.max(_minimum_extent, max_y - min_y);
    unit = math.min(
      board.width / TileQuestConfig.board_logical_width,
      board.height / TileQuestConfig.board_logical_height,
    );
    board_origin =
        board.center -
        Offset(logical_width * unit / 2, logical_height * unit / 2);
  }

  // 槽背景、静态牌、移动牌只读取下列统一尺寸和坐标。
  static const int slot_count = 7;
  static const int reserve_count = 3;
  static const double tray_padding = 8;
  static const double tray_gap = 3;
  static const double tray_caption_height = 12;
  static const double tray_caption_gap = 2;
  static const double reserve_vertical_padding = 3;
  static const double reserve_right_padding = 5;
  static const double reserve_gap = 4;

  static const double _landscape_ratio = 1.3;
  static const double _small_height = 620;
  static const double _narrow_width = 350;
  static const double _narrow_inset = 12;
  static const double _header_top = 8;
  static const double _controls_width_fraction = .36;
  static const double _landscape_gap = 9;
  static const double _landscape_bottom = 10;
  static const double _landscape_tools_height = 80;
  static const double _landscape_board_offset = 33;
  static const double _landscape_board_bottom = 126;
  static const double _minimum_extent = 1;
  static const double _minimum_board_extent = 20;
  static const double _small_tools_height = 74;
  static const double _tools_height = 86;
  static const double _portrait_bottom = 12;
  static const double _portrait_gap = 10;
  static const double _tutorial_height = 26;
  static const double _board_inset = 2;
  static const double _board_bottom_gap = 8;
  static const double reserve_stack_lift = 8;

  final Size size;
  late final Rect header, tutorial, board, tray, reserve, tools;
  late final double min_x, min_y, unit;
  late final Offset board_origin;

  /// 七个槽按宽度均分，间距单独扣除，高度始终与宽度相同。
  static double _tray_edge(double width) =>
      (width - tray_padding * 2 - tray_gap * (slot_count - 1)) / slot_count;

  static double _tray_height(double width) =>
      _tray_edge(width) +
      tray_padding * 2 +
      tray_caption_gap +
      tray_caption_height;

  static double _reserve_height_for(double width) =>
      _tray_edge(width) +
      reserve_vertical_padding * 2 +
      reserve_stack_lift * (TileQuestConfig.remove_uses_per_challenge - 1);

  Rect board_tile(TileQuestTile tile) => Rect.fromLTWH(
    board_origin.dx + (tile.x - min_x) * unit,
    board_origin.dy + (tile.y - min_y) * unit,
    tile.width * unit,
    tile.height * unit,
  );

  /// 槽背景与牌都必须使用本矩形，禁止分别按组件高度推算槽位。
  Rect tray_tile(int index) {
    final edge = _tray_edge(tray.width);
    return Rect.fromLTWH(
      tray.left + tray_padding + index * (edge + tray_gap),
      tray.top + tray_padding,
      edge,
      edge,
    );
  }

  Rect get tray_caption => Rect.fromLTWH(
    tray.left + tray_padding,
    tray_tile(0).bottom + tray_caption_gap,
    tray.width - tray_padding * 2,
    tray_caption_height,
  );

  /// 备用槽也共用统一矩形，背景和返回动画不会各自多出边距。
  Rect reserve_tile(int index, {int depth = 0}) {
    final edge = tray_tile(0).width;
    return Rect.fromLTWH(
      reserve.right -
          reserve_right_padding -
          (reserve_count - index) * edge -
          (reserve_count - index - 1) * reserve_gap,
      reserve.bottom -
          reserve_vertical_padding -
          edge -
          depth * reserve_stack_lift,
      edge,
      edge,
    );
  }

  Rect get reserve_label => Rect.fromLTWH(
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
