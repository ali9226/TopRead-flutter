// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'dart:math' as math;
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';
import '../game/models.dart';
import '../style.dart';
import 'scene_layout.dart';
import 'layout_debug_style.dart';

/// 仅由 debug 构建挂载；关闭时不遍历牌阵，也不绘制碰撞或文字。
class QuestLayoutDebug extends StatefulWidget {
  const QuestLayoutDebug({
    super.key,
    required this.state,
    required this.layout,
  });
  final TileQuestState state;
  final QuestSceneLayout layout;

  @override
  State<QuestLayoutDebug> createState() => _QuestLayoutDebugState();
}

class _QuestLayoutDebugState extends State<QuestLayoutDebug> {
  bool _enabled = const bool.fromEnvironment('TILE_QUEST_LAYOUT_DEBUG');

  @override
  Widget build(BuildContext context) {
    final layout = widget.layout;
    final tiles = _enabled
        ? widget.state.tiles.where((tile) => !tile.is_removed).toList()
        : const <TileQuestTile>[];
    final counts = <int, int>{};
    for (final tile in tiles) {
      counts.update(tile.layer, (count) => count + 1, ifAbsent: () => 1);
    }
    final layers = counts.keys.toList()..sort();
    final choices = tiles.where((tile) => !tile.is_blocked).length;
    final toggle = _toggle_rect(layout);
    return Stack(
      children: [
        if (_enabled) ...[
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                key: const ValueKey('tile_quest_layout_debug_rects'),
                painter: _QuestLayoutDebugPainter(tiles, layout),
              ),
            ),
          ),
          Positioned(
            top: layout.header.bottom + QuestLayoutDebugStyle.button_extent,
            right: QuestLayoutDebugStyle.inset,
            width: math.min(
              QuestLayoutDebugStyle.panel_width,
              layout.size.width - QuestLayoutDebugStyle.inset * 2,
            ),
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: QuestLayoutDebugStyle.panel_color,
                  borderRadius: BorderRadius.circular(QuestLayoutDebugStyle.radius),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(QuestLayoutDebugStyle.panel_padding),
                  child: Text(
                    'seed ${widget.state.seed}\n'
                    'clickable $choices  blocked ${tiles.length - choices}\n'
                    '${layers.map((layer) => 'L$layer:${counts[layer]}').join('  ')}',
                    key: const ValueKey('tile_quest_layout_debug_stats'),
                    style: TextStyle(
                      color: TileQuestStyle.cream,
                      fontSize: QuestLayoutDebugStyle.stats_size,
                      height: QuestLayoutDebugStyle.line_height,
                      fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        if (toggle != null)
          Positioned.fromRect(
            rect: toggle,
            child: SizedBox.square(
              dimension: QuestLayoutDebugStyle.button_extent,
              child: IconButton(
                key: const ValueKey('tile_quest_layout_debug_toggle'),
                tooltip: 'Layout debug',
                onPressed: () => setState(() => _enabled = !_enabled),
                icon: Icon(
                  _enabled ? Icons.grid_off_rounded : Icons.grid_on_rounded,
                  color: _enabled ? TileQuestStyle.gold : TileQuestStyle.pale,
                  size: QuestLayoutDebugStyle.icon_size,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 紧凑顶栏没有第二行空位；在真实未占用的棋盘边角安放调试入口。
  /// 无安全空位时不创建浮层，不能盖住重开、牌面或任何游戏控件。
  Rect? _toggle_rect(QuestSceneLayout layout) {
    // 顶栏工具行（返回/声音/重开）整行不可覆盖，与 compact 无关。
    final toolbar = Rect.fromLTWH(
      layout.header.left,
      layout.header.top,
      layout.header.width,
      TileQuestStyle.toolbar_height,
    );
    final candidates = <Rect>[
      if (!layout.compact_header)
        Rect.fromLTWH(
          layout.header.right - QuestLayoutDebugStyle.button_extent,
          layout.header.bottom - QuestLayoutDebugStyle.button_extent,
          QuestLayoutDebugStyle.button_extent,
          QuestLayoutDebugStyle.button_extent,
        ),
      for (final corner in [
        layout.board.topRight,
        layout.board.topLeft,
        layout.board.bottomRight,
        layout.board.bottomLeft,
      ])
        Rect.fromLTWH(
          corner.dx == layout.board.right
              ? corner.dx - QuestLayoutDebugStyle.button_extent
              : corner.dx,
          corner.dy == layout.board.bottom
              ? corner.dy - QuestLayoutDebugStyle.button_extent
              : corner.dy,
          QuestLayoutDebugStyle.button_extent,
          QuestLayoutDebugStyle.button_extent,
        ),
    ];
    final cards = widget.state.tiles
        .where((tile) => !tile.is_removed)
        .map(layout.board_tile)
        .toList();
    for (final candidate in candidates) {
      if (candidate.overlaps(layout.tools) ||
          candidate.overlaps(layout.reserve) ||
          candidate.overlaps(layout.tray)) {
        continue;
      }
      if (candidate.overlaps(toolbar) || candidate.overlaps(layout.header)) {
        continue;
      }
      if (!cards.any(candidate.overlaps)) return candidate;
    }
    return null;
  }
}

/// 边框直接使用游戏布局矩形，调试层不参与命中，避免改变真实点牌行为。
class _QuestLayoutDebugPainter extends CustomPainter {
  _QuestLayoutDebugPainter(this.tiles, this.layout);
  final List<TileQuestTile> tiles;
  final QuestSceneLayout layout;

  @override
  void paint(Canvas canvas, Size size) {
    final ordered = List<TileQuestTile>.of(tiles)
      ..sort((left, right) => left.layer.compareTo(right.layer));
    for (final tile in ordered) {
      final rect = layout.board_tile(tile);
      final color = tile.is_blocked
          ? QuestLayoutDebugStyle.blocked_color
          : QuestLayoutDebugStyle.open_color;
      canvas.drawRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = QuestLayoutDebugStyle.stroke_width
          ..color = color,
      );
      final text = TextPainter(
        text: TextSpan(
          text: 'L${tile.layer}\n${tile.region_id}',
          style: TextStyle(
            color: color,
            backgroundColor: QuestLayoutDebugStyle.panel_color,
            fontSize: QuestLayoutDebugStyle.tile_size,
            fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: rect.width);
      text.paint(canvas, rect.topLeft);
      text.dispose();
    }
  }

  @override
  bool shouldRepaint(covariant _QuestLayoutDebugPainter old) =>
      old.tiles != tiles || old.layout != layout;
}
