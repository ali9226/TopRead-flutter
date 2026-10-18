// ignore_for_file: non_constant_identifier_names
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import '../game/models.dart';
import '../style.dart';
import 'scene_layout.dart';
import 'shuffle_textures.dart';
import 'tile_batch.dart';
import 'tile_card.dart';
import 'tile_frame.dart';
import 'tile_surface.dart';

/// 数百张静态牌只占一个绘制节点，输入按真实层序逆向命中。
class QuestBoardCanvas extends StatelessWidget {
  QuestBoardCanvas({
    super.key,
    required List<TileQuestTile> tiles,
    required QuestSceneLayout layout,
    required QuestShuffleTextures textures,
    required ValueListenable<int?> pressed,
    required this.on_press,
    required this.on_tile,
    required bool enabled,
  }) : painter = QuestBoardPainter(
         tiles: tiles,
         layout: layout,
         textures: textures,
         pressed: pressed,
         enabled: enabled,
         on_tile: on_tile,
       );
  final QuestBoardPainter painter;
  final ValueChanged<int?> on_press;
  final ValueChanged<int> on_tile;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (details) =>
        on_press(painter.tile_at(details.localPosition)?.id),
    onTapCancel: () => on_press(null),
    onTapUp: (details) {
      final tile = painter.tile_at(details.localPosition);
      on_press(null);
      if (tile != null && painter.enabled && !tile.blocked) on_tile(tile.id);
    },
    child: RepaintBoundary(
      child: CustomPaint(painter: painter, size: painter.layout.size),
    ),
  );
}

class QuestBoardPainter extends CustomPainter {
  QuestBoardPainter({
    required List<TileQuestTile> tiles,
    required this.layout,
    required this.textures,
    required this.pressed,
    required this.enabled,
    required this.on_tile,
  }) : _tiles = tiles,
       super(repaint: Listenable.merge([textures, pressed])) {
    final ordered = List<TileQuestTile>.of(tiles)
      ..sort((a, b) {
        final layer = a.layer.compareTo(b.layer);
        return layer == 0 ? a.id.compareTo(b.id) : layer;
      });
    frames = List.unmodifiable([
      for (final tile in ordered)
        QuestTileFrame(
          id: tile.id,
          type: tile.type,
          rect: layout.board_tile(tile),
          zone: QuestTileZone.board,
          blocked: tile.is_blocked,
        ),
    ]);
    _batch = QuestTileBatch(frames.length);
  }
  final List<TileQuestTile> _tiles;
  final QuestSceneLayout layout;
  final QuestShuffleTextures textures;
  final ValueListenable<int?> pressed;
  final bool enabled;
  final ValueChanged<int> on_tile;
  late final List<QuestTileFrame> frames;
  late final QuestTileBatch _batch;

  QuestTileFrame? tile_at(Offset point) {
    for (final frame in frames.reversed) {
      if (QuestTileSurface.contains(frame.rect, point)) return frame;
    }
    return null;
  }

  @override
  bool? hitTest(Offset position) => tile_at(position) != null;

  @override
  void paint(Canvas canvas, Size size) {
    _batch.begin();
    final ready = textures.ready;
    for (final frame in frames) {
      final rect = pressed.value == frame.id && enabled && !frame.blocked
          ? frame.rect.translate(
              0,
              frame.rect.height * TileQuestStyle.tile_press_depth_fraction,
            )
          : frame.rect;
      final source = ready
          ? textures.source_of(frame.type, blocked: frame.blocked)
          : null;
      if (source != null) {
        _batch.add(source, rect);
      } else {
        textures.paint_tile(canvas, rect, frame.type, blocked: frame.blocked);
      }
    }
    _batch.paint(canvas, textures);
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder =>
      (size) => [
        for (final frame in frames)
          if (!frame.blocked)
            CustomPainterSemantics(
              key: ValueKey('tile_quest_tile_${frame.id}'),
              rect: frame.rect,
              properties: SemanticsProperties(
                label: '${quest_tile_assets[frame.type]} ${frame.id}',
                textDirection: TextDirection.ltr,
                button: true,
                enabled: enabled,
                onTap: enabled ? () => on_tile(frame.id) : null,
              ),
            ),
      ];

  @override
  bool shouldRepaint(covariant QuestBoardPainter old) =>
      !listEquals(_tiles, old._tiles) ||
      layout.unit != old.layout.unit ||
      layout.board_origin != old.layout.board_origin ||
      layout.size != old.layout.size ||
      enabled != old.enabled ||
      textures != old.textures ||
      pressed != old.pressed;
  @override
  bool shouldRebuildSemantics(covariant QuestBoardPainter oldDelegate) =>
      shouldRepaint(oldDelegate);
}
