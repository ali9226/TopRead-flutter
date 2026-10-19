// ignore_for_file: non_constant_identifier_names
import 'package:flutter/material.dart';
import 'tile_quest_tile_style.dart';

/// 2.5D 卡通方块底板的矢量材质。
///
/// 分五层自下而上绘制：投影 → 立体厚度 → 曲面（正面+倒角一体的凸面渐变）
/// → 漫画高光 → 遮挡薄纱。正面与倒角不画硬分界，用多层同心 RRect 把
/// 暖奶油到暖棕的色变铺成连续曲面，模拟陶瓷圆盘从上方看的凸起弧面。
class TileQuestTilePainter extends CustomPainter {
  TileQuestTilePainter({
    required this.is_blocked,
    required this.is_selected,
    required this.elevation,
  });

  /// 被其他方块遮挡：压暗并叠暖灰，保留立体结构。
  final bool is_blocked;

  /// 选中：整体上抬、阴影加强。
  final bool is_selected;

  /// 阴影强度，1 为标准；0 最轻、2 最重。
  final double elevation;

  @override
  void paint(Canvas canvas, Size size) {
    final body = TileQuestTileStyle.body_rect(size);
    if (body.isEmpty) return;

    // 投影始终贴地，不随选中上抬。
    _paint_shadow(canvas, body, size);

    final lift = is_selected
        ? size.shortestSide * TileQuestTileStyle.selected_lift
        : 0.0;
    canvas.save();
    canvas.translate(0, -lift);
    _paint_wall(canvas, body, size);
    _paint_dome(canvas, body, size);
    _paint_highlights(canvas, size);
    if (is_blocked) _paint_blocked(canvas, body, size);
    canvas.restore();
  }

  // ------------------------------------------------------------ 第一层：投影 --
  void _paint_shadow(Canvas canvas, Rect body, Size size) {
    final scale = body.width;
    final boost = is_selected ? TileQuestTileStyle.selected_shadow_boost : 0.0;
    final strength = (elevation + boost).clamp(0.0, 2.2);
    final silhouette = RRect.fromRectAndRadius(
      body,
      TileQuestTileStyle.body_radius(size),
    );

    final ambient = Paint()
      ..color = TileQuestTileStyle.shadow_color.withValues(
        alpha: (TileQuestTileStyle.shadow_color.a * (0.55 + 0.30 * strength))
            .clamp(0.0, 1.0),
      )
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        scale * TileQuestTileStyle.shadow_sigma * (0.88 + 0.12 * strength),
      );
    canvas.drawRRect(
      silhouette.shift(
        Offset(
          TileQuestTileStyle.shadow_offset.dx * scale * (0.9 + 0.1 * strength),
          TileQuestTileStyle.shadow_offset.dy * scale * (0.9 + 0.1 * strength),
        ),
      ),
      ambient,
    );

