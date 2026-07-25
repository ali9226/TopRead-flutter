import 'dart:math' as math;
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';

/// 可爱的断网云朵组件。
///
/// 一只趴在桌上的小云朵，闭着眼睛打瞌睡，
/// 旁边飘着一个断开的 Wi-Fi 符号，表达"没有网络"的状态。
///
/// 参数说明：
/// [size] - 组件尺寸（正方形）。
/// [isDark] - 当前是否为夜间模式。
class CuteNoInternetCloud extends StatelessWidget {
  /// 组件尺寸。
  final double size;

  /// 是否为夜间模式。
  final bool isDark;

  const CuteNoInternetCloud({
    super.key,
    this.size = 180,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      builder: (BuildContext context, double progress, Widget? child) {
        return Transform.scale(
          scale: progress,
          child: CustomPaint(
            size: Size(size, size),
            painter: _CloudPainter(isDark: isDark),
          ),
        );
      },
    );
  }
}

/// 云朵绘制器。
///
/// 绘制内容：
/// - 一朵圆润的小云朵（身体）
/// - 闭着的眼睛（弯弯的弧线）
/// - 微微下撇的小嘴（表示沮丧）
/// - 两团腮红
/// - 一个断开的 Wi-Fi 符号（带斜杠）
/// - 几颗漂浮的 zzz（表示打瞌睡）
class _CloudPainter extends CustomPainter {
  /// 是否为夜间模式。
  final bool isDark;

