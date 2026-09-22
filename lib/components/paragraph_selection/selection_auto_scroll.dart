// ignore_for_file: non_constant_identifier_names, avoid_renaming_method_parameters

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'style.dart';

/// 正文选区位于阅读滚动容器内部时，为原生选择事件补上边缘自动滚动。
///
/// 手柄、字形定位和选区更新仍由 Flutter 处理；返回 pending 使框架在
/// 滚动期间继续发送当前边界事件，不需要额外的文字渲染或全局指针监听。
class ParagraphSelectionAutoScroll extends StatefulWidget {
  const ParagraphSelectionAutoScroll({super.key, required this.child});

  final Widget child;

  @override
  State<ParagraphSelectionAutoScroll> createState() =>
      _ParagraphSelectionAutoScrollState();
}

class _ParagraphSelectionAutoScrollState
    extends State<ParagraphSelectionAutoScroll> {
  final _delegate = _ParagraphAutoScrollDelegate();
  ValueListenable<SelectableRegionSelectionStatus>? _selection_status;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _delegate.update_scrollable(Scrollable.maybeOf(context));
    final status = SelectableRegionSelectionStatusScope.maybeOf(context);
    if (identical(status, _selection_status)) return;
    _selection_status?.removeListener(_selection_status_changed);
    _selection_status = status;
    status?.addListener(_selection_status_changed);
  }

  /// 松手即终止滚动，不等待下一次指针移动或选择取消。
  void _selection_status_changed() {
    if (_selection_status?.value == SelectableRegionSelectionStatus.finalized) {
      _delegate.stop_auto_scroll();
    }
  }

  @override
  void dispose() {
    _selection_status?.removeListener(_selection_status_changed);
    _delegate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      SelectionContainer(delegate: _delegate, child: widget.child);
}

/// 复用原生多段选区分发，并将尚未收到边界事件的新段落定位到正文坐标。
class _ParagraphAutoScrollDelegate extends StaticSelectionContainerDelegate {
  ScrollableState? _scrollable;
  ScrollPosition? _position;
  EdgeDraggingAutoScroller? _auto_scroller;
  Offset? _start_local;
  Offset? _end_local;
  bool _layout_scheduled = false;
  bool _updating_children = false;
  bool _disposed = false;

  /// 滚动容器或 ScrollPosition 被替换时，解除旧监听和正在进行的滚动。
  void update_scrollable(ScrollableState? scrollable) {
    final position = scrollable?.position;
    if (identical(scrollable, _scrollable) &&
        identical(position, _position)) {
      return;
    }
    stop_auto_scroll();
    _position?.removeListener(_schedule_layout_update);
    _scrollable = scrollable;
    _position = position;
    _auto_scroller = scrollable == null
        ? null
        : EdgeDraggingAutoScroller(
            scrollable,
            velocityScalar: ParagraphSelectionStyle.auto_scroll_velocity,
          );
    position?.addListener(_schedule_layout_update);
  }

  void stop_auto_scroll() => _auto_scroller?.stopAutoScroll();

  /// 容器随滚动移动后刷新手柄位置；只保留一份帧后任务。
  void _schedule_layout_update() {
    if (_layout_scheduled || _disposed) return;
    _layout_scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed) return;
      _layout_scheduled = false;
      _sync_edge_positions();
      layoutDidChange();
    });
  }

  /// 保存正文局部坐标，跨屏后补发另一端的事件不会使用过期屏幕坐标。
  @override
  void updateLastSelectionEdgeLocation({
    required Offset globalSelectionEdgeLocation,
    required bool forEnd,
  }) {
    final inverse = Matrix4.inverted(getTransformTo(null));
    final local = MatrixUtils.transformPoint(
      inverse,
      globalSelectionEdgeLocation,
    );
    if (forEnd) {
      _end_local = local;
    } else {
      _start_local = local;
    }
    super.updateLastSelectionEdgeLocation(
      globalSelectionEdgeLocation: globalSelectionEdgeLocation,
      forEnd: forEnd,
    );
  }

  /// 只更新框架的事件缓存，不改变当前段落已经保存的 UTF-16 选区。
  void _sync_edge_positions() {
    if (_start_local == null && _end_local == null) return;
    final transform = getTransformTo(null);
    if (_start_local != null) {
      super.updateLastSelectionEdgeLocation(
        globalSelectionEdgeLocation: MatrixUtils.transformPoint(
          transform,
          _start_local!,
        ),
        forEnd: false,
      );
    }
    if (_end_local != null) {
      super.updateLastSelectionEdgeLocation(
        globalSelectionEdgeLocation: MatrixUtils.transformPoint(
          transform,
          _end_local!,
        ),
        forEnd: true,
      );
    }
  }

  @override
  void ensureChildUpdated(Selectable selectable) {
    _sync_edge_positions();
    super.ensureChildUpdated(selectable);
  }

  /// 评论计数等重建产生的补发事件只恢复选择，不应启动新的自动滚动。
  @override
  void didChangeSelectables() {
    _updating_children = true;
    try {
      _sync_edge_positions();
      super.didChangeSelectables();
    } finally {
      _updating_children = false;
    }
  }

  @override
  SelectionResult handleSelectionEdgeUpdate(SelectionEdgeUpdateEvent event) {
    _sync_edge_positions();
    final result = super.handleSelectionEdgeUpdate(event);
    if (_updating_children) return result;
    final scrollable = _scrollable;
    final scroller = _auto_scroller;
    if (scrollable == null || scroller == null || !scrollable.mounted) {
      return result;
    }
    if (result == SelectionResult.pending ||
        axisDirectionToAxis(scrollable.axisDirection) != Axis.vertical) {
      stop_auto_scroll();
      return result;
    }
    final viewport = scrollable.context.findRenderObject();
    if (viewport is! RenderBox || !viewport.hasSize) return result;
    final viewport_bounds = MatrixUtils.transformRect(
      viewport.getTransformTo(null),
      Offset.zero & viewport.size,
    );
    final content_bounds = MatrixUtils.transformRect(
      getTransformTo(null),
      Offset.zero & containerSize,
    );
    final target = Rect.fromCircle(
      center: event.globalPosition,
      radius: ParagraphSelectionStyle.auto_scroll_edge_extent,
    );
    // 每章拥有独立坐标；到达本章边缘后不继续滚入无法选择的下一章。
    final can_scroll_up =
        target.top < viewport_bounds.top &&
        content_bounds.top < viewport_bounds.top;
    final can_scroll_down =
        target.bottom > viewport_bounds.bottom &&
        content_bounds.bottom > viewport_bounds.bottom;
    if (!can_scroll_up && !can_scroll_down) {
      stop_auto_scroll();
      return result;
    }
    scroller.startAutoScrollIfNecessary(target);
    return scroller.scrolling ? SelectionResult.pending : result;
  }

  @override
  SelectionResult handleClearSelection(ClearSelectionEvent event) {
    stop_auto_scroll();
    _start_local = null;
    _end_local = null;
    return super.handleClearSelection(event);
  }

  @override
  void dispose() {
    _disposed = true;
    stop_auto_scroll();
    _position?.removeListener(_schedule_layout_update);
    super.dispose();
  }
}
