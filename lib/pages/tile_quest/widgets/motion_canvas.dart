// ignore_for_file: non_constant_identifier_names
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'match_particles.dart';
import 'scene_layout.dart';
import 'scene_motion.dart';
import 'shuffle_motion.dart';
import 'shuffle_textures.dart';
import 'tile_batch.dart';
import 'tile_frame.dart';
import 'tile_surface.dart';

class QuestShuffleStage {
  const QuestShuffleStage(
    this.motion, {
    this.waiting = false,
    this.excluded_ids = const {},
  });
  final QuestSceneMotion motion;
  final bool waiting;
  final Set<int> excluded_ids;
}

class QuestMotionSnapshot {
  const QuestMotionSnapshot(this.tiles, {this.shuffle});
  final List<QuestTileFrame> tiles;
  final QuestShuffleStage? shuffle;
}

/// 场景时钟直接重绘一个画布；飞行、入场与粒子均不经过逐帧build/layout。
class QuestMotionCanvas extends StatelessWidget {
  QuestMotionCanvas({
    super.key,
    required QuestSceneLayout layout,
    required ValueListenable<double> clock,
    required QuestShuffleTextures textures,
    required QuestMotionSnapshot Function(double) snapshot_at,
    required Map<int, QuestParticleField> particle_fields,
    required bool reduced_motion,
    required this.on_reserve,
    required bool Function(int) can_return,
  }) : painter = QuestMotionPainter(
         layout: layout,
         clock: clock,
         textures: textures,
         snapshot_at: snapshot_at,
         particle_fields: particle_fields,
         reduced_motion: reduced_motion,
         can_return: can_return,
         on_reserve: on_reserve,
       );
  final QuestMotionPainter painter;
  final ValueChanged<int> on_reserve;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapUp: (details) {
      final id = painter.reserve_at(details.localPosition);
      if (id != null) on_reserve(id);
    },
    child: RepaintBoundary(
      child: CustomPaint(painter: painter, size: painter.layout.size),
    ),
  );
}

class QuestMotionPainter extends CustomPainter {
  QuestMotionPainter({
    required this.layout,
    required this.clock,
    required this.textures,
    required this.snapshot_at,
    required this.particle_fields,
    required this.reduced_motion,
    required this.can_return,
    required this.on_reserve,
  }) : super(repaint: Listenable.merge([clock, textures]));
  final QuestSceneLayout layout;
  final ValueListenable<double> clock;
  final QuestShuffleTextures textures;
  final QuestMotionSnapshot Function(double) snapshot_at;
  final Map<int, QuestParticleField> particle_fields;
  final bool reduced_motion;
  final bool Function(int) can_return;
  final ValueChanged<int> on_reserve;
  final QuestTileBatch _batch = QuestTileBatch(32);
  QuestShufflePainter? _shuffle;

  QuestShufflePainter? _shuffle_for(QuestShuffleStage? stage) {
    if (stage == null) {
      _shuffle = null;
      return null;
    }
    final previous = _shuffle;
    if (previous == null ||
        previous.motion != stage.motion ||
        previous.waiting != stage.waiting ||
        !setEquals(previous.excluded_ids, stage.excluded_ids)) {
      _shuffle = QuestShufflePainter(
        motion: stage.motion,
        layout: layout,
        clock: clock,
        textures: textures,
        waiting: stage.waiting,
        excluded_ids: stage.excluded_ids,
      );
    }
    return _shuffle;
  }

  /// 读取真实绘制数据，测试不再依赖数百个不可见卡片widget。
  List<QuestTileFrame> get frames {
    final snapshot = snapshot_at(clock.value);
    final shuffle = _shuffle_for(snapshot.shuffle);
    return [
      ...snapshot.tiles,
      if (shuffle != null)
        for (final id in shuffle.tile_ids) _shuffle_frame(shuffle.frame_of(id)),
    ];
  }

  QuestTileFrame _shuffle_frame(QuestShuffleFrame frame) => QuestTileFrame(
    id: frame.id,
    type: frame.type,
    previous_type: frame.previous_type,
    rect: frame.rect,
    zone: QuestTileZone.flight,
    blocked: frame.blocked,
    rotation: frame.rotation,
    face_progress: frame.face_progress,
  );

  int? reserve_at(Offset position) {
    for (final frame in snapshot_at(clock.value).tiles.reversed) {
      if (frame.zone == QuestTileZone.reserve &&
          !frame.blocked &&
          QuestTileSurface.contains(frame.rect, position) &&
          can_return(frame.id)) {
        return frame.id;
      }
    }
    return null;
  }

  @override
  bool? hitTest(Offset position) => reserve_at(position) != null;

  @override
  void paint(Canvas canvas, Size size) {
    final snapshot = snapshot_at(clock.value);
    _batch.begin();
    final ready = textures.ready;
    for (final frame in snapshot.tiles) {
      if ((frame.dissolve ?? 0) > 0) continue;
      final source = ready
          ? textures.source_of(frame.type, blocked: frame.blocked)
          : null;
      if (source != null) {
        _batch.add(source, frame.rect, rotation: frame.rotation);
      } else {
        canvas.save();
        canvas.translate(frame.rect.center.dx, frame.rect.center.dy);
        canvas.rotate(frame.rotation);
        textures.paint_tile(
          canvas,
          Rect.fromCenter(
            center: Offset.zero,
            width: frame.rect.width,
            height: frame.rect.height,
          ),
          frame.type,
          blocked: frame.blocked,
        );
        canvas.restore();
      }
    }
    _batch.paint(canvas, textures);
    _shuffle_for(snapshot.shuffle)?.paint(canvas, size);
    // 碎粒叠在正在入槽的牌上方，但不持有槽位，也不创建独立合成图层。
    for (final frame in snapshot.tiles) {
      final dissolve = frame.dissolve;
      if (dissolve == null || dissolve <= 0 || dissolve >= 1) continue;
      final source = textures.source_of(frame.type, blocked: false);
      final atlas = textures.atlas;
      if (atlas == null || source == null) continue;
      canvas.save();
      canvas.translate(frame.rect.left, frame.rect.top);
      QuestMatchParticlePainter(
        image: atlas,
        source_rect: source,
        field: particle_fields.putIfAbsent(
          frame.id,
          () => QuestParticleField(frame.id),
        ),
        progress: dissolve,
        reduced_motion: reduced_motion,
      ).paint(canvas, frame.rect.size);
      canvas.restore();
    }
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder =>
      (size) => [
        for (final frame in snapshot_at(clock.value).tiles)
          if (frame.zone == QuestTileZone.reserve && can_return(frame.id))
            CustomPainterSemantics(
              key: ValueKey('tile_quest_reserve_${frame.id}'),
              rect: frame.rect,
              properties: SemanticsProperties(
                label: 'Reserve tile ${frame.id}',
                textDirection: TextDirection.ltr,
                button: true,
                enabled: true,
                onTap: () => on_reserve(frame.id),
              ),
            ),
      ];
  @override
  bool shouldRepaint(covariant QuestMotionPainter old) => true;
  @override
  bool shouldRebuildSemantics(covariant QuestMotionPainter oldDelegate) => true;
}
