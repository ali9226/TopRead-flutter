// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'package:flutter/material.dart';
import '../game/layout_patterns.dart';
import '../game/models.dart';
import '../style.dart';

/// 短高窗口只压缩独立牌岛之间的留白，保留各岛全部真实相交关系。
/// 已移除牌仍参与包络计算，消牌和收起/展开均不会重建或改写牌局。
class QuestCompactBoardLayout {
  QuestCompactBoardLayout(List<TileQuestTile> tiles) {
    final bounds = <String, Rect>{};
    for (final tile in tiles) {
      final region = tile.region_id == 'core' ? 'main' : tile.region_id;
      final rect = Rect.fromLTWH(tile.x, tile.y, tile.width, tile.height);
      bounds[region] = bounds[region]?.expandToInclude(rect) ?? rect;
    }
    final main = bounds['main'];
    final top = bounds['side_top'];
    final bottom = bounds['side_bottom'];
    if (main == null || top == null || bottom == null || bounds.length != 3) {
      return;
    }
    // 旧存档或手工牌阵存在跨区依赖时保持原位，不能为了适配而改变规则。
    if (main.overlaps(top) || main.overlaps(bottom) || top.overlaps(bottom)) {
      return;
    }
    if (main.height > TileQuestLayoutPatterns.main_rows + _epsilon ||
        top.height > 1 + _epsilon ||
        bottom.height > 1 + _epsilon) {
      return;
    }
    _translations.addAll({
      'side_top': Offset(0, -top.top),
      'main': Offset(0, top.height + gap - main.top),
      'side_bottom': Offset(
        0,
        top.height + gap + main.height + gap - bottom.top,
      ),
    });
  }

  static const double _epsilon = .000001;
  static const double gap = TileQuestStyle.compact_island_gap;
  static const double reference_rows =
      TileQuestLayoutPatterns.main_rows + 2 + gap * 2;
  final Map<String, Offset> _translations = {};

  bool get reflowed => _translations.isNotEmpty;

  Offset position(TileQuestTile tile) =>
      Offset(tile.x, tile.y) +
      (_translations[tile.region_id == 'core' ? 'main' : tile.region_id] ??
          Offset.zero);
}
