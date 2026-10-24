import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

/// 可爱猫咪吉祥物组件。
///
/// 展示一只坐在书本上的小猫，当用户输入密码时，
/// 小猫会用爪子遮住眼睛，呈现"不偷看"的可爱效果。
///
/// 参数说明：
/// [isCovering] - 是否处于遮眼状态（用户正在输入）。
/// [isDark] - 当前是否为夜间模式。
class CuteMascot extends StatelessWidget {
  /// 是否处于遮眼状态。
  final bool isCovering;

  /// 当前是否为夜间模式。
  final bool isDark;

  const CuteMascot({super.key, required this.isCovering, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: isCovering ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      builder: (BuildContext context, double coverValue, Widget? child) {
        return CustomPaint(
          size: const Size(140, 140),
          painter: _CatPainter(coverProgress: coverValue, isDark: isDark),
        );
      },
    );
  }
}

/// 猫咪绘制器。
///
/// 使用 CustomPainter 绘制一只可爱的卡通猫咪，
/// 包含：猫头、耳朵、眼睛、鼻子、嘴巴、胡须、身体、爪子。
/// 遮眼时爪子会移动到眼睛前方。
class _CatPainter extends CustomPainter {
  /// 遮眼动画进度（0 = 睁眼, 1 = 完全遮眼）。
  final double coverProgress;

  /// 是否为夜间模式。
  final bool isDark;

