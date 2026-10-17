// ignore_for_file: non_constant_identifier_names
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../style.dart';

/// 原生绘制星空与山谷，保持不同屏幕下清晰，参考图不会作为整页背景。
class QuestAtmosphere extends StatelessWidget {
  const QuestAtmosphere({super.key, required this.is_dark});
  final bool is_dark;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: TileQuestStyle.sky(is_dark),
        ),
      ),
      child: CustomPaint(painter: _ValleyPainter(is_dark), size: Size.infinite),
    ),
  );
}

class _ValleyPainter extends CustomPainter {
  _ValleyPainter(this.is_dark);
  final bool is_dark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final center = Offset(size.width * .58, size.height * .57);
    paint.shader = RadialGradient(
      colors: [
        const Color(0xFF88BFD1).withValues(alpha: is_dark ? .15 : .24),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: center, radius: size.width * .8));
    canvas.drawRect(Offset.zero & size, paint);
    paint.shader = null;
    // 固定种子使重建与旋转时星点位置稳定。
    final random = math.Random(37);
    for (var i = 0; i < 70; i++) {
      final point = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height * .8,
      );
      final radius = i % 9 == 0 ? 1.6 : .7;
      paint.color = TileQuestStyle.cream.withValues(
        alpha: .18 + random.nextDouble() * .5,
      );
      canvas.drawCircle(point, radius, paint);
      if (i % 13 == 0) {
        canvas.drawLine(
          point - const Offset(3.4, 0),
          point + const Offset(3.4, 0),
          paint..strokeWidth = .8,
        );
        canvas.drawLine(
          point - const Offset(0, 3.4),
          point + const Offset(0, 3.4),
          paint,
        );
      }
    }
    _mountain(
      canvas,
      size,
      const Color(0xFF4C7590).withValues(alpha: .30),
      .70,
      .12,
    );
    _mountain(
      canvas,
      size,
      const Color(0xFF224761).withValues(alpha: .75),
      .82,
      .22,
    );
    _mountain(
      canvas,
      size,
      is_dark ? const Color(0xFF112E40) : const Color(0xFF295668),
      .94,
      .08,
    );
    // 左右草叶建立前景，中央保留棋盘视觉空间。
    paint.color = const Color(0xFF609791).withValues(alpha: .22);
    for (var side = 0; side < 2; side++) {
      for (var i = 0; i < 8; i++) {
        final x = side == 0 ? i * 7.0 : size.width - i * 7;
        final y = size.height - 16 - (i % 3) * 8;
        final path = Path()
          ..moveTo(x, size.height)
          ..quadraticBezierTo(
            x + (side == 0 ? 18 : -18),
            y - 42,
            x + (side == 0 ? 30 : -30),
            y - 60,
          )
          ..quadraticBezierTo(
            x + (side == 0 ? 20 : -20),
            y + 2,
            x,
            size.height,
          );
        canvas.drawPath(path, paint);
      }
    }
  }

  void _mountain(
    Canvas canvas,
    Size size,
    Color color,
    double horizon,
    double peak,
  ) {
    final path = Path()..moveTo(0, size.height * horizon);
    path.cubicTo(
      size.width * .05,
      size.height * (horizon - peak),
      size.width * .13,
      size.height * (horizon - peak * 1.3),
      size.width * .24,
      size.height * horizon,
    );
    path.cubicTo(
      size.width * .42,
      size.height * (horizon + .08),
      size.width * .53,
      size.height * (horizon + .08),
      size.width * .67,
      size.height * horizon,
    );
    path.cubicTo(
      size.width * .79,
      size.height * (horizon - peak * 1.9),
      size.width * .86,
      size.height * (horizon - peak),
      size.width,
      size.height * (horizon - .04),
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ValleyPainter oldDelegate) =>
      oldDelegate.is_dark != is_dark;
}
