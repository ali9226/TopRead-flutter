// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'tile_quest_tile_style.dart';
import 'tile_surface_style.dart';

/// 静态牌、飞牌、洗牌与三消粒子共用的陶瓷牌材质。
///
/// 绘制单位是「绘制格」：逻辑牌格向外扩 `bleed`，外扩区域用于装下落影。
/// 正常运行时每个图案只在图集里合成一次，交互帧只做 drawRawAtlas；
/// 正常牌体直接使用用户提供的lattice.png；向量材质只处理素材失败回退。
class QuestTileSurface {
  const QuestTileSurface._();
  static final _QuestTileMaterial _material = _QuestTileMaterial();
  static final Paint _image_paint = Paint()
    ..filterQuality = FilterQuality.medium;
  static final Paint _body_image_paint = Paint()
    ..filterQuality = FilterQuality.medium
    ..colorFilter = const ColorFilter.matrix(QuestTileSurfaceStyle.body_filter);
  static final Paint _blocked_body_paint = Paint()
    ..filterQuality = FilterQuality.medium
    ..colorFilter = ColorFilter.matrix(
      QuestTileSurfaceStyle.blocked_body_filter,
    );
  static final Paint _fade_image_paint = Paint()
    ..filterQuality = FilterQuality.medium;
  static final Paint _fade_body_paint = Paint()
    ..filterQuality = FilterQuality.medium;
  static final List<double> _blocked_body_filter =
      QuestTileSurfaceStyle.blocked_body_filter;
  static const List<double> _identity_filter = [
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];
  static final Path _unit_silhouette =
      QuestTileSurfaceStyle.create_silhouette();

  /// 被压住的牌用色滤镜整体压暗：直接作用于图像像素（含抗锯齿边缘），
  /// 不会像裁剪蒙层那样在牌体外沿留下一圈未压暗的亮边。
  static final Paint _blocked_image_paint = Paint()
    ..filterQuality = FilterQuality.medium
    ..colorFilter = const ColorFilter.matrix(
      QuestTileSurfaceStyle.blocked_filter,
    );

