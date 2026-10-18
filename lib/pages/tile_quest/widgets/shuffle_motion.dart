// ignore_for_file: non_constant_identifier_names
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../game/models.dart';
import '../style.dart';
import 'board_motion.dart';
import 'scene_layout.dart';
import 'scene_motion.dart';
import 'shuffle_textures.dart';

/// 与真实画布共用的单牌快照，供几何、换面及尺寸回归检查。
/// 游戏绘制直接复用 atlas 缓冲区，不为每帧创建这些快照或隐藏卡片。
class QuestShuffleFrame {
  const QuestShuffleFrame({
    required this.id,
    required this.type,
    required this.previous_type,
    required this.rect,
    required this.rotation,
    required this.face_progress,
    required this.blocked,
  });
  final int id, type, previous_type;
  final Rect rect;
  final double rotation, face_progress;
  final bool blocked;
}

/// 洗牌只有一个绘制节点。时钟直接触发 repaint，牌数不再影响组件树大小。
class QuestShuffleMotion extends StatefulWidget {
  const QuestShuffleMotion({
    super.key,
    required this.motion,
    required this.layout,
    required this.clock,
    required this.textures,
    this.waiting = false,
    this.excluded_ids = const {},
  });
  final QuestSceneMotion motion;
  final QuestSceneLayout layout;
  final ValueListenable<double> clock;
  final QuestShuffleTextures textures;
  final bool waiting;
  final Set<int> excluded_ids;

  @override
  State<QuestShuffleMotion> createState() => _QuestShuffleMotionState();
}

class _QuestShuffleMotionState extends State<QuestShuffleMotion> {
  late Widget _surface;

  @override
  void initState() {
    super.initState();
    _create_surface();
  }

