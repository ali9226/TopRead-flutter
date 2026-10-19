// ignore_for_file: non_constant_identifier_names
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../game/models.dart';
import '../style.dart';
import 'board_motion.dart';
import 'board_reveal.dart';
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
    this.blocked_amount,
  });
  final int id, type, previous_type;
  final Rect rect;
  final double rotation, face_progress;
  final bool blocked;
  final double? blocked_amount;
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
    this.reveal,
  });
  final QuestSceneMotion motion;
  final QuestSceneLayout layout;
  final ValueListenable<double> clock;
  final QuestShuffleTextures textures;
  final bool waiting;
  final Set<int> excluded_ids;
  final QuestBoardReveal? reveal;

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
        oldWidget.reveal != widget.reveal ||
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
            reveal: widget.reveal,
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
    this.reveal,
  }) : super(repaint: Listenable.merge([clock, textures, reveal])) {
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
    // 极短的揭牌和换面窗口可以重叠；每牌最多四个精灵，仍只提交一次。
    _transforms = Float32List(_cards.length * 16);
    _sources = Float32List(_cards.length * 16);
    _colors = Int32List(_cards.length * 4);
  }

  final QuestSceneMotion motion;
  final QuestSceneLayout layout;
  final ValueListenable<double> clock;
  final QuestShuffleTextures textures;
  final bool waiting;
  final Set<int> excluded_ids;
  final QuestBoardReveal? reveal;
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
      blocked_amount: reveal?.amount_of(id, blocked: card.tile.is_blocked),
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
      final old_normal = textures.source_of(card.previous_type, blocked: false);
      final old_blocked = textures.source_of(card.previous_type, blocked: true);
      final new_normal = textures.source_of(card.tile.type, blocked: false);
      final new_blocked = textures.source_of(card.tile.type, blocked: true);
      if (atlas == null ||
          old_normal == null ||
          old_blocked == null ||
          new_normal == null ||
          new_blocked == null) {
        // 预热未完成仍绘制已解码的原图，不因首帧异步加载而清空棋盘。
        _paint_fallback(canvas, card, center_x, center_y, rotation, face);
        continue;
      }
      final blended =
          card.previous_type != card.tile.type && face > 0 && face < 1;
      final amount =
          reveal?.amount_of(card.tile.id, blocked: card.tile.is_blocked) ??
          (card.tile.is_blocked ? 1.0 : 0.0);
      final first = face >= 1 ? new_normal : old_normal;
      final scale = source.width / TileQuestStyle.tile_cache_width;
      final scos = math.cos(rotation) * scale;
      final ssin = math.sin(rotation) * scale;
      // 图集每格包含外扩落影，绕中心铺满整格而不是只铺逻辑牌。
      final half_width = first.width / 2;
      final half_height = first.height / 2;
      final tx = center_x - scos * half_width + ssin * half_height;
      final ty = center_y - ssin * half_width - scos * half_height;
      sprite = _write_reveal(
        sprite,
        first,
        face >= 1 ? new_blocked : old_blocked,
        amount,
        scos,
        ssin,
        tx,
        ty,
        1,
      );
      if (blended) {
        sprite = _write_reveal(
          sprite,
          new_normal,
          new_blocked,
          amount,
          scos,
          ssin,
          tx,
          ty,
          face,
        );
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

  /// 已在变亮的牌进入洗牌等待/运动时，沿用同一连续遮罩权重。
  int _write_reveal(
    int index,
    Rect normal,
    Rect blocked,
    double amount,
    double scos,
    double ssin,
    double tx,
    double ty,
    double opacity,
  ) {
    if (amount <= 0) {
      _write_sprite(index++, normal, scos, ssin, tx, ty, opacity);
    } else {
      _write_sprite(index++, blocked, scos, ssin, tx, ty, opacity);
      if (amount < 1) {
        _write_sprite(
          index++,
          normal,
          scos,
          ssin,
          tx,
          ty,
          opacity * (1 - amount),
        );
      }
    }
    return index;
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
      blocked_amount: reveal?.amount_of(
        card.tile.id,
        blocked: card.tile.is_blocked,
      ),
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
      reveal != oldDelegate.reveal ||
      clock != oldDelegate.clock;
}
