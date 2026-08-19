import 'package:flutter/material.dart';

/// 可测量高度的包装组件。
///
/// 在子组件渲染后测量实际高度，通过 [on_height_measured] 回调通知父组件。
/// 用于瀑布流布局中动态获取每个卡片的真实高度。
class MeasurableWidget extends StatefulWidget {
  final Widget child;
  final ValueChanged<double> on_height_measured;

  const MeasurableWidget({
    super.key,
    required this.child,
    required this.on_height_measured,
  });

  @override
  State<MeasurableWidget> createState() => _MeasurableWidgetState();
}

class _MeasurableWidgetState extends State<MeasurableWidget> {
  double _last_height = 0;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (_) {
        _measure();
        return false;
      },
      child: SizeChangedLayoutNotifier(child: widget.child),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measure();
    });
  }

  void _measure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final double height = box.size.height;
        if ((height - _last_height).abs() > 1) {
          _last_height = height;
          widget.on_height_measured(height);
        }
      }
    });
  }
}