  _CatPainter({required this.coverProgress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    _drawBook(canvas, cx, cy + 38, size.width * 0.7, 22);
    _drawBody(canvas, cx, cy + 10);
    _drawHead(canvas, cx, cy - 12);
    _drawEars(canvas, cx, cy - 12);
    _drawEyes(canvas, cx, cy - 12);
    _drawNoseAndMouth(canvas, cx, cy - 12);
    _drawWhiskers(canvas, cx, cy - 12);
    _drawPaws(canvas, cx, cy + 10);
  }

  void _drawBook(
    Canvas canvas,
    double cx,
    double cy,
    double width,
    double height,
  ) {
    final Paint bookPaint = Paint()
      ..color = isDark ? ColorConstants.components_cute_mascot_index_tone : ColorConstants.components_cute_mascot_index_tone_ff8b7355
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: width, height: height),
        const Radius.circular(LayoutConfig.radius_4),
      ),
      bookPaint,
    );

    final Paint pagePaint = Paint()
      ..color = isDark ? ColorConstants.components_cute_mascot_index_tone_ff2a2d3a : ColorConstants.components_cute_mascot_index_tone_fff5f0e8
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, cy - 2),
          width: width - 8,
          height: height - 6,
        ),
        const Radius.circular(LayoutConfig.radius_2),
      ),
      pagePaint,
    );

    final Paint spinePaint = Paint()
      ..color = isDark ? ColorConstants.components_cute_mascot_index_tone_ff4a4d5a : ColorConstants.components_cute_mascot_index_tone_ffd4c8b0
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(cx, cy - height / 2 + 2),
      Offset(cx, cy + height / 2 - 2),
      spinePaint,
    );
  }

  void _drawBody(Canvas canvas, double cx, double cy) {
    final Paint bodyPaint = Paint()
      ..color = isDark ? ColorConstants.components_cute_mascot_index_tone_ff3a3a3a : ColorConstants.components_cute_mascot_index_tone_ff4a4a4a
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: 52, height: 40),
      bodyPaint,
    );

    final Paint bellyPaint = Paint()
      ..color = isDark ? ColorConstants.components_cute_mascot_index_tone_ff5a5a5a : ColorConstants.components_cute_mascot_index_tone_ff6a6a6a
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 2), width: 30, height: 22),
      bellyPaint,
    );
  }

  void _drawHead(Canvas canvas, double cx, double cy) {
    final Paint headPaint = Paint()
      ..color = isDark ? ColorConstants.components_cute_mascot_index_tone_ff3a3a3a : ColorConstants.components_cute_mascot_index_tone_ff4a4a4a
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: 56, height: 50),
      headPaint,
    );

    final Paint facePaint = Paint()
      ..color = isDark ? ColorConstants.components_cute_mascot_index_tone_ff5a5a5a : ColorConstants.components_cute_mascot_index_tone_ff6a6a6a
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 4), width: 36, height: 28),
      facePaint,
    );
  }

  void _drawEars(Canvas canvas, double cx, double cy) {
    final Paint earPaint = Paint()
      ..color = isDark ? ColorConstants.components_cute_mascot_index_tone_ff3a3a3a : ColorConstants.components_cute_mascot_index_tone_ff4a4a4a
      ..style = PaintingStyle.fill;

    final Paint innerEarPaint = Paint()
      ..color = isDark ? ColorConstants.components_cute_mascot_index_tone_ff6a4a4a : ColorConstants.components_cute_mascot_index_tone_ff8b6b6b
      ..style = PaintingStyle.fill;

    canvas.drawPath(
      Path()
        ..moveTo(cx - 22, cy - 18)
        ..lineTo(cx - 30, cy - 42)
        ..lineTo(cx - 10, cy - 22)
        ..close(),
      earPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(cx - 21, cy - 20)
        ..lineTo(cx - 27, cy - 38)
        ..lineTo(cx - 13, cy - 23)
        ..close(),
      innerEarPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(cx + 22, cy - 18)
        ..lineTo(cx + 30, cy - 42)
        ..lineTo(cx + 10, cy - 22)
        ..close(),
      earPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(cx + 21, cy - 20)
        ..lineTo(cx + 27, cy - 38)
        ..lineTo(cx + 13, cy - 23)
        ..close(),
      innerEarPaint,
    );
  }

  void _drawEyes(Canvas canvas, double cx, double cy) {
    final double eyeOpacity = 1.0 - coverProgress * 0.8;

    final Paint eyeWhitePaint = Paint()
      ..color = ColorConstants.whiteColor.withValues(alpha: eyeOpacity)
      ..style = PaintingStyle.fill;

    final Paint eyePupilPaint = Paint()
      ..color = Color.lerp(
        isDark ? ColorConstants.components_cute_mascot_index_tone_ff1a1a1a : ColorConstants.components_cute_mascot_index_tone_ff2a2a2a,
        isDark ? ColorConstants.components_cute_mascot_index_tone_ff3a3a3a : ColorConstants.components_cute_mascot_index_tone_ff4a4a4a,
        coverProgress,
      )!
      ..style = PaintingStyle.fill;

    final Paint highlightPaint = Paint()
      ..color = ColorConstants.whiteColor.withValues(alpha: eyeOpacity * 0.9)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 10, cy - 4), width: 14, height: 14),
      eyeWhitePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 10, cy - 3), width: 8, height: 8),
      eyePupilPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 8, cy - 5), width: 3, height: 3),
      highlightPaint,
    );

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 10, cy - 4), width: 14, height: 14),
      eyeWhitePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 10, cy - 3), width: 8, height: 8),
      eyePupilPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 12, cy - 5), width: 3, height: 3),
      highlightPaint,
    );
  }

  void _drawNoseAndMouth(Canvas canvas, double cx, double cy) {
    final Paint nosePaint = Paint()
      ..color = isDark ? ColorConstants.components_cute_mascot_index_tone_ffe8a0a0 : ColorConstants.components_cute_mascot_index_tone_ffe89090
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 4), width: 6, height: 4),
      nosePaint,
    );

    final Paint mouthPaint = Paint()
      ..color = isDark ? ColorConstants.components_cute_mascot_index_tone_ff8a7a7a : ColorConstants.components_cute_mascot_index_tone_ff7a6a6a
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(
      Path()
        ..moveTo(cx, cy + 6)
        ..quadraticBezierTo(cx - 6, cy + 12, cx - 10, cy + 8),
      mouthPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(cx, cy + 6)
        ..quadraticBezierTo(cx + 6, cy + 12, cx + 10, cy + 8),
      mouthPaint,
    );
  }

  void _drawWhiskers(Canvas canvas, double cx, double cy) {
    final Paint whiskerPaint = Paint()
      ..color = isDark
          ? ColorConstants.components_authorized_login_apple_review_index_tone_4cffffff
          : ColorConstants.components_cute_mascot_index_tone_33222222
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(cx - 18, cy), Offset(cx - 36, cy - 4), whiskerPaint);
    canvas.drawLine(
      Offset(cx - 18, cy + 4),
      Offset(cx - 36, cy + 4),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(cx - 18, cy + 8),
      Offset(cx - 36, cy + 12),
      whiskerPaint,
    );
    canvas.drawLine(Offset(cx + 18, cy), Offset(cx + 36, cy - 4), whiskerPaint);
    canvas.drawLine(
      Offset(cx + 18, cy + 4),
      Offset(cx + 36, cy + 4),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(cx + 18, cy + 8),
      Offset(cx + 36, cy + 12),
      whiskerPaint,
    );
  }

  void _drawPaws(Canvas canvas, double cx, double cy) {
    final Paint pawPaint = Paint()
      ..color = isDark ? ColorConstants.components_cute_mascot_index_tone_ff3a3a3a : ColorConstants.components_cute_mascot_index_tone_ff4a4a4a
      ..style = PaintingStyle.fill;

    final Paint pawPadPaint = Paint()
      ..color = isDark ? ColorConstants.components_cute_mascot_index_tone_ff6a5a5a : ColorConstants.components_cute_mascot_index_tone_ff8b7a7a
      ..style = PaintingStyle.fill;

    final double leftPawX = cx - 26 + coverProgress * 16;
    final double leftPawY = cy + 14 - coverProgress * 22;
    final double rightPawX = cx + 26 - coverProgress * 16;
    final double rightPawY = cy + 14 - coverProgress * 22;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(leftPawX, leftPawY),
        width: 14,
        height: 10,
      ),
      pawPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(leftPawX, leftPawY), width: 8, height: 6),
      pawPadPaint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(rightPawX, rightPawY),
        width: 14,
        height: 10,
      ),
      pawPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(rightPawX, rightPawY),
        width: 8,
        height: 6,
      ),
      pawPadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CatPainter oldDelegate) {
    return oldDelegate.coverProgress != coverProgress ||
        oldDelegate.isDark != isDark;
  }
}
