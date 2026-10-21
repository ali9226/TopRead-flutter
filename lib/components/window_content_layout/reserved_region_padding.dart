// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'index.dart' show WindowLayoutData;

/// TODO 默认保留短导航条行为；标题模式允许超过局部遮挡高度的多行标题参与避让。
enum WindowReservedRegionPaddingMode { toolbar, heading }

/// 只对真正与系统顶角区域相交的前景控件加横向避让。
/// 自身背景留在本组件外，因此系统区域后方仍绘制原来的页面背景。
class WindowReservedRegionPadding extends StatefulWidget {
  const WindowReservedRegionPadding({
    super.key,
    required this.child,
    this.enabled = true,
    this.mode = WindowReservedRegionPaddingMode.toolbar,
  });
  final Widget child;
  final bool enabled;

  /// TODO 仅标题显式使用heading；不改变正文、底栏和既有导航条的默认测量策略。
  final WindowReservedRegionPaddingMode mode;

  @override
  State<WindowReservedRegionPadding> createState() =>
      _WindowReservedRegionPaddingState();
}

class _WindowReservedRegionPaddingState
    extends State<WindowReservedRegionPadding> {
  EdgeInsets _insets = EdgeInsets.zero;

  void _measure(Rect bounds) {
    if (!mounted) return;
    final scope = context
        .dependOnInheritedWidgetOfExactType<WindowLayoutData>();
    var left = 0.0;
    var right = 0.0;
    if (widget.enabled && scope?.has_local_edge == true) {
      for (final region in scope!.regions) {
        final obstruction = region.bounds;
        if (!bounds.overlaps(obstruction) ||
            (widget.mode == WindowReservedRegionPaddingMode.toolbar &&
                bounds.height > obstruction.height)) {
          continue;
        }
        if (obstruction.left <= bounds.left) {
          left = math.max(left, obstruction.right - bounds.left);
        } else if (obstruction.right >= bounds.right) {
          right = math.max(right, bounds.right - obstruction.left);
        }
      }
    }
    final next = EdgeInsets.only(
      left: left.clamp(0, bounds.width),
      right: right.clamp(0, bounds.width),
    );
    if (_insets != next) setState(() => _insets = next);
  }

  @override
  Widget build(BuildContext context) {
    // 建立姿态依赖，区域变动但外层尺寸相同时也会重新测量。
    context.dependOnInheritedWidgetOfExactType<WindowLayoutData>();
    return _RegionBoundsObserver(
      on_bounds: _measure,
      child: Padding(padding: _insets, child: widget.child),
    );
  }
}

class _RegionBoundsObserver extends SingleChildRenderObjectWidget {
  const _RegionBoundsObserver({required this.on_bounds, required super.child});
  final ValueChanged<Rect> on_bounds;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RegionBoundsRenderObject(on_bounds);
  @override
  void updateRenderObject(
    BuildContext context,
    _RegionBoundsRenderObject renderObject,
  ) {
    renderObject.on_bounds = on_bounds;
    renderObject.markNeedsLayout();
  }
}

class _RegionBoundsRenderObject extends RenderProxyBox {
  _RegionBoundsRenderObject(this.on_bounds);
  ValueChanged<Rect> on_bounds;
  bool _scheduled = false;

  @override
  void performLayout() {
    super.performLayout();
    _schedule_measurement();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // 滚动/定位变化可能只更新父级 paint offset，不会重新 layout 本组件。
    // 仍读取这一帧最终的窗口位置，不能把导航栏离开遮挡区后继续留白。
    _schedule_measurement();
    super.paint(context, offset);
  }

  void _schedule_measurement() {
    if (_scheduled) return;
    _scheduled = true;
    // 必须等祖先 Flex/Sliver 更新本帧 offset，再读取窗口位置；否则折叠时
    // 会拿旧帧坐标误判底栏，让右侧重新出现不必要的空列。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!attached || !hasSize) return;
      final top_left = localToGlobal(Offset.zero);
      on_bounds(top_left & size);
    });
  }
}
