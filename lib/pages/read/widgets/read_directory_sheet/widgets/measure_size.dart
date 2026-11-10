import 'package:flutter/material.dart';

/// TODO 记录多行章节卡片的真实高度，定位不依赖固定行高或字体缩放猜测。
class DirectoryMeasureSize extends StatefulWidget {
  const DirectoryMeasureSize({
    super.key,
    required this.child,
    required this.on_change,
  });
  final Widget child;
  final ValueChanged<Size> on_change;
  @override
  State<DirectoryMeasureSize> createState() => _DirectoryMeasureSizeState();
}

class _DirectoryMeasureSizeState extends State<DirectoryMeasureSize> {
  Size? _old_size;
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final render = context.findRenderObject();
      if (render is! RenderBox || !render.hasSize || _old_size == render.size) {
        return;
      }
      _old_size = render.size;
      widget.on_change(render.size);
    });
    return widget.child;
  }
}
