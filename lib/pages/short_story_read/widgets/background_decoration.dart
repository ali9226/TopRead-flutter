import 'package:flutter/material.dart';

import 'package:app/pages/short_story_read/style.dart';

/// 背景装饰组件。
///
/// 为阅读页面添加微妙的装饰圆形元素，提升视觉层次感。
/// 使用 [CustomPaint] 绘制两个半透明圆形：
/// - 右上角大圆（半径 50）
/// - 左侧中部小圆（半径 35）
///
/// 颜色随日间/夜间主题自动切换。
class BackgroundDecoration extends StatelessWidget {
  /// 是否为夜间模式。
  final bool is_dark;

  const BackgroundDecoration({
    super.key,
    required this.is_dark,
  });

  @override
  Widget build(BuildContext context) {
    /// 装饰元素颜色（极低透明度，仅作点缀）。
    final Color decoration_color = is_dark
        ? ShortStoryReadStyle.decoration_dark_color
        : ShortStoryReadStyle.decoration_light_color;

    return Positioned.fill(
      child: CustomPaint(
        painter: _DecorationPainter(
          decoration_color: decoration_color,
        ),
      ),
    );
  }
}

/// 装饰元素绘制器。
///
/// 负责在画布上绘制两个装饰圆形。
class _DecorationPainter extends CustomPainter {
  /// 装饰元素颜色。
  final Color decoration_color;

  _DecorationPainter({
    required this.decoration_color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = decoration_color
      ..style = PaintingStyle.fill;

    // 右上角装饰圆（距右边缘 30px，距顶部 80px）。
    canvas.drawCircle(
      Offset(size.width - 30, 80),
      50,
      paint,
    );

    // 左侧中部装饰圆（距左边缘 20px，垂直居中位置）。
    canvas.drawCircle(
      Offset(20, size.height * 0.5),
      35,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _DecorationPainter oldDelegate) {
    // 仅当颜色变化时重绘。
    return oldDelegate.decoration_color != decoration_color;
  }
}
