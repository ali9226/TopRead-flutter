// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:app/pages/comics/detail/style.dart';

/// TODO 纸面线稿与金叶使用矢量绘制，在不同像素密度下保持清晰且不拦截触摸。
class ComicWarmPaper extends StatelessWidget {
  const ComicWarmPaper({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(ComicDetailStyle.author_card_radius),
    child: CustomPaint(
      painter: _PaperPainter(dark: ComicDetailStyle.is_dark(context)),
      child: child,
    ),
  );
}

class _PaperPainter extends CustomPainter {
  const _PaperPainter({required this.dark});
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF252630), Color(0xFF20212A)]
              : const [Color(0xFFFEFDFC), Color(0xFFF7F4EF)],
        ).createShader(bounds),
    );
    canvas.save();
    canvas.clipRect(bounds);
    final pencil = Paint()
      ..color = (dark ? Colors.white : const Color(0xFF9C8A76)).withValues(
        alpha: 0.055,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.65;
    for (var i = 0; i < 10; i++) {
      final x = size.width * 0.5 + i * 16;
      canvas.drawPath(
        Path()
          ..moveTo(x, size.height)
          ..lineTo(x + 60, size.height * 0.2)
          ..lineTo(x + 100, size.height * 0.1)
          ..lineTo(x + 20, size.height),
        pencil,
      );
    }
    _leaf(canvas, Offset(size.width * 0.62, 9), 18, -0.5);
    _leaf(canvas, Offset(size.width * 0.56, size.height - 6), 23, 0.35);
    _leaf(canvas, Offset(size.width - 7, size.height - 12), 33, -0.65);
    canvas.restore();
  }

  void _leaf(Canvas canvas, Offset origin, double length, double angle) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(angle - math.pi / 4);
    final leaf = Path()
      ..moveTo(-length / 2, 0)
      ..quadraticBezierTo(-length / 4, -length * 0.52, length / 2, 0)
      ..quadraticBezierTo(length / 6, length * 0.4, -length / 2, 0);
    canvas.drawPath(
      leaf,
      Paint()
        ..shader =
            LinearGradient(
              colors: [
                const Color(0xFFFFCF25).withValues(alpha: dark ? 0.15 : 0.35),
                const Color(0xFFFFECA0).withValues(alpha: dark ? 0.05 : 0.16),
              ],
            ).createShader(
              Rect.fromCenter(
                center: Offset.zero,
                width: length,
                height: length,
              ),
            ),
    );
    canvas.drawLine(
      Offset(-length / 2, 0),
      Offset(length / 2, 0),
      Paint()
        ..color = const Color(0xFFFFD555).withValues(alpha: 0.2)
        ..strokeWidth = 0.5,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PaperPainter oldDelegate) =>
      dark != oldDelegate.dark;
}

/// TODO 内容圆角外侧延续海报底色，避免浅色直角破坏海报与纸面的衔接。
class ComicContentSurface extends StatelessWidget {
  const ComicContentSurface({
    super.key,
    required this.child,
    required this.is_dark,
  });
  final Widget child;
  final bool is_dark;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      const Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: ComicDetailStyle.content_card_radius,
        child: ColoredBox(color: Color(0xFF29292C)),
      ),
      Container(
        decoration: BoxDecoration(
          color: ComicDetailStyle.page_background(is_dark),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(ComicDetailStyle.content_card_radius),
          ),
        ),
        child: child,
      ),
    ],
  );
}