  @override
  void didUpdateWidget(covariant QuestShuffleMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.motion != widget.motion ||
        oldWidget.layout.board != widget.layout.board ||
        oldWidget.layout.unit != widget.layout.unit ||
        oldWidget.layout.size != widget.layout.size ||
        oldWidget.clock != widget.clock ||
        oldWidget.waiting != widget.waiting ||
        !setEquals(oldWidget.excluded_ids, widget.excluded_ids) ||
        oldWidget.textures != widget.textures) {
      _create_surface();
    }
  }

  void _create_surface() {
    _surface = RepaintBoundary(
      child: IgnorePointer(
        child: CustomPaint(
          painter: QuestShufflePainter(
            motion: widget.motion,
            layout: widget.layout,
            clock: widget.clock,
            textures: widget.textures,
            waiting: widget.waiting,
            excluded_ids: widget.excluded_ids,
          ),
          size: widget.layout.size,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _surface;
}

/// 静态牌序、原位和三角函数只在事务开始或窗口变化时计算一次。
class _ShuffleCard {
  _ShuffleCard(
    this.tile,
    this.previous_type,
    this.source,
    this.index,
    int count,
  ) : angle_cos = math.cos(
        index / math.max(1, count) * math.pi * 2 - math.pi / 2,
      ),
      angle_sin = math.sin(
        index / math.max(1, count) * math.pi * 2 - math.pi / 2,
      ),
      wobble_cos = math.cos(index * 1.7),
      wobble_sin = math.sin(index * 1.7);
  final TileQuestTile tile;
  final int previous_type, index;
  final Rect source;
  final double angle_cos, angle_sin, wobble_cos, wobble_sin;
}

/// 每帧一次 drawRawAtlas：顺序保留逐牌旧图、新图，透明度直接参与像素混合。
/// 遮挡暗色已烘焙在 atlas 中，避免数百个 saveLayer 和独立合成图层。
class QuestShufflePainter extends CustomPainter {
  QuestShufflePainter({
    required this.motion,
    required this.layout,
    required this.clock,
    required this.textures,
    this.waiting = false,
    this.excluded_ids = const {},
  }) : super(repaint: Listenable.merge([clock, textures])) {
    final result = motion.result;
    final before = {for (final tile in result.before.tiles) tile.id: tile};
    final after = {for (final tile in result.after.tiles) tile.id: tile};
    _cards =
        [
          for (var index = 0; index < result.moved_ids.length; index++)
            if (!excluded_ids.contains(result.moved_ids[index]))
              _ShuffleCard(
                after[result.moved_ids[index]]!,
                before[result.moved_ids[index]]!.type,
                layout.board_tile(before[result.moved_ids[index]]!),
                index,
                result.moved_ids.length,
              ),
        ]..sort((a, b) {
          final layer = a.tile.layer.compareTo(b.tile.layer);
          return layer == 0 ? a.tile.id.compareTo(b.tile.id) : layer;
        });
    _by_id = {for (final card in _cards) card.tile.id: card};
    // 最多两张纹理组成一张换面牌；缓冲区随本次洗牌复用。
    _transforms = Float32List(_cards.length * 8);
    _sources = Float32List(_cards.length * 8);
    _colors = Int32List(_cards.length * 2);
  }

  final QuestSceneMotion motion;
  final QuestSceneLayout layout;
  final ValueListenable<double> clock;
  final QuestShuffleTextures textures;
  final bool waiting;
  final Set<int> excluded_ids;
  int get _count => motion.result.moved_ids.length;
  late final List<_ShuffleCard> _cards;
  late final Map<int, _ShuffleCard> _by_id;
  late final Float32List _transforms, _sources;
  late final Int32List _colors;
  final Paint _paint = Paint()..filterQuality = FilterQuality.low;

  double get progress => waiting || motion.travel_ms <= 0
      ? 0
      : (motion.elapsed(clock.value) / motion.travel_ms).clamp(0.0, 1.0);
  Iterable<int> get tile_ids => _by_id.keys;

  /// 暴露实际绘制使用的几何，不为测试保留昂贵的不可见组件树。
  QuestShuffleFrame frame_of(int id) {
    final card = _by_id[id]!;
    final time = progress;
    final frame = QuestBoardMotion.shuffle_frame(layout, time);
    return QuestShuffleFrame(
      id: id,
      type: card.tile.type,
      previous_type: card.previous_type,
      rect: QuestBoardMotion.shuffle_rect_with(
        layout,
        card.source,
        card.index,
        _count,
        frame.phase,
        frame.presence,
      ),
      rotation: QuestBoardMotion.shuffle_rotation_with(
        frame.phase,
        frame.presence,
        index: card.index,
      ),
      face_progress: QuestBoardMotion.shuffle_face_progress(
        time,
        index: card.index,
        count: _count,
      ),
      blocked: card.tile.is_blocked,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final time = progress;
    final frame = QuestBoardMotion.shuffle_frame(layout, time);
    final phase_cos = math.cos(frame.phase);
    final phase_sin = math.sin(frame.phase);
    final atlas = textures.ready ? textures.atlas : null;
    var sprite = 0;
    for (final card in _cards) {
      final source = card.source;
      final presence = frame.presence;
      final center_x =
          source.center.dx +
          (frame.center.dx +
                  (card.angle_cos * phase_cos - card.angle_sin * phase_sin) *
                      frame.radius -
                  source.center.dx) *
              presence;
      final center_y =
          source.center.dy +
          (frame.center.dy +
                  (card.angle_sin * phase_cos + card.angle_cos * phase_sin) *
                      frame.radius -
                  source.center.dy) *
              presence;
      final rotation =
          (phase_sin * card.wobble_cos + phase_cos * card.wobble_sin) *
          TileQuestStyle.shuffle_rotation *
          presence;
      final face = QuestBoardMotion.shuffle_face_progress(
        time,
        index: card.index,
        count: _count,
      );
      final old_source = textures.source_of(
        card.previous_type,
        blocked: card.tile.is_blocked,
      );
      final new_source = textures.source_of(
        card.tile.type,
        blocked: card.tile.is_blocked,
      );
      if (atlas == null || old_source == null || new_source == null) {
        // 预热未完成仍绘制已解码的原图，不因首帧异步加载而清空棋盘。
        _paint_fallback(canvas, card, center_x, center_y, rotation, face);
        continue;
      }
      final blended =
          card.previous_type != card.tile.type && face > 0 && face < 1;
      final first = face >= 1 ? new_source : old_source;
      final scale = source.shortestSide / TileQuestStyle.tile_cache_width;
      final scos = math.cos(rotation) * scale;
      final ssin = math.sin(rotation) * scale;
      final tx = center_x - (scos - ssin) * TileQuestStyle.tile_cache_width / 2;
      final ty = center_y - (scos + ssin) * TileQuestStyle.tile_cache_width / 2;
      _write_sprite(sprite++, first, scos, ssin, tx, ty, 1);
      if (blended) {
        _write_sprite(sprite++, new_source, scos, ssin, tx, ty, face);
      }
    }
    if (atlas != null && sprite > 0) {
      canvas.drawRawAtlas(
        atlas,
        Float32List.sublistView(_transforms, 0, sprite * 4),
        Float32List.sublistView(_sources, 0, sprite * 4),
        Int32List.sublistView(_colors, 0, sprite),
        BlendMode.modulate,
        null,
        _paint,
      );
    }
  }

  void _write_sprite(
    int index,
    Rect source,
    double scos,
    double ssin,
    double tx,
    double ty,
    double opacity,
  ) {
    final offset = index * 4;
    _transforms[offset] = scos;
    _transforms[offset + 1] = ssin;
    _transforms[offset + 2] = tx;
    _transforms[offset + 3] = ty;
    _sources[offset] = source.left;
    _sources[offset + 1] = source.top;
    _sources[offset + 2] = source.right;
    _sources[offset + 3] = source.bottom;
    _colors[index] = ((opacity * 255).round() << 24) | 0x00FFFFFF;
  }

  void _paint_fallback(
    Canvas canvas,
    _ShuffleCard card,
    double x,
    double y,
    double rotation,
    double face,
  ) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(rotation);
    textures.paint_tile(
      canvas,
      Rect.fromCenter(
        center: Offset.zero,
        width: card.source.width,
        height: card.source.height,
      ),
      face >= 1 ? card.tile.type : card.previous_type,
      blocked: card.tile.is_blocked,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant QuestShufflePainter oldDelegate) =>
      motion != oldDelegate.motion ||
      layout != oldDelegate.layout ||
      textures != oldDelegate.textures ||
      waiting != oldDelegate.waiting ||
      !setEquals(excluded_ids, oldDelegate.excluded_ids) ||
      clock != oldDelegate.clock;
}
