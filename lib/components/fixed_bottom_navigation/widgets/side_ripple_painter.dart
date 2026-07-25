// ignore_for_file: non_constant_identifier_names

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../style.dart';

/// 底部导航左右区域点击波纹 painter。
///
/// 这里使用自定义圆形扩散，目的是让整条底栏的波纹视觉更轻，
/// 同时不受单个按钮边界裁切影响。
class SideRipplePainter extends CustomPainter {
  /// 当前动画进度。
  final double progress;

  /// 当前波纹起点。
  final Offset? origin;

  /// 当前波纹颜色。
  final Color color;

  const SideRipplePainter({
    required this.progress,
    required this.origin,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (origin == null || progress <= 0) {
      return;
    }

    canvas.save();
    canvas.clipRect(Offset.zero & size);

    final double eased_progress = Curves.easeOutCubic.transform(progress);
    final double max_radius =
        lerpDouble(
          size.height * Style.ripple_height_radius_factor,
          size.width * Style.ripple_width_radius_factor,
          Style.ripple_radius_blend,
        ) ??
        (size.width * Style.ripple_width_radius_factor);
    final double radius = lerpDouble(0, max_radius, eased_progress) ?? 0;
    final double opacity =
        lerpDouble(1, 0, Curves.easeOut.transform(progress)) ?? 0;

    if (radius <= 0 || opacity <= 0) {
      canvas.restore();
      return;
    }

    final Paint paint = Paint()
      ..color = color.withValues(alpha: color.a * opacity);

    canvas.drawCircle(origin!, radius, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SideRipplePainter old_delegate) {
    return old_delegate.progress != progress ||
        old_delegate.origin != origin ||
        old_delegate.color != color;
  }
}
