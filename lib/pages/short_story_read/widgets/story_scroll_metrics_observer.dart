import 'package:flutter/material.dart';

import '../utils/calculate_current_story_scroll_extent.dart';

/// 监听正文和视口尺寸变化，在新布局完成后刷新当前篇的进度范围。
///
/// 尺寸通知与用户滚动分开处理，旋转屏幕、解锁或广告重排不会停止自动阅读。
class StoryScrollMetricsObserver extends StatefulWidget {
  const StoryScrollMetricsObserver({
    super.key,
    required this.scroll_controller,
    required this.story_end_key,
    required this.on_extent_changed,
    required this.child,
    this.on_layout_pending,
  });

  /// 正文滚动控制器，用于取得真实视口和滚动边界。
  final ScrollController scroll_controller;

  /// 当前篇正文结束标记，排除其后的下一篇预览。
  final GlobalKey story_end_key;

  /// 尺寸已经改变时立即失效旧缓存，不读取尚未稳定的布局。
  final VoidCallback? on_layout_pending;

  /// 新布局稳定后返回当前篇的真实滚动范围。
  final ValueChanged<double> on_extent_changed;

  /// 包含正文滚动视口的组件。
  final Widget child;

  @override
  State<StoryScrollMetricsObserver> createState() =>
      _StoryScrollMetricsObserverState();
}

class _StoryScrollMetricsObserverState
    extends State<StoryScrollMetricsObserver> {
  /// 合并同一帧的视口与正文尺寸通知，使用最终布局计算一次范围。
  bool _is_update_scheduled = false;

  bool _on_scroll_metrics_changed(ScrollMetricsNotification notification) {
    // 内嵌控件自己的滚动范围不属于正文，不能影响当前篇阅读进度。
    if (notification.depth != 0) return false;
    widget.on_layout_pending?.call();
    if (_is_update_scheduled) return false;

    _is_update_scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _is_update_scheduled = false;
      if (!mounted ||
          !widget.scroll_controller.hasClients ||
          !widget.scroll_controller.position.hasContentDimensions) {
        return;
      }
      widget.on_extent_changed(
        calculate_current_story_scroll_extent(
          scroll_controller: widget.scroll_controller,
          story_end_key: widget.story_end_key,
        ),
      );
    });
    // 尺寸通知可能在帧末到达；主动安排一帧，静止阅读时也能更新进度。
    WidgetsBinding.instance.ensureVisualUpdate();
    return false;
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollMetricsNotification>(
        onNotification: _on_scroll_metrics_changed,
        child: widget.child,
      );
}
