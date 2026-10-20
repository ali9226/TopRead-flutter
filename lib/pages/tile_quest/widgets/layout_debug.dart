// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'dart:math' as math;
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';
import '../game/models.dart';
import '../style.dart';
import 'scene_layout.dart';

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
            top: layout.header.bottom + _DebugStyle.button_extent,
            right: _DebugStyle.inset,
            width: math.min(
              _DebugStyle.panel_width,
              layout.size.width - _DebugStyle.inset * 2,
            ),
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _DebugStyle.panel_color,
                  borderRadius: BorderRadius.circular(_DebugStyle.radius),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(_DebugStyle.panel_padding),
                  child: Text(
                    'seed ${widget.state.seed}\n'
                    'clickable $choices  blocked ${tiles.length - choices}\n'
                    '${layers.map((layer) => 'L$layer:${counts[layer]}').join('  ')}',
                    key: const ValueKey('tile_quest_layout_debug_stats'),
                    style: TextStyle(
                      color: TileQuestStyle.cream,
                      fontSize: _DebugStyle.stats_size,
                      height: _DebugStyle.line_height,
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
              dimension: _DebugStyle.button_extent,
              child: IconButton(
                key: const ValueKey('tile_quest_layout_debug_toggle'),
                tooltip: 'Layout debug',
                onPressed: () => setState(() => _enabled = !_enabled),
                icon: Icon(
                  _enabled ? Icons.grid_off_rounded : Icons.grid_on_rounded,
                  color: _enabled ? TileQuestStyle.gold : TileQuestStyle.pale,
                  size: _DebugStyle.icon_size,
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
          layout.header.right - _DebugStyle.button_extent,
          layout.header.bottom - _DebugStyle.button_extent,
          _DebugStyle.button_extent,
          _DebugStyle.button_extent,
        ),
      for (final corner in [
        layout.board.topRight,
        layout.board.topLeft,
        layout.board.bottomRight,
        layout.board.bottomLeft,
      ])
        Rect.fromLTWH(
          corner.dx == layout.board.right
              ? corner.dx - _DebugStyle.button_extent
              : corner.dx,
          corner.dy == layout.board.bottom
              ? corner.dy - _DebugStyle.button_extent
              : corner.dy,
          _DebugStyle.button_extent,
          _DebugStyle.button_extent,
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
          ? _DebugStyle.blocked_color
          : _DebugStyle.open_color;
      canvas.drawRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _DebugStyle.stroke_width
          ..color = color,
      );
      final text = TextPainter(
        text: TextSpan(
          text: 'L${tile.layer}\n${tile.region_id}',
          style: TextStyle(
            color: color,
            backgroundColor: _DebugStyle.panel_color,
            fontSize: _DebugStyle.tile_size,
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

/// 调试样式独立于游戏视觉，生产构建不会创建调试组件。
class _DebugStyle {
  static const double button_extent = 44;
  static const double icon_size = 18;
  static const double inset = 4;
  static const double panel_width = 260;
  static const double panel_padding = 8;
  static const double radius = 8;
  static const double stats_size = 10;
  static const double tile_size = 7;
  static const double line_height = 1.3;
  static const double stroke_width = .8;
  static const Color panel_color = Color(0xDD091628);
  static const Color blocked_color = Color(0xFFFFAE7C);
  static const Color open_color = Color(0xFF7CFFCE);
}