  /// 被压住的牌沿轮廓压一圈径向环境影；填充路径比牌体略大，
  /// 抗锯齿边缘也能被完全压暗，不会残留一圈亮边。
  static final Path _blocked_edge_path = Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        QuestTileSurfaceStyle.body.inflate(
          QuestTileSurfaceStyle.blocked_edge_grow,
        ),
        Radius.circular(
          QuestTileSurfaceStyle.radius +
              QuestTileSurfaceStyle.blocked_edge_grow,
        ),
      ),
    );
  static final Paint _blocked_edge_paint = Paint()
    ..shader = const RadialGradient(
      center: Alignment(-.06, -.10),
      radius: .92,
      colors: QuestTileSurfaceStyle.blocked_edge_colors,
      stops: QuestTileSurfaceStyle.blocked_edge_stops,
    ).createShader(const Rect.fromLTWH(0, 0, 1, 1));

  static ui.Image? _body_image;
  static ui.Image? _shadow_image;
  static bool _preparation_failed = false;

  /// 场景纹理加载时预热；全局只栅格化一次，不等待玩家第一次点击。
  static void prepare() {
    if (_body_image != null || _preparation_failed) return;
    final recorder = ui.PictureRecorder();
    _material.paint(Canvas(recorder), detailed: true);
    final picture = recorder.endRecording();
    try {
      // 同步取得 GPU 图片句柄，栅格化由引擎异步完成；没有 CPU 读回。
      _body_image = picture.toImageSync(
        QuestTileSurfaceStyle.cell_edge,
        QuestTileSurfaceStyle.cell_height,
      );
      final shadow_recorder = ui.PictureRecorder();
      _material.paint_shadows(Canvas(shadow_recorder));
      final shadow_picture = shadow_recorder.endRecording();
      try {
        _shadow_image = shadow_picture.toImageSync(
          QuestTileSurfaceStyle.cell_edge,
          QuestTileSurfaceStyle.cell_height,
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

  /// 绘制格宽度（含落影外扩），相对逻辑牌宽度。
  static double get cell_scale => QuestTileSurfaceStyle.cell_scale;

  /// 逻辑牌格 → 绘制格。牌体与投影共用这一换算，禁止各组件自行加边距。
  static Rect cell_rect(Rect tile) {
    return tile.inflate(tile.width * QuestTileSurfaceStyle.bleed);
  }

  /// 图案区域；输入是逻辑牌格，返回值是场景绝对坐标。
  /// 图标尺寸始终由牌宽决定，底板加高不能把原始图案纵向拉长。
  static Rect icon_rect(Rect tile) {
    const icon = QuestTileSurfaceStyle.icon;
    return Rect.fromCenter(
      center: Offset(
        tile.left + icon.center.dx * tile.width,
        tile.top + icon.center.dy * tile.height,
      ),
      width: icon.width * tile.width,
      height: icon.height * tile.width,
    );
  }

  /// 从含投影绘制格还原逻辑牌，横纵共享由牌宽计算的投影留白。
  static Rect _logical_rect(Rect cell) {
    final width = cell.width / QuestTileSurfaceStyle.cell_scale;
    return cell.deflate((cell.width - width) / 2);
  }

  /// 命中检测只看牌体轮廓，模糊投影不能拦截落在下层牌上的点击。
  static bool contains(Rect bounds, Offset point) {
    if (bounds.isEmpty || !bounds.contains(point)) return false;
    final local = Offset(
      (point.dx - bounds.left) / bounds.width,
      (point.dy - bounds.top) / bounds.height,
    );
    return _unit_silhouette.contains(local);
  }

  /// 一张完整牌：牌体 + 图案 + 遮挡态。`rect` 始终是逻辑牌格。
  static void paint(
    Canvas canvas,
    Rect rect, {
    ui.Image? icon,
    ui.Image? body,
    bool blocked = false,
    double? blocked_amount,
    bool icon_shadow = false,
  }) {
    if (rect.isEmpty) return;
    final amount = (blocked_amount ?? (blocked ? 1.0 : 0.0)).clamp(0.0, 1.0);
    final cell = cell_rect(rect);
    if (!_paint_body(canvas, cell, body, amount)) return;
    if (amount > 0) _paint_blocked_edge(canvas, cell, amount);
    if (icon != null) {
      _paint_icon(
        canvas,
        rect,
        icon,
        soft_shadow: icon_shadow,
        blocked_amount: amount,
      );
    }
  }

  /// 在被压住的牌边缘叠加径向环境影。
  ///
  /// 路径是相对“逻辑牌”的归一化坐标，而绘制格比逻辑牌大 [cell_scale] 倍，
  /// 因此必须先缩回逻辑牌尺寸，否则蒙层会外扩到相邻牌上形成暗带。
  static void _paint_blocked_edge(Canvas canvas, Rect cell, double amount) {
    final tile = _logical_rect(cell);
    canvas.save();
    canvas.translate(tile.left, tile.top);
    canvas.scale(tile.width, tile.height);
    _blocked_edge_paint.color = Colors.white.withValues(alpha: amount);
    canvas.drawPath(_blocked_edge_path, _blocked_edge_paint);
    canvas.restore();
  }

  /// 牌体优先使用预烘焙 PNG；缺失时使用同一材质的向量烘焙图。
  static bool _paint_body(
    Canvas canvas,
    Rect cell,
    ui.Image? body,
    double blocked_amount,
  ) {
    final paint = _image_filter(blocked_amount);
    if (body != null) {
      try {
        prepare();
        final shadow = _shadow_image;
        if (shadow != null) {
          canvas.drawImageRect(
            shadow,
            Rect.fromLTWH(
              0,
              0,
              shadow.width.toDouble(),
              shadow.height.toDouble(),
            ),
            cell,
            _image_paint,
          );
        }
        final tile = _logical_rect(cell);
        final target = QuestTileSurfaceStyle.resolve(
          QuestTileSurfaceStyle.body,
          tile,
        );
        final source_size = Size(body.width.toDouble(), body.height.toDouble());
        // 底部厚度占用额外高度，整块底板纵向展开，瓷面恢复接近正方形。
        // 原始PNG不含投影留白，只填牌体目标，不能填满整个绘制格。
        canvas.drawImageRect(
          body,
          Offset.zero & source_size,
          target,
          _image_filter(blocked_amount, body: true),
        );
        return true;
      } catch (_) {
        // 材质图失效时退回向量烘焙图，不能阻断整个棋盘绘制。
      }
    }
    prepare();
    final fallback = _body_image;
    if (fallback != null) {
      try {
        canvas.drawImageRect(
          fallback,
          Rect.fromLTWH(
            0,
            0,
            fallback.width.toDouble(),
            fallback.height.toDouble(),
          ),
          cell,
          paint,
        );
        return true;
      } catch (_) {
        // 延迟 GPU 栅格化失败时退回逐帧矢量，不能反复抛错。
        _body_image = null;
        _preparation_failed = true;
        fallback.dispose();
      }
    }
    canvas.save();
    canvas.translate(cell.left, cell.top);
    canvas.scale(cell.width / QuestTileSurfaceStyle.cell_edge);
    _material.paint(canvas, blocked_amount: blocked_amount);
    canvas.restore();
    return true;
  }

  /// 图案的柔和投影只烘焙进图集一次；冷启动回退不承担逐牌模糊成本。
  static void _paint_icon(
    Canvas canvas,
    Rect tile,
    ui.Image icon, {
    required bool soft_shadow,
    required double blocked_amount,
  }) {
    final source = Rect.fromLTWH(
      0,
      0,
      icon.width.toDouble(),
      icon.height.toDouble(),
    );
    final bounds = icon_rect(tile);
    final fit = applyBoxFit(BoxFit.contain, source.size, bounds.size);
    final target = Alignment.center.inscribe(fit.destination, bounds);
    if (soft_shadow) {
      _draw_icon_shadow(
        canvas,
        icon,
        source,
        target,
        tile,
        offset: QuestTileSurfaceStyle.icon_contact_offset,
        sigma: QuestTileSurfaceStyle.icon_contact_sigma,
        color: QuestTileSurfaceStyle.icon_contact_color,
      );
      _draw_icon_shadow(
        canvas,
        icon,
        source,
        target,
        tile,
        offset: QuestTileSurfaceStyle.icon_shadow_offset,
        sigma: QuestTileSurfaceStyle.icon_shadow_sigma,
        color: QuestTileSurfaceStyle.icon_shadow_color,
      );
    }
    canvas.drawImageRect(icon, source, target, _image_filter(blocked_amount));
  }

  /// 冷启动/素材故障回退也连续变亮。颜色矩阵直接作用于采样像素，
  /// 不创建离屏层；普通/遮挡端点复用已有 Paint，中间态才计算矩阵。
  static Paint _image_filter(double amount, {bool body = false}) {
    if (amount <= 0) return body ? _body_image_paint : _image_paint;
    if (amount >= 1) return body ? _blocked_body_paint : _blocked_image_paint;
    final paint = body ? _fade_body_paint : _fade_image_paint;
    paint.colorFilter = _color_filter(amount, body: body);
    return paint;
  }

  static ColorFilter _color_filter(double amount, {bool body = false}) {
    final normal = body ? QuestTileSurfaceStyle.body_filter : _identity_filter;
    final blocked = body
        ? _blocked_body_filter
        : QuestTileSurfaceStyle.blocked_filter;
    return ColorFilter.matrix([
      for (var index = 0; index < normal.length; index++)
        normal[index] + (blocked[index] - normal[index]) * amount,
    ]);
  }

  /// 图案投影只绘制一次（图集烘焙阶段），不进入普通交互帧。
  static void _draw_icon_shadow(
    Canvas canvas,
    ui.Image icon,
    Rect source,
    Rect target,
    Rect tile, {
    required Offset offset,
    required double sigma,
    required Color color,
  }) {
    final paint = Paint()
      ..colorFilter = ColorFilter.mode(color, BlendMode.srcIn)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, tile.width * sigma);
    canvas.drawImageRect(
      icon,
      source,
      target.shift(Offset(offset.dx * tile.width, offset.dy * tile.width)),
      paint,
    );
  }
}

/// 素材缺失时的向量陶瓷牌；几何取 [QuestTileSurfaceStyle]，
/// 材质与配色取 [TileQuestTileStyle]，与独立组件 `TileQuestTile` 视觉一致。
class _QuestTileMaterial {
  _QuestTileMaterial() {
    final tile = _tile_rect;
    body = RRect.fromRectAndRadius(
      QuestTileSurfaceStyle.resolve(QuestTileSurfaceStyle.body, tile),
      Radius.circular(tile.width * QuestTileSurfaceStyle.radius),
    );
    face = RRect.fromRectAndRadius(
      QuestTileSurfaceStyle.resolve(QuestTileSurfaceStyle.face, tile),
      Radius.circular(tile.width * QuestTileSurfaceStyle.radius),
    );
    final inset = tile.width * QuestTileSurfaceStyle.bevel;
    face_inset = RRect.fromRectAndRadius(
      face.outerRect.deflate(inset),
      Radius.circular(tile.width * QuestTileSurfaceStyle.radius - inset),
    );
    silhouette = Path()..addRRect(body);
    exposed_side = Path.combine(
      PathOperation.difference,
      silhouette,
      Path()..addRRect(face),
    );

    // 厚度条矩形：牌体底部 side_depth 高的横带，墙面渐变的取值域。
    final body_rect = body.outerRect;
    final wall_strip = Rect.fromLTRB(
      body_rect.left,
      body_rect.bottom - body_rect.height * QuestTileSurfaceStyle.side_depth,
      body_rect.right,
      body_rect.bottom,
    );
    final face_rect = face.outerRect;
    final inner_rect = face_inset.outerRect;

    // 第二层：厚度——灰棕五段梯度。
    body_paint.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        TileQuestTileStyle.wall_ledge,
        TileQuestTileStyle.wall_top,
        TileQuestTileStyle.wall_mid,
        TileQuestTileStyle.wall_bottom,
        TileQuestTileStyle.wall_floor,
      ],
      stops: [0.0, 0.22, 0.50, 0.80, 1.0],
    ).createShader(wall_strip);

    // 厚度右缘暗化。
    wall_shade_paint.shader = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: TileQuestTileStyle.wall_shade_colors,
    ).createShader(wall_strip);

    // 第三、四层：曲面（正面+倒角一体）。
    // 最外层先铺曲面边缘的暗色。
    face_paint.shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [TileQuestTileStyle.face_main, TileQuestTileStyle.face_bottom],
    ).createShader(face_rect);

    // 向内连续插值：每一层比外层更亮一点，形成凸起曲面。
    for (var step = 0; step < QuestTileSurfaceStyle.bevel_steps; step++) {
      final t = (step + 1) / (QuestTileSurfaceStyle.bevel_steps + 1);
      final section = RRect.lerp(face, face_inset, t)!;
      final top = Color.lerp(
        TileQuestTileStyle.face_main,
        TileQuestTileStyle.face_center,
        t,
      )!;
      final bottom = Color.lerp(
        TileQuestTileStyle.face_bottom,
        TileQuestTileStyle.face_main,
        t,
      )!;
      _bevel_sections.add((
        section,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [top, bottom],
          ).createShader(section.outerRect),
      ));
    }

    // 最内层：曲面顶部，最亮。
    core_paint.shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [TileQuestTileStyle.face_center, TileQuestTileStyle.face_main],
    ).createShader(inner_rect);

    // 第五层：漫画高光——大笔触柔光 + 辅助碎光。
    final highlight_center = Offset(
      body_rect.left + body_rect.width * 0.26,
      body_rect.top + body_rect.height * 0.20,
    );
    final major = face_rect.width * TileQuestTileStyle.highlight_major;
    final minor = face_rect.width * TileQuestTileStyle.highlight_minor;
    _highlight_center = highlight_center;
    _highlight_rotation = TileQuestTileStyle.highlight_rotation;
    _highlight_tail = Rect.fromCenter(
      center: Offset(major * 0.20, minor * 0.10),
      width: major * 2.6,
      height: minor * 2.1,
    );
    _highlight_core = Rect.fromCenter(
      center: Offset(-major * 0.12, -minor * 0.18),
      width: major * 1.9,
      height: minor * 1.7,
    );
    _highlight_tail_paint.shader = const RadialGradient(
      colors: TileQuestTileStyle.highlight_tail_colors,
      stops: [0.0, 0.50, 1.0],
    ).createShader(_highlight_tail);
    _highlight_core_paint.shader = const RadialGradient(
      colors: TileQuestTileStyle.highlight_core_colors,
      stops: [0.0, 0.42, 1.0],
    ).createShader(_highlight_core);

    final aux_center = Offset(
      body_rect.left + body_rect.width * 0.155,
      body_rect.top + body_rect.height * 0.370,
    );
    final aux_radius =
        face_rect.width * TileQuestTileStyle.highlight_aux_radius;
    _highlight_aux = Rect.fromCircle(center: aux_center, radius: aux_radius);
    _highlight_aux_paint.shader = const RadialGradient(
      colors: TileQuestTileStyle.highlight_aux_colors,
    ).createShader(_highlight_aux);
  }

  /// 牌体所在的归一化坐标 → 绘制格像素；四周是投影外扩区域。
  static Rect get _tile_rect {
    final margin = QuestTileSurfaceStyle.bleed * QuestTileSurfaceStyle.edge;
    return Rect.fromLTWH(
      margin,
      margin,
      QuestTileSurfaceStyle.edge.toDouble(),
      QuestTileSurfaceStyle.height.toDouble(),
    );
  }

  late final RRect body, face, face_inset;
  late final Path silhouette, exposed_side;
  final _bevel_sections = <(RRect, Paint)>[];
  final Paint body_paint = Paint(), wall_shade_paint = Paint();
  final Paint face_paint = Paint(), core_paint = Paint();
  late final Offset _highlight_center;
  late final double _highlight_rotation;
  late final Rect _highlight_tail, _highlight_core, _highlight_aux;
  final Paint _highlight_tail_paint = Paint();
  final Paint _highlight_core_paint = Paint();
  final Paint _highlight_aux_paint = Paint();
  final Paint ambient_paint = Paint()
    ..color = TileQuestTileStyle.shadow_color
    ..maskFilter = MaskFilter.blur(
      BlurStyle.normal,
      TileQuestTileStyle.shadow_sigma * QuestTileSurfaceStyle.edge,
    );
  final Paint contact_paint = Paint()
    ..color = TileQuestTileStyle.contact_color
    ..maskFilter = MaskFilter.blur(
      BlurStyle.normal,
      TileQuestTileStyle.contact_sigma * QuestTileSurfaceStyle.edge,
    );

  void paint(
    Canvas canvas, {
    bool detailed = false,
    double blocked_amount = 0,
  }) {
    // 最后一级 GPU 图片故障才会逐路径回退；shader 和纯色共用相同滤镜。
    final filter = blocked_amount <= 0
        ? null
        : QuestTileSurface._color_filter(blocked_amount);
    for (final paint in [
      body_paint,
      wall_shade_paint,
      face_paint,
      core_paint,
      for (final section in _bevel_sections) section.$2,
      _highlight_tail_paint,
      _highlight_core_paint,
      _highlight_aux_paint,
    ]) {
      paint.colorFilter = filter;
    }
    if (detailed) paint_shadows(canvas);
    // 厚度：整块牌体承载墙面渐变，正面覆盖后只剩底缘可见。
    canvas.drawRRect(body, body_paint);
    canvas.drawRRect(body, wall_shade_paint);
    // 曲面：从外向内连续插值的凸面渐变，正面与倒角一体无硬分界。
    canvas.drawRRect(face, face_paint);
    for (final (section, paint) in _bevel_sections) {
      canvas.drawRRect(section, paint);
    }
    canvas.drawRRect(face_inset, core_paint);
    // 漫画高光：亮核 + 拖尾 + 辅助碎光。
    canvas.save();
    canvas.translate(_highlight_center.dx, _highlight_center.dy);
    canvas.rotate(_highlight_rotation);
    canvas.drawOval(_highlight_tail, _highlight_tail_paint);
    canvas.drawOval(_highlight_core, _highlight_core_paint);
    canvas.restore();
    canvas.drawOval(_highlight_aux, _highlight_aux_paint);
  }

  /// 只有烘焙共享回退材质时调用；图集与交互帧只采样已完成的图片。
  void paint_shadows(Canvas canvas) {
    final edge = QuestTileSurfaceStyle.edge.toDouble();
    canvas.drawPath(
      silhouette.shift(TileQuestTileStyle.shadow_offset * edge),
      ambient_paint,
    );
    canvas.drawPath(
      silhouette.shift(TileQuestTileStyle.contact_offset * edge),
      contact_paint,
    );
  }
}
