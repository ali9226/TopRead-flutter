import 'package:flutter/material.dart';

/// 平滑移动短篇目录到估算位置。
Future<void> animate_catalog_position({
  required ScrollController controller,
  required double target_offset,
  required Duration duration,
  required Curve curve,
}) async {
  if (!controller.hasClients) return;

  final ScrollPosition position = controller.position;
  final double resolved_offset = target_offset.clamp(
    position.minScrollExtent,
    position.maxScrollExtent,
  );
  if ((resolved_offset - position.pixels).abs() < 0.5) return;

  await controller.animateTo(resolved_offset, duration: duration, curve: curve);
}
