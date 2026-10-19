// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'match_particle_style.dart';
import 'shuffle_textures.dart';

/// 一张牌分为 144 个保留原图颜色的碎粒；三个匹配牌最多绘制 432 粒。
/// 共用场景时钟，不创建粒子 Widget、额外 ticker 或逐帧随机数。
class QuestMatchParticles extends StatefulWidget {
  const QuestMatchParticles({
    super.key,
    required this.type,
    required this.seed,
    required this.progress,
    required this.child,
    this.textures,
  });

  final int type, seed;
  final double progress;
  final Widget child;

  /// 复用场景已经准备好的完整立体牌，消除时不提交新的纹理解码或烘焙。
  final QuestShuffleTextures? textures;

  @override
  State<QuestMatchParticles> createState() => _QuestMatchParticlesState();
}

class _QuestMatchParticlesState extends State<QuestMatchParticles> {
  late QuestParticleField _field = QuestParticleField(widget.seed);

  @override
  void didUpdateWidget(covariant QuestMatchParticles oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seed != widget.seed) {
      _field = QuestParticleField(widget.seed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.progress.clamp(0.0, 1.0);
    if (progress == 0) return widget.child;
    final textures = widget.textures;
    final atlas = textures?.atlas;
    final source = textures?.content_of(widget.type, blocked: false);
    if (atlas != null && source != null) {
      return CustomPaint(
        painter: QuestMatchParticlePainter(
          image: atlas,
          source_rect: source,
          field: _field,
          progress: progress,
          reduced_motion: MediaQuery.disableAnimationsOf(context),
        ),
      );
    }
    // 独立卡无场景图集时保持完整立体牌淡出，绝不把裸图标切换为碎片。
    return Opacity(opacity: 1 - progress, child: widget.child);
  }
}

/// 每次消除只分配一次的粒子参数和 atlas 缓冲区，之后原地复用。
class QuestParticleField {
  QuestParticleField(int seed) {
    final random = math.Random(seed);
    for (var index = 0; index < count; index++) {
      final x = (index % columns + .5) / columns - .5;
      final y = (index ~/ columns + .5) / columns - .5;
      final angle = math.atan2(y, x) + (random.nextDouble() - .5) * .9;
      final speed = .48 + random.nextDouble() * .58;
      dx[index] = math.cos(angle) * speed;
      dy[index] = math.sin(angle) * speed - .34;
      delay[index] = random.nextDouble() * .14;
      rotation[index] = (random.nextDouble() - .5) * 3.4;
    }
  }

  static const int columns = 12;
  static const int count = columns * columns;
  final Float64List dx = Float64List(count);
  final Float64List dy = Float64List(count);
  final Float64List delay = Float64List(count);
  final Float64List rotation = Float64List(count);
  final Float32List transforms = Float32List(count * 4);
  final Float32List sources = Float32List(count * 4);
  final Int32List colors = Int32List(count);
}

/// 裁切原牌纹理进行一次 atlas 绘制。粒子从各自原位出发，而非中心喷点。
class QuestMatchParticlePainter extends CustomPainter {
  QuestMatchParticlePainter({
    required this.image,
    required this.field,
    required this.progress,
    this.reduced_motion = false,
    this.source_rect,
  });

  final ui.Image image;

  /// 图集中完整牌的内容区域；未提供时使用单张纹理的完整矩形。
  final Rect? source_rect;
  final QuestParticleField field;
  final double progress;
  final bool reduced_motion;
  static final Paint _paint = Paint()..filterQuality = FilterQuality.low;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1 || size.isEmpty) return;
    final source =
        source_rect ??
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    if (source.isEmpty) return;
    final cell_width = source.width / QuestParticleField.columns;
    final cell_height = source.height / QuestParticleField.columns;
    // 完整矩形等比映射到牌格，保留底部厚度，不能先裁成短边正方形。
    final base_scale = math.min(
      size.width / source.width,
      size.height / source.height,
    );
    final edge = source.width * base_scale;
    final origin =
        size.center(Offset.zero) -
        Offset(source.width * base_scale / 2, source.height * base_scale / 2);
    final motion_scale = reduced_motion ? .12 : 1.0;
    for (var index = 0; index < QuestParticleField.count; index++) {
      final local = ((progress - field.delay[index]) / (1 - field.delay[index]))
          .clamp(0.0, 1.0);
      // 起步速度为零，随后散开并带少许重力；延迟错落避免整齐爆炸。
      final travel = local * local / (local + .10);
      final remaining = 1 - local;
      // 与原 remaining^1.3 的全区间透明度误差小于 2/255；只需乘加。
      final fade =
          remaining *
          (QuestMatchParticleStyle.fade_linear +
              remaining *
                  (QuestMatchParticleStyle.fade_quadratic +
                      remaining * QuestMatchParticleStyle.fade_cubic));
      // 五次 smoothstep 起止速度和加速度均为零，无贝塞尔逆向迭代求根。
      final eased = local * local * local * (local * (local * 6 - 15) + 10);
      final shrink = 1 - eased * QuestMatchParticleStyle.shrink_fraction;
      final angle = field.rotation[index] * travel * motion_scale;
      final scos = math.cos(angle) * base_scale * shrink;
      final ssin = math.sin(angle) * base_scale * shrink;
      final column = index % QuestParticleField.columns;
      final row = index ~/ QuestParticleField.columns;
      final center =
          origin +
          Offset(
            (column + .5) * cell_width * base_scale +
                field.dx[index] * edge * travel * motion_scale,
            (row + .5) * cell_height * base_scale +
                (field.dy[index] * travel + .38 * local * local) *
                    edge *
                    motion_scale,
          );
      final offset = index * 4;
      field.transforms[offset] = scos;
      field.transforms[offset + 1] = ssin;
      field.transforms[offset + 2] =
          center.dx - scos * cell_width / 2 + ssin * cell_height / 2;
      field.transforms[offset + 3] =
          center.dy - ssin * cell_width / 2 - scos * cell_height / 2;
      field.sources[offset] = source.left + column * cell_width;
      field.sources[offset + 1] = source.top + row * cell_height;
      field.sources[offset + 2] = source.left + (column + 1) * cell_width;
      field.sources[offset + 3] = source.top + (row + 1) * cell_height;
      field.colors[index] = ((fade * 255).round() << 24) | 0x00FFFFFF;
    }
    canvas.drawRawAtlas(
      image,
      field.transforms,
      field.sources,
      field.colors,
      BlendMode.modulate,
      null,
      _paint,
    );
  }

  @override
  bool shouldRepaint(covariant QuestMatchParticlePainter oldDelegate) =>
      progress != oldDelegate.progress ||
      image != oldDelegate.image ||
      source_rect != oldDelegate.source_rect ||
      field != oldDelegate.field ||
      reduced_motion != oldDelegate.reduced_motion;
}
