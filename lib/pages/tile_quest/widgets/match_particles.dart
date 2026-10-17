// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'tile_card.dart';

/// 一张牌分为 144 个保留原图颜色的碎粒；三个匹配牌最多绘制 432 粒。
/// 共用场景时钟，不创建粒子 Widget、额外 ticker 或逐帧随机数。
class QuestMatchParticles extends StatefulWidget {
  const QuestMatchParticles({
    super.key,
    required this.type,
    required this.seed,
    required this.progress,
    required this.child,
  });

  final int type, seed;
  final double progress;
  final Widget child;

  @override
  State<QuestMatchParticles> createState() => _QuestMatchParticlesState();
}

class _QuestMatchParticlesState extends State<QuestMatchParticles> {
  ImageStream? _stream;
  ImageInfo? _image;
  int? _resolved_type;
  late QuestParticleField _field = QuestParticleField(widget.seed);
  late final ImageStreamListener _listener = ImageStreamListener(
    (image, synchronous) {
      _image?.dispose();
      _image = image;
      if (mounted) setState(() {});
    },
    onError: (Object error, StackTrace? stack) {
      // 解码失败时仍柔和淡出已有牌，不影响规则或视觉队列完成。
    },
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve_image();
  }

  @override
  void didUpdateWidget(covariant QuestMatchParticles oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seed != widget.seed) {
      _field = QuestParticleField(widget.seed);
    }
    if (oldWidget.type != widget.type) _resolve_image();
  }

  void _resolve_image() {
    if (_resolved_type == widget.type) return;
    _resolved_type = widget.type;
    _stream?.removeListener(_listener);
    _image?.dispose();
    _image = null;
    // 与 Image.asset(cacheWidth: 192) 完全相同的缓存键；飞牌途中就准备好。
    _stream = ResizeImage.resizeIfNeeded(
      192,
      null,
      AssetImage(
        'assets/img/game/tile_${quest_tile_assets[widget.type % quest_tile_assets.length]}.png',
      ),
    ).resolve(createLocalImageConfiguration(context));
    _stream!.addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.progress.clamp(0.0, 1.0);
    if (progress == 0) return widget.child;
    if (_image == null) {
      return Opacity(opacity: 1 - progress, child: widget.child);
    }
    return CustomPaint(
      painter: QuestMatchParticlePainter(
        image: _image!.image,
        field: _field,
        progress: progress,
        reduced_motion: MediaQuery.disableAnimationsOf(context),
      ),
    );
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
  });

  final ui.Image image;
  final QuestParticleField field;
  final double progress;
  final bool reduced_motion;
  static final Paint _paint = Paint()..filterQuality = FilterQuality.low;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1 || size.isEmpty) return;
    final edge = math.min(size.width, size.height);
    final source_edge = math.min(image.width, image.height).toDouble();
    final cell = source_edge / QuestParticleField.columns;
    final base_scale = edge / source_edge;
    final origin = size.center(Offset.zero) - Offset(edge / 2, edge / 2);
    final motion_scale = reduced_motion ? .12 : 1.0;
    for (var index = 0; index < QuestParticleField.count; index++) {
      final local = ((progress - field.delay[index]) / (1 - field.delay[index]))
          .clamp(0.0, 1.0);
      // 起步速度为零，随后散开并带少许重力；延迟错落避免整齐爆炸。
      final travel = local * local / (local + .10);
      final fade = math.pow(1 - local, 1.3).toDouble();
      final shrink = 1 - Curves.easeInOutCubic.transform(local) * .94;
      final angle = field.rotation[index] * travel * motion_scale;
      final scos = math.cos(angle) * base_scale * shrink;
      final ssin = math.sin(angle) * base_scale * shrink;
      final column = index % QuestParticleField.columns;
      final row = index ~/ QuestParticleField.columns;
      final center =
          origin +
          Offset(
            (column + .5) * cell * base_scale +
                field.dx[index] * edge * travel * motion_scale,
            (row + .5) * cell * base_scale +
                (field.dy[index] * travel + .38 * local * local) *
                    edge *
                    motion_scale,
          );
      final offset = index * 4;
      field.transforms[offset] = scos;
      field.transforms[offset + 1] = ssin;
      field.transforms[offset + 2] = center.dx - (scos - ssin) * cell / 2;
      field.transforms[offset + 3] = center.dy - (scos + ssin) * cell / 2;
      field.sources[offset] = column * cell;
      field.sources[offset + 1] = row * cell;
      field.sources[offset + 2] = (column + 1) * cell;
      field.sources[offset + 3] = (row + 1) * cell;
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
      field != oldDelegate.field ||
      reduced_motion != oldDelegate.reduced_motion;
}
