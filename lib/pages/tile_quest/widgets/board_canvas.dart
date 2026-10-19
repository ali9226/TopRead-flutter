// ignore_for_file: non_constant_identifier_names
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import '../game/models.dart';
import '../style.dart';
import 'board_reveal.dart';
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
    QuestBoardReveal? reveal,
  }) : painter = QuestBoardPainter(
         tiles: tiles,
         layout: layout,
         textures: textures,
         pressed: pressed,
         enabled: enabled,
         on_tile: on_tile,
         reveal: reveal,
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
    this.reveal,
  }) : _tiles = tiles,
       super(repaint: Listenable.merge([textures, pressed, reveal])) {
    final ordered = List<TileQuestTile>.of(tiles)
      ..sort((a, b) {
        final layer = a.layer.compareTo(b.layer);
        return layer == 0 ? a.id.compareTo(b.id) : layer;
      });
    final ordered_frames = <QuestTileFrame>[];
    for (final tile in ordered) {
      final frame = QuestTileFrame(
        id: tile.id,
        type: tile.type,
        rect: layout.board_tile(tile),
        zone: QuestTileZone.board,
        blocked: tile.is_blocked,
      );
      ordered_frames.add(frame);
    }
    frames = List.unmodifiable(ordered_frames);
    final removed_ids = {
      for (final tile in tiles)
        if (tile.is_removed) tile.id,
    };
    _paint_hidden_ids = Set.of(removed_ids);
    final top_by_rect = <Rect, QuestTileFrame>{};
    _pressed_underlays = {};
    for (final frame in frames) {
      if (removed_ids.contains(frame.id)) continue;
      final previous = top_by_rect[frame.rect];
      if (previous != null) {
        _paint_hidden_ids.add(previous.id);
        _pressed_underlays.remove(previous.id);
        if (!frame.blocked) _pressed_underlays[frame.id] = previous.id;
      }
      top_by_rect[frame.rect] = frame;
    }
    // 图集保留真实牌面透明圆角；绘制列表按层排序，不添加人工底板。
    _batch = QuestTileBatch(frames.length);
  }
  final List<TileQuestTile> _tiles;
  final QuestSceneLayout layout;
  final QuestShuffleTextures textures;
  final ValueListenable<int?> pressed;
  final bool enabled;
  final ValueChanged<int> on_tile;
  final QuestBoardReveal? reveal;
  late final List<QuestTileFrame> frames;
  late final QuestTileBatch _batch;
  late final Set<int> _paint_hidden_ids;
  late final Map<int, int> _pressed_underlays;

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
    final underlay = enabled ? _pressed_underlays[pressed.value] : null;
    if (textures.ready) {
      // drawRawAtlas保留从低层到高层的顺序，所有真实牌共用一次GPU提交。
      _batch.begin();
      for (final frame in frames) {
        if (_paint_hidden_ids.contains(frame.id) && frame.id != underlay) {
          continue;
        }
        _batch.add_reveal(
          textures.source_of(frame.type, blocked: false)!,
          textures.source_of(frame.type, blocked: true)!,
          _paint_rect(frame),
          reveal_amount_of(frame),
        );
      }
      _batch.paint(canvas, textures);
      return;
    }
    // 只有首次解码或素材切换才逐牌回退，同样保留素材自身的圆角透明度。
    for (final frame in frames) {
      if (_paint_hidden_ids.contains(frame.id) && frame.id != underlay) {
        continue;
      }
      textures.paint_tile(
        canvas,
        _paint_rect(frame),
        frame.type,
        blocked: frame.blocked,
        blocked_amount: reveal_amount_of(frame),
      );
    }
  }

  /// 完全同位下层只保留逻辑/命中数据，不重复叠加投影；半格覆盖不剔除。
  /// 按压顶牌发生微移时补直接下层，避免顶部短暂露出场景背景。
  List<QuestTileFrame> get painted_frames {
    final underlay = enabled ? _pressed_underlays[pressed.value] : null;
    return [
      for (final frame in frames)
        if (!_paint_hidden_ids.contains(frame.id) || frame.id == underlay)
          frame,
    ];
  }

  /// 实际视觉遮罩强度；规则/无障碍状态仍直接读取 frame.blocked。
  double reveal_amount_of(QuestTileFrame frame) =>
      reveal?.amount_of(frame.id, blocked: frame.blocked) ??
      (frame.blocked ? 1 : 0);

  /// 按压只移动实体牌，规则坐标始终保持不变。
  Rect _paint_rect(QuestTileFrame frame) =>
      pressed.value == frame.id && enabled && !frame.blocked
      ? frame.rect.translate(
          0,
          frame.rect.height * TileQuestStyle.tile_press_depth_fraction,
        )
      : frame.rect;

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
      pressed != old.pressed ||
      reveal != old.reveal;
  @override
  bool shouldRebuildSemantics(covariant QuestBoardPainter oldDelegate) =>
      shouldRepaint(oldDelegate);
}
