// ignore_for_file: non_constant_identifier_names
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'tile_surface_style.dart';

/// 静态牌、飞牌、洗牌共用同一张陶瓷材质；柔影与倒角只栅格化一次。
class QuestTileSurface {
  const QuestTileSurface._();
  static final _QuestTileMaterial _material = _QuestTileMaterial();
  static final Paint _image_paint = Paint()
    ..filterQuality = FilterQuality.medium;
  static ui.Image? _body_image;
  static ui.Image? _shadow_image;
  static bool _preparation_failed = false;

  /// 场景纹理加载时预热，不等待玩家第一次点击才编译阴影与材质。
  /// 全局只有一张 192px 只读底板，不为每种图标重复做模糊栅格化。
  static void prepare() {
    if (_body_image != null || _preparation_failed) return;
    final recorder = ui.PictureRecorder();
    _material.paint(Canvas(recorder), detailed: true);
    final picture = recorder.endRecording();
    try {
      // 同步取得GPU图片句柄，栅格化由引擎异步完成；没有CPU读回或跨会话Future。
      _body_image = picture.toImageSync(
        QuestTileSurfaceStyle.edge.toInt(),
        QuestTileSurfaceStyle.edge.toInt(),
      );
      final shadow_recorder = ui.PictureRecorder();
      _material.paint_shadows(Canvas(shadow_recorder));
      final shadow_picture = shadow_recorder.endRecording();
      try {
        _shadow_image = shadow_picture.toImageSync(
          QuestTileSurfaceStyle.edge.toInt(),
          QuestTileSurfaceStyle.edge.toInt(),
        );
      } finally {
        shadow_picture.dispose();
      }
    } catch (_) {
      _preparation_failed = true;
    } finally {
      picture.dispose();
    }
  }

  static Rect _rect(Rect fraction, Rect bounds) => Rect.fromLTWH(
    bounds.left + fraction.left * bounds.width,
    bounds.top + fraction.top * bounds.height,
    fraction.width * bounds.width,
    fraction.height * bounds.height,
  );

  static Rect icon_rect(Rect bounds) =>
      _rect(QuestTileSurfaceStyle.icon, bounds);

  /// 只命中实物，不让模糊投影截获落在下层牌上的点击。
  static bool contains(Rect bounds, Offset point) {
    if (bounds.isEmpty || !bounds.contains(point)) return false;
    final local = Offset(
      (point.dx - bounds.left) * QuestTileSurfaceStyle.edge / bounds.width,
      (point.dy - bounds.top) * QuestTileSurfaceStyle.edge / bounds.height,
    );
    return _material.silhouette.contains(local);
  }

  static void paint(
    Canvas canvas,
    Rect bounds, {
    ui.Image? icon,
    ui.Image? body,
    bool blocked = false,
  }) {
    if (bounds.isEmpty) return;
    // 参考材质由场景借用Flutter解码缓存；这里不持有或释放调用方的图片。
    // 图集初始化时合成一次，交互帧仍只采样预烘焙的完整牌纹理。
    if (body != null) {
      prepare();
      final shadow = _shadow_image;
      if (shadow != null) {
        canvas.drawImageRect(shadow, _material.bounds, bounds, _image_paint);
      }
      canvas.save();
      canvas.translate(bounds.left, bounds.top);
      canvas.scale(
        bounds.width / QuestTileSurfaceStyle.edge,
        bounds.height / QuestTileSurfaceStyle.edge,
      );
      // 生成素材外侧的孤立半透明像素不属于实物；与命中共用实体轮廓，
      // 仅在底板合成时裁掉边缘杂点，接触投影单独由共享图片提供。
      canvas.clipPath(_material.silhouette);
      // 实体内部始终不透明，原PNG的254/255透明误差不透出深色背景。
      canvas.drawPath(_material.silhouette, _material.substrate_paint);
      canvas.drawImageRect(
        body,
        Rect.fromLTWH(0, 0, body.width.toDouble(), body.height.toDouble()),
        _material.bounds,
        _image_paint,
      );
      canvas.restore();
    }
    final body_image = body == null ? _body_image : null;
    var body_drawn = body != null;
    if (body_image != null) {
      try {
        canvas.drawImageRect(
          body_image,
          _material.bounds,
          bounds,
          _image_paint,
        );
        body_drawn = true;
      } catch (_) {
        // 延迟GPU栅格化失败时退回无滤镜形体，不能使低内存设备反复抛错。
        _body_image = null;
        _preparation_failed = true;
        body_image.dispose();
      }
    }
    if (!body_drawn) {
      // 首次底板未到齐时使用无模糊、无离屏层的简化形体。
      // 数百张牌的冷启动回退不能逐牌重复执行阴影滤镜。
      canvas.save();
      canvas.translate(bounds.left, bounds.top);
      canvas.scale(
        bounds.width / QuestTileSurfaceStyle.edge,
        bounds.height / QuestTileSurfaceStyle.edge,
      );
      _material.paint(canvas);
      canvas.restore();
    }
    if (icon != null) {
      final image_size = Size(icon.width.toDouble(), icon.height.toDouble());
      final available = icon_rect(bounds);
      final fitted = applyBoxFit(BoxFit.contain, image_size, available.size);
      canvas.drawImageRect(
        icon,
        Alignment.center.inscribe(fitted.source, Offset.zero & image_size),
        Alignment.center.inscribe(fitted.destination, available),
        _image_paint,
      );
    }
    if (blocked) {
      canvas.save();
      canvas.translate(bounds.left, bounds.top);
      canvas.scale(
        bounds.width / QuestTileSurfaceStyle.edge,
        bounds.height / QuestTileSurfaceStyle.edge,
      );
      canvas.drawPath(_material.silhouette, _material.occlusion_paint);
      // 下层牌主要在实体侧壁接收蓝灰环境光，不再把整张奶油面涂灰。
      canvas.drawPath(_material.exposed_side, _material.side_occlusion_paint);
      canvas.restore();
    }
  }
}

