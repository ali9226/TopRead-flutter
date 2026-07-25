import 'dart:math';
import 'package:flutter/material.dart';

/// 顶部星星点缀装饰组件。
///
/// 多个大小不一、透明度各异的金色四角星随机散布在区域内，
/// 营造类似 ✨ 的星光点缀效果，仅用于夜间模式。
class StarfieldDecoration extends StatelessWidget {
  /// 是否为夜间模式。
  final bool is_dark;

  const StarfieldDecoration({super.key, required this.is_dark});

  @override
  Widget build(BuildContext context) {
    /// 日间模式用主题色，夜间模式用金色。
    final Color color = is_dark
        ? const Color(0xFFFFD45A)
        : const Color(0xFFFFC94D);
    /// 日间模式透明度更高（背景浅，需要更明显），夜间模式透明度适中。
    final double base = is_dark ? 1.0 : 1.8;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: SizedBox(
          height: 100,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned(top: 10, left: 20, child: _star(14, 0.40 * base, color)),
              Positioned(top: 4, left: 80, child: _star(9, 0.28 * base, color)),
              Positioned(top: 30, left: 50, child: _star(11, 0.45 * base, color)),
              Positioned(top: 18, left: 140, child: _star(18, 0.55 * base, color)),
              Positioned(top: 6, left: 190, child: _star(7, 0.22 * base, color)),
              Positioned(top: 40, left: 110, child: _star(9, 0.30 * base, color)),
              Positioned(top: 12, right: 130, child: _star(12, 0.42 * base, color)),
              Positioned(top: 35, right: 80, child: _star(16, 0.50 * base, color)),
              Positioned(top: 8, right: 40, child: _star(9, 0.25 * base, color)),
              Positioned(top: 50, right: 100, child: _star(11, 0.32 * base, color)),
            ],
          ),
        ),
      ),
    );
  }

  /// 单个四角星形（✨ 效果）。
  static Widget _star(double size, double opacity, Color color) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SparklePainter(opacity: opacity, color: color),
    );
  }
}

/// 四角星画笔，绘制类似 ✨ 的放射状星形。
class _SparklePainter extends CustomPainter {
  final double opacity;
  final Color color;

  _SparklePainter({required this.opacity, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double outer = size.width / 2;
    final double inner = outer * 0.22;

    final Paint paint = Paint()
      ..color = color.withValues(alpha: opacity.clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    final Path path = Path();
    for (int i = 0; i < 4; i++) {
      final double outerAngle = (i * 90 - 90) * pi / 180;
      final double innerAngle = ((i * 90 + 45) - 90) * pi / 180;
      final double ox = cx + outer * cos(outerAngle);
      final double oy = cy + outer * sin(outerAngle);
      final double ix = cx + inner * cos(innerAngle);
      final double iy = cy + inner * sin(innerAngle);
      if (i == 0) {
        path.moveTo(ox, oy);
      } else {
        path.lineTo(ox, oy);
      }
      path.lineTo(ix, iy);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) =>
      oldDelegate.opacity != opacity || oldDelegate.color != color;
}
