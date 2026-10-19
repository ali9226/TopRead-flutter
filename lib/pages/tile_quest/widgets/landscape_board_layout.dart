// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../game/layout_patterns.dart';
import '../game/models.dart';
import '../style.dart';

/// 横屏仅重排彼此独立的牌岛，不改变每个区域内部的网格、层序或遮挡。
/// 主阵和核心共用平移，方形辅助牌整岛转90度；旧存档保留原坐标。
class QuestLandscapeBoardLayout {
  QuestLandscapeBoardLayout(List<TileQuestTile> tiles) {
    final bounds = <String, Rect>{};
    for (final tile in tiles) {
      final region = _island(tile.region_id);
      final rect = Rect.fromLTWH(tile.x, tile.y, tile.width, tile.height);
      bounds[region] = bounds[region]?.expandToInclude(rect) ?? rect;
    }
    final main = bounds['main'];
    final upper = bounds['side_top'];
    final lower = bounds['side_bottom'];
    final gate = bounds['gate'];
    final recognized = bounds.keys.every(_regions.contains);
    // 当前规则模板的辅助牌与主阵至少隔一行。拒绝未知/相交区域，防止
    // 将手写或旧存档中的真实跨区依赖分开，造成视觉与引擎规则不一致。
    final islands = bounds.values.toList(growable: false);
    var independent = true;
    for (var left = 0; left < islands.length && independent; left++) {
      for (var right = left + 1; right < islands.length; right++) {
        if (islands[left].overlaps(islands[right])) independent = false;
      }
    }
    final square_helpers = tiles
        .where((tile) => _island(tile.region_id) != 'main')
        .every((tile) => (tile.width - tile.height).abs() < _epsilon);
    reflowed =
        recognized &&
        independent &&
        square_helpers &&
        main != null &&
        upper != null &&
        lower != null &&
        main.width <= TileQuestLayoutPatterns.main_columns + _epsilon &&
        main.height <= TileQuestLayoutPatterns.main_rows + _epsilon &&
        upper.width <= TileQuestLayoutPatterns.main_columns + _epsilon &&
        lower.width <= TileQuestLayoutPatterns.main_columns + _epsilon &&
        upper.height <= 1 + _epsilon &&
        lower.height <= 1 + _epsilon &&
        (gate == null ||
            // 旧版独立容量门需要短列下方的空间；新版容量链嵌在主岛，
            // 两条辅助岛都可使用六列，横屏各自转成完整六行竖列。
            (math.min(upper.width, lower.width) <= 3 + _epsilon &&
                gate.width <= 2 + _epsilon &&
                gate.height <= 1 + _epsilon));
    if (!reflowed) return;
    final auxiliary_left =
        TileQuestStyle.landscape_main_columns +
        TileQuestStyle.landscape_island_gap;
    final long_region = upper!.width >= lower!.width
        ? 'side_top'
        : 'side_bottom';
    final short_region = long_region == 'side_top' ? 'side_bottom' : 'side_top';
    final short_left = auxiliary_left + 1 + TileQuestStyle.landscape_island_gap;
    _origins.addAll(bounds);
    _destinations.addAll({
      'main': Offset.zero,
      long_region: Offset(auxiliary_left, 0),
      short_region: Offset(short_left, 0),
      if (gate != null) 'gate': Offset(short_left, _gate_top),
    });
  }

  static const double _epsilon = .000001;
  static const Set<String> _regions = {
    'main',
    'side_top',
    'side_bottom',
    'gate',
  };
  static const double _gate_top =
      3 + TileQuestStyle.landscape_auxiliary_rows_gap;
  static const double reference_width =
      TileQuestStyle.landscape_main_columns +
      2 +
      TileQuestStyle.landscape_island_gap * 2;
  late final bool reflowed;
  final Map<String, Rect> _origins = {};
  final Map<String, Offset> _destinations = {};

  static String _island(String region) => region == 'core' ? 'main' : region;

  /// 已移除牌也传入构造器并参与边界；消牌不会触发牌岛重新居中或缩放。
  Offset position(TileQuestTile tile) {
    final region = _island(tile.region_id);
    final origin = _origins[region];
    if (origin == null) return Offset(tile.x, tile.y);
    final local = region == 'main'
        ? Offset(tile.x - origin.left, tile.y - origin.top)
        : Offset(origin.bottom - tile.y - tile.height, tile.x - origin.left);
    return _destinations[region]! + local;
  }

  /// 教学和新模板共用横屏基准；跨度更大的旧牌阵安全缩小，不裁切内容。
  static Size fitting_size(Size actual) => Size(
    math.max(reference_width, actual.width),
    math.max(TileQuestStyle.landscape_reference_rows, actual.height),
  );
}
