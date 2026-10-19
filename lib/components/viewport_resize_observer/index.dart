// ignore_for_file: non_constant_identifier_names

import 'package:flutter/widgets.dart';

/// 在真实阅读视口重新排版前记录位置，稳定布局后恢复位置。
///
/// 观察constraints而非设备方向：折叠、分屏和只改变宽度的窗口调整均可触发。
/// 首次布局不触发，连续尺寸变化合并为一次事务，避免用中间布局覆盖原锚点。
class ViewportResizeObserver extends StatefulWidget {
  const ViewportResizeObserver({
    super.key,
    required this.child,
    required this.on_resize_start,
    required this.on_resize_end,
  });

  final Widget child;

  /// 同步记录旧布局锚点；仅记录数据，不在回调中触发重建。
  final VoidCallback on_resize_start;

  /// 新视口完成布局后恢复锚点。
  final VoidCallback on_resize_end;

  @override
  State<ViewportResizeObserver> createState() => _ViewportResizeObserverState();
}

class _ViewportResizeObserverState extends State<ViewportResizeObserver> {
  Size? _last_size;
  bool _resize_pending = false;
  int _layout_revision = 0;

  void _observe_size(Size size) {
    final previous_size = _last_size;
    _last_size = size;
    if (previous_size == null || previous_size == size) return;
    if (!_resize_pending) {
      _resize_pending = true;
      widget.on_resize_start();
    }
    final revision = ++_layout_revision;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || revision != _layout_revision) return;
      _resize_pending = false;
      widget.on_resize_end();
    });
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      _observe_size(constraints.biggest);
      return widget.child;
    },
  );
}