  _CloudPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    _drawDisconnectedWifi(canvas, cx, cy);
    _drawZzz(canvas, cx, cy);
    _drawCloudBody(canvas, cx, cy);
    _drawFace(canvas, cx, cy);
    _drawBlush(canvas, cx, cy);
  }

  /// 绘制断开的 Wi-Fi 符号。
  ///
  /// 位于云朵右上方，带一条斜杠表示断开。
  void _drawDisconnectedWifi(Canvas canvas, double cx, double cy) {
    final double wifiX = cx + 32;
    final double wifiY = cy - 38;

    final Paint wifiPaint = Paint()
      ..color = isDark
          ? const Color(0xFF6CA0DC).withValues(alpha: 0.6)
          : const Color(0xFF4A90D9).withValues(alpha: 0.5)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Wi-Fi 弧线（三条弧线，从外到内）。
    for (int i = 0; i < 3; i++) {
      final double radius = 8.0 + i * 7;
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(wifiX, wifiY + 4),
          width: radius * 2,
          height: radius * 2,
        ),
        -math.pi * 0.75,
        math.pi * 0.5,
        false,
        wifiPaint,
      );
    }

    // Wi-Fi 中心小圆点。
    final Paint dotPaint = Paint()
      ..color = isDark
          ? const Color(0xFF6CA0DC).withValues(alpha: 0.7)
          : const Color(0xFF4A90D9).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(wifiX, wifiY + 4), 2.5, dotPaint);

    // 斜杠（表示断开）。
    final Paint slashPaint = Paint()
      ..color = isDark
          ? const Color(0xFFFF6B6B).withValues(alpha: 0.7)
          : const Color(0xFFE85D75).withValues(alpha: 0.6)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(wifiX - 16, wifiY + 20),
      Offset(wifiX + 16, wifiY - 16),
      slashPaint,
    );
  }

  /// 绘制打瞌睡的 zzz 符号。
  ///
  /// 位于云朵左上方，由小到大排列。
  void _drawZzz(Canvas canvas, double cx, double cy) {
    final Paint zPaint = Paint()
      ..color = isDark
          ? const Color(0xFF8B8B9E).withValues(alpha: 0.4)
          : const Color(0xFF999999).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    // 三个不同大小的 z，从左下到右上排列。
    final List<Offset> positions = <Offset>[
      Offset(cx - 40, cy - 20),
      Offset(cx - 48, cy - 36),
      Offset(cx - 54, cy - 54),
    ];
    final List<double> sizes = <double>[8, 10, 12];

    for (int i = 0; i < 3; i++) {
      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: 'z',
          style: TextStyle(
            fontSize: sizes[i],
            fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
            color: zPaint.color,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          positions[i].dx - textPainter.width / 2,
          positions[i].dy - textPainter.height / 2,
        ),
      );
    }
  }

  /// 绘制云朵身体。
  ///
  /// 由多个重叠的圆形组成云朵形状，底部稍微扁平（趴在桌上的感觉）。
  void _drawCloudBody(Canvas canvas, double cx, double cy) {
    // 云朵主体颜色。
    final Color bodyColor = isDark
        ? const Color(0xFF3A3D4A)
        : const Color(0xFFF0F0F5);

    // 云朵高光颜色。
    final Color highlightColor = isDark
        ? const Color(0xFF4A4D5A)
        : const Color(0xFFFAFAFF);

    // 云朵阴影颜色。
    final Color shadowColor = isDark
        ? const Color(0xFF2A2D3A)
        : const Color(0xFFE0E0E8);

    // 底部阴影（趴在桌上的感觉）。
    final Paint shadowPaint = Paint()
      ..color = shadowColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + 28),
        width: 100,
        height: 14,
      ),
      shadowPaint,
    );

    // 云朵主体（多个圆形组合）。
    final Paint bodyPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;

    // 主圆（中间偏右）。
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 4, cy + 6), width: 80, height: 52),
      bodyPaint,
    );

    // 左侧凸起。
    canvas.drawCircle(Offset(cx - 24, cy + 2), 26, bodyPaint);

    // 右侧凸起。
    canvas.drawCircle(Offset(cx + 30, cy - 2), 22, bodyPaint);

    // 顶部凸起（云朵的"鼓包"）。
    canvas.drawCircle(Offset(cx + 2, cy - 16), 24, bodyPaint);

    // 高光层（让云朵更立体）。
    final Paint highlightPaint = Paint()
      ..color = highlightColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - 8, cy - 12),
        width: 32,
        height: 20,
      ),
      highlightPaint,
    );

    canvas.drawCircle(Offset(cx + 24, cy - 6), 12, highlightPaint);
  }

  /// 绘制面部表情。
  ///
  /// - 闭着的眼睛（弯弯的弧线，像在打瞌睡）
  /// - 微微下撇的小嘴（表示沮丧/无奈）
  void _drawFace(Canvas canvas, double cx, double cy) {
    // 闭着的眼睛（弯弯弧线）。
    final Paint eyePaint = Paint()
      ..color = isDark
          ? const Color(0xFFE8E8EA).withValues(alpha: 0.8)
          : const Color(0xFF4A4A4A).withValues(alpha: 0.7)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 左眼。
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx - 12, cy - 2),
        width: 14,
        height: 10,
      ),
      0,
      math.pi,
      false,
      eyePaint,
    );

    // 右眼。
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx + 16, cy - 2),
        width: 14,
        height: 10,
      ),
      0,
      math.pi,
      false,
      eyePaint,
    );

    // 小嘴（微微下撇的弧线）。
    final Paint mouthPaint = Paint()
      ..color = isDark
          ? const Color(0xFFE8E8EA).withValues(alpha: 0.6)
          : const Color(0xFF4A4A4A).withValues(alpha: 0.5)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx + 2, cy + 10),
        width: 16,
        height: 10,
      ),
      math.pi * 0.1,
      math.pi * 0.8,
      false,
      mouthPaint,
    );
  }

  /// 绘制腮红。
  ///
  /// 两团淡淡的圆形腮红，增加可爱感。
  void _drawBlush(Canvas canvas, double cx, double cy) {
    final Paint blushPaint = Paint()
      ..color = isDark
          ? const Color(0xFFFF9E80).withValues(alpha: 0.15)
          : const Color(0xFFFFB3A0).withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    // 左腮红。
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - 22, cy + 6),
        width: 14,
        height: 8,
      ),
      blushPaint,
    );

    // 右腮红。
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + 26, cy + 6),
        width: 14,
        height: 8,
      ),
      blushPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CloudPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