    final contact = Paint()
      ..color = TileQuestTileStyle.contact_color.withValues(
        alpha: (TileQuestTileStyle.contact_color.a * (0.65 + 0.25 * strength))
            .clamp(0.0, 1.0),
      )
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        scale * TileQuestTileStyle.contact_sigma,
      );
    canvas.drawRRect(
      silhouette.shift(
        Offset(
          TileQuestTileStyle.contact_offset.dx * scale,
          TileQuestTileStyle.contact_offset.dy * scale,
        ),
      ),
      contact,
    );
  }

  // ---------------------------------------------------------- 第二层：立体厚度 --
  void _paint_wall(Canvas canvas, Rect body, Size size) {
    final wall = RRect.fromRectAndRadius(
      body,
      TileQuestTileStyle.body_radius(size),
    );
    final strip = Rect.fromLTRB(
      body.left,
      body.bottom - body.height * TileQuestTileStyle.depth,
      body.right,
      body.bottom,
    );
    canvas.drawRRect(
      wall,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            TileQuestTileStyle.wall_ledge,
            TileQuestTileStyle.wall_top,
            TileQuestTileStyle.wall_mid,
            TileQuestTileStyle.wall_bottom,
            TileQuestTileStyle.wall_floor,
          ],
          stops: const [0.0, 0.22, 0.50, 0.80, 1.0],
        ).createShader(strip),
    );
    canvas.drawRRect(
      wall,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0x00000000), Color(0x2E000000)],
        ).createShader(strip),
    );
  }

  // ------------------------------------------ 第三、四层：曲面（正面+倒角一体） --
  /// 用多层同心 RRect 把「暖奶油 → 暖棕」的色变铺成连续曲面。
  ///
  /// 外圈是倒角（曲面滚下去的边缘），内圈是瓷面（曲面最平坦的顶部），
  /// 二者之间不画任何硬分界线，只靠色彩与圆角的连续插值形成凸起感。
  void _paint_dome(Canvas canvas, Rect body, Size size) {
    final face = TileQuestTileStyle.face_rect(size);
    final face_radius = TileQuestTileStyle.face_radius(size);
    final inner = TileQuestTileStyle.face_inner_rect(size);
    final inner_radius = TileQuestTileStyle.face_inner_radius(size);
    final outer = RRect.fromRectAndRadius(face, face_radius);
    final core = RRect.fromRectAndRadius(inner, inner_radius);

    // 最外层：曲面边缘最暗，先铺底色。
    canvas.drawRRect(
      outer,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [
            TileQuestTileStyle.face_main,
            TileQuestTileStyle.face_bottom,
          ],
        ).createShader(face),
    );

    // 向内连续插值：每一层都比外层更亮一点、更接近中心色。
    // 14 层保证在高 DPI 下看不到色阶。
    const steps = 14;
    for (var step = 1; step <= steps; step++) {
      final t = step / (steps + 1);
      final section = RRect.lerp(outer, core, t)!;
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
      canvas.drawRRect(
        section,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [top, bottom],
            stops: const [0.0, 1.0],
          ).createShader(section.outerRect),
      );
    }

    // 最内层：曲面顶部，最亮、渐变最平。
    canvas.drawRRect(
      core,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TileQuestTileStyle.face_center,
            TileQuestTileStyle.face_main,
          ],
          stops: [0.0, 1.0],
        ).createShader(inner),
    );
  }

  // ---------------------------------------------------------- 第五层：漫画高光 --
  /// 左上大面积柔光笔触 + 辅助碎光。
  void _paint_highlights(Canvas canvas, Size size) {
    final face = TileQuestTileStyle.face_rect(size);
    final major = face.width * TileQuestTileStyle.highlight_major;
    final minor = face.width * TileQuestTileStyle.highlight_minor;
    final center = TileQuestTileStyle.body_point(
      TileQuestTileStyle.highlight_center,
      size,
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(TileQuestTileStyle.highlight_rotation);

    // 外圈拖尾：更淡更大，垫出高光的软边。
    final tail = Rect.fromCenter(
      center: Offset(major * 0.20, minor * 0.10),
      width: major * 2.6,
      height: minor * 2.1,
    );
    canvas.drawOval(
      tail,
      Paint()
        ..shader = const RadialGradient(
          colors: [
            Color(0x28FFFFFF),
            Color(0x0CFFFFFF),
            Color(0x00FFFFFF),
          ],
          stops: [0.0, 0.50, 1.0],
        ).createShader(tail),
    );

    // 亮核：偏左上，主体高光，多段渐变软边。
    final core = Rect.fromCenter(
      center: Offset(-major * 0.12, -minor * 0.18),
      width: major * 1.9,
      height: minor * 1.7,
    );
    canvas.drawOval(
      core,
      Paint()
        ..shader = const RadialGradient(
          colors: [
            TileQuestTileStyle.highlight_main,
            Color(0x50FFFFFF),
            Color(0x00FFFFFF),
          ],
          stops: [0.0, 0.42, 1.0],
        ).createShader(core),
    );
    canvas.restore();

    // 辅助碎光。
    final aux_center = TileQuestTileStyle.body_point(
      TileQuestTileStyle.highlight_aux_center,
      size,
    );
    final aux_radius = face.width * TileQuestTileStyle.highlight_aux_radius;
    final aux = Rect.fromCircle(center: aux_center, radius: aux_radius);
    canvas.drawOval(
      aux,
      Paint()
        ..shader = const RadialGradient(
          colors: [
            TileQuestTileStyle.highlight_aux,
            Color(0x00FFFFFF),
          ],
        ).createShader(aux),
    );
  }

  // ---------------------------------------------------------------- 遮挡态 --
  void _paint_blocked(Canvas canvas, Rect body, Size size) {
    final wall = RRect.fromRectAndRadius(
      body,
      TileQuestTileStyle.body_radius(size),
    );
    canvas.drawRRect(
      wall,
      Paint()
        ..color = TileQuestTileStyle.blocked_multiply
        ..blendMode = BlendMode.multiply,
    );
    canvas.drawRRect(wall, Paint()..color = TileQuestTileStyle.blocked_veil);
  }

  @override
  bool shouldRepaint(covariant TileQuestTilePainter oldDelegate) =>
      is_blocked != oldDelegate.is_blocked ||
      is_selected != oldDelegate.is_selected ||
      elevation != oldDelegate.elevation;
}