/// 单一左上光源。侧壁渐变只作用于露出的厚度，软投影与底缘接触影分开。
class _QuestTileMaterial {
  _QuestTileMaterial() {
    final radius =
        QuestTileSurfaceStyle.edge * QuestTileSurfaceStyle.radius_fraction;
    body = RRect.fromRectAndRadius(
      _r(QuestTileSurfaceStyle.body),
      Radius.circular(radius),
    );
    face = RRect.fromRectAndRadius(
      _r(QuestTileSurfaceStyle.face),
      Radius.circular(radius),
    );
    final inset = _r(QuestTileSurfaceStyle.face_inset);
    face_inset = RRect.fromRectAndRadius(
      inset,
      Radius.circular(radius - (inset.left - face.left)),
    );
    silhouette = QuestTileSurfaceStyle.create_outline();
    exposed_side = Path.combine(
      PathOperation.difference,
      silhouette,
      Path()..addRRect(face),
    );
    final side_rect = Rect.fromLTRB(
      body.left,
      QuestTileSurfaceStyle.side_start * QuestTileSurfaceStyle.edge,
      body.right,
      body.bottom,
    );
    body_paint.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: QuestTileSurfaceStyle.body_colors,
      stops: QuestTileSurfaceStyle.body_stops,
    ).createShader(side_rect);
    side_light_paint.shader = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: QuestTileSurfaceStyle.side_light_colors,
      stops: QuestTileSurfaceStyle.side_light_stops,
    ).createShader(body.outerRect);
    face_paint.shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: QuestTileSurfaceStyle.face_colors,
      stops: QuestTileSurfaceStyle.face_stops,
    ).createShader(inset);
    sheen_paint.shader = const RadialGradient(
      center: QuestTileSurfaceStyle.sheen_center,
      radius: QuestTileSurfaceStyle.sheen_radius,
      colors: QuestTileSurfaceStyle.sheen_colors,
    ).createShader(inset);
    occlusion_paint.shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: QuestTileSurfaceStyle.occlusion_colors,
    ).createShader(bounds);
    side_occlusion_paint.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: QuestTileSurfaceStyle.side_occlusion_colors,
    ).createShader(exposed_side.getBounds());
    // 多个连续的圆角截面模拟软倒角，所有 shader 只在这一次构造。
    for (var step = 0; step < QuestTileSurfaceStyle.bevel_steps; step++) {
      final t = step / (QuestTileSurfaceStyle.bevel_steps - 1);
      final section = RRect.lerp(face, face_inset, t)!;
      final colors = <Color>[
        for (
          var channel = 0;
          channel < QuestTileSurfaceStyle.bevel_colors.length;
          channel++
        )
          Color.lerp(
            QuestTileSurfaceStyle.bevel_colors[channel],
            QuestTileSurfaceStyle.face_colors[channel],
            t,
          )!,
      ];
      _bevel_sections.add((
        section,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
            stops: QuestTileSurfaceStyle.bevel_stops,
          ).createShader(section.outerRect),
      ));
    }
  }

  final Rect bounds =
      Offset.zero & const Size.square(QuestTileSurfaceStyle.edge);
  Rect _r(Rect fraction) => QuestTileSurface._rect(fraction, bounds);
  late final RRect body, face, face_inset;
  late final Path silhouette, exposed_side;
  final _bevel_sections = <(RRect, Paint)>[];
  final Paint body_paint = Paint(),
      side_light_paint = Paint(),
      face_paint = Paint(),
      sheen_paint = Paint(),
      occlusion_paint = Paint(),
      side_occlusion_paint = Paint();
  final Paint substrate_paint = Paint()
    ..color = QuestTileSurfaceStyle.face_colors[1];
  final Paint ambient_paint = Paint()
    ..color = QuestTileSurfaceStyle.ambient_color
    ..maskFilter = const MaskFilter.blur(
      BlurStyle.normal,
      QuestTileSurfaceStyle.ambient_sigma * QuestTileSurfaceStyle.edge,
    );
  final Paint contact_paint = Paint()
    ..color = QuestTileSurfaceStyle.contact_color
    ..maskFilter = const MaskFilter.blur(
      BlurStyle.normal,
      QuestTileSurfaceStyle.contact_sigma * QuestTileSurfaceStyle.edge,
    );

  void paint(Canvas canvas, {bool detailed = false}) {
    if (detailed) paint_shadows(canvas);
    canvas.drawRRect(body, body_paint);
    canvas.drawRRect(body, side_light_paint);
    if (detailed) {
      for (final (section, paint) in _bevel_sections) {
        canvas.drawRRect(section, paint);
      }
    } else {
      canvas.drawRRect(face, _bevel_sections.first.$2);
    }
    canvas.drawRRect(face_inset, face_paint);
    canvas.drawRRect(face_inset, sheen_paint);
  }

  /// 只有准备共享192px底板时调用；牌图集与交互帧只采样该图片。
  void paint_shadows(Canvas canvas) {
    final edge = QuestTileSurfaceStyle.edge;
    canvas.drawPath(
      silhouette.shift(QuestTileSurfaceStyle.ambient_offset * edge),
      ambient_paint,
    );
    canvas.drawPath(
      silhouette.shift(QuestTileSurfaceStyle.contact_offset * edge),
      contact_paint,
    );
  }
}
