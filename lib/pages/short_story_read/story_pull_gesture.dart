import 'package:flutter/material.dart';

/// 上下拉切篇手势的宿主能力。
///
/// 由阅读页 State 实现，控制器只负责手势状态机与阻尼动画，
/// 与页面业务（切篇、自动阅读、遮罩刷新）通过本接口解耦。
abstract class StoryPullGestureHost {
  /// 是否有段落选区（选文时不让边缘拖拽接管手势）。
  bool get is_selection_active;

  /// 段评输入框是否打开。
  bool get is_composer_open;

  /// 是否允许下拉切上一篇。
  bool get can_pull_previous_story;

  /// 是否允许上拉切下一篇。
  bool get can_pull_next_story;

  /// 正文是否停在顶部。
  bool get is_reader_at_top;

  /// 正文是否停在底部。
  bool get is_reader_at_bottom;

  /// 视口高度，用于换算上拉最大视觉位移。
  double get viewport_height;

  /// 宿主是否仍然挂载。
  bool get host_mounted;

  /// 上一篇小说 ID；无则返回 null。
  int? get previous_story_id;

  /// 下一篇小说 ID；无则返回 null。
  int? get next_story_id;

  /// 手势接管时停掉自动阅读。
  void stop_auto_read();

  /// 执行切篇。
  void switch_to_story(int story_id, {required bool slide_up});

  /// 位移变化后的界面刷新回调（宿主调用 setState）。
  void on_pull_offsets_changed();

  /// 底部遮罩透明度需要重算。
  void schedule_next_story_overlay_update();

  /// 上拉露出更多正文后，同步滚动位置到新的底部。
  void sync_next_preview_scroll_position();

  /// 手势首次有效位移时标记用户已交互。
  void mark_user_engaged();
}

/// 阅读页“顶部下拉看上一篇 / 底部上拉看下一篇”的手势状态机。
///
/// 独立持有原始/视觉位移、拖拽与回弹标志以及回弹动画控制器，
/// 避免这些状态与页面其它 UI 逻辑继续堆积在同一个 State 文件里。
class StoryPullGestureController {
  StoryPullGestureController({
    required TickerProvider ticker,
    required this.host,
  }) {
    _previous_pull_animation_controller = AnimationController(
      vsync: ticker,
      duration: _rebound_duration,
    );
    _next_pull_animation_controller = AnimationController(
      vsync: ticker,
      duration: _rebound_duration,
    );
  }

  /// 页面能力宿主。
  final StoryPullGestureHost host;

  /// 回弹动画时长。
  static const Duration _rebound_duration = Duration(milliseconds: 220);

  /// 顶部下拉触发距离。
  static const double previous_pull_trigger_distance = 118.0;

  /// 顶部下拉最大视觉距离。
  static const double previous_pull_max_distance = 230.0;

  /// 底部上拉触发距离。
  static const double next_pull_trigger_distance = 138.0;

  /// 底部上拉最大视觉位移与视口高度之比。
  static const double next_pull_max_viewport_ratio = 0.82;

  /// 顶部下拉原始拖拽距离（跟手值，不直接参与布局）。
  double previous_pull_raw_offset = 0;

  /// 顶部下拉视觉位移（经阻尼，直接绑定 Transform）。
  double previous_pull_offset = 0;

  /// 顶部下拉手势是否已接管本次按压。
  bool is_previous_pull_dragging = false;

  /// 顶部下拉是否正在回弹。
  bool is_previous_pull_rebounding = false;

  /// 底部上拉原始拖拽距离。
  double next_pull_raw_offset = 0;

  /// 底部上拉视觉位移。
  double next_pull_offset = 0;

  /// 底部上拉手势是否已接管本次按压。
  bool is_next_pull_dragging = false;

  /// 底部上拉是否正在回弹。
  bool is_next_pull_rebounding = false;

  late final AnimationController _previous_pull_animation_controller;
  late final AnimationController _next_pull_animation_controller;

  /// 是否存在任何上拉/下拉位移。
  bool get has_active_pull => previous_pull_offset > 0 || next_pull_offset > 0;

  /// 释放所有手势资源。
  void dispose() {
    _previous_pull_animation_controller.dispose();
    _next_pull_animation_controller.dispose();
  }

  /// 把顶部真实下拉距离转换成视觉位移。
  double compute_previous_pull_visual_offset(double raw_offset) {
    if (raw_offset <= 0) return 0;
    if (raw_offset <= previous_pull_trigger_distance) {
      return raw_offset;
    }

    final double extra = raw_offset - previous_pull_trigger_distance;
    final double resisted_extra = extra * 0.38;
    return (previous_pull_trigger_distance + resisted_extra).clamp(
      0.0,
      previous_pull_max_distance,
    );
  }

  /// 把底部真实上拉距离转换成视觉位移。
  double compute_next_pull_visual_offset(double raw_offset) {
    if (raw_offset <= 0) return 0;
    if (raw_offset <= next_pull_trigger_distance) {
      return raw_offset;
    }

    final double viewport_height = host.viewport_height;
    final double max_visual_offset =
        (viewport_height * next_pull_max_viewport_ratio).clamp(
          next_pull_trigger_distance,
          viewport_height - 24.0,
        );

    final double extra = raw_offset - next_pull_trigger_distance;

    // 超过触发距离之后仍然保留一点阻尼，但不能阻尼过重；
    // 否则用户继续上拉时，下一篇正文看起来还是被固定裁剪在几行。
    final double resisted_extra = extra * 0.82;

    return (next_pull_trigger_distance + resisted_extra).clamp(
      0.0,
      max_visual_offset,
    );
  }

  /// 指针移动：在顶部向下拖拽切上一篇，在底部向上拖拽切下一篇。
  void on_reader_pointer_move(double dy) {
    if (host.is_selection_active || host.is_composer_open) return;
    if (dy != 0) {
      host.mark_user_engaged();
    }

    if (is_previous_pull_dragging || previous_pull_offset > 0) {
      _handle_previous_pull_move(dy);
      return;
    }

    if (is_next_pull_dragging || next_pull_offset > 0) {
      _handle_next_pull_move(dy);
      return;
    }

    if (host.can_pull_previous_story && host.is_reader_at_top && dy > 0) {
      _handle_previous_pull_move(dy);
      return;
    }

    if (host.can_pull_next_story && host.is_reader_at_bottom && dy < 0) {
      _handle_next_pull_move(dy);
    }
  }

  /// 顶部下拉上一篇的拖拽处理。
  void _handle_previous_pull_move(double dy) {
    if (!host.can_pull_previous_story && previous_pull_offset <= 0) return;

    host.stop_auto_read();
    _previous_pull_animation_controller.stop();
    is_previous_pull_rebounding = false;

    final double next_raw = (previous_pull_raw_offset + dy).clamp(
      0.0,
      previous_pull_max_distance * 2.2,
    );
    final double next_visual = compute_previous_pull_visual_offset(next_raw);

    // 一旦进入顶部下拉手势，在本次按压释放前都保持手势态。
    // 否则用户拉出提示后又推回 0，再继续下拉时容易被普通滚动接管。
    is_previous_pull_dragging = true;
    previous_pull_raw_offset = next_raw;
    previous_pull_offset = next_visual;
    host.on_pull_offsets_changed();
  }

  /// 底部上拉下一篇的拖拽处理。
  void _handle_next_pull_move(double dy) {
    if (!host.can_pull_next_story && next_pull_offset <= 0) return;

    host.stop_auto_read();
    _next_pull_animation_controller.stop();
    is_next_pull_rebounding = false;

    // dy < 0 表示手指向上拖动，所以用 -dy 转为正数距离。
    final double viewport_height = host.viewport_height;
    final double next_raw = (next_pull_raw_offset - dy).clamp(
      0.0,
      viewport_height * 1.35,
    );
    final double next_visual = compute_next_pull_visual_offset(next_raw);

    // 一旦进入底部上拉手势，在本次按压释放前都保持手势态。
    // 这样用户上拉看到提示后推回去，再继续上拉，仍然可以重新出现提示并触发下一篇。
    is_next_pull_dragging = true;
    next_pull_raw_offset = next_raw;
    next_pull_offset = next_visual;
    host.on_pull_offsets_changed();
    host.schedule_next_story_overlay_update();
    host.sync_next_preview_scroll_position();
  }

  /// 指针释放/取消：距离足够切换，否则回弹。
  void on_reader_pointer_end() {
    if (is_previous_pull_dragging || previous_pull_offset > 0) {
      is_previous_pull_dragging = false;
      finish_previous_pull_gesture();
      return;
    }

    if (is_next_pull_dragging || next_pull_offset > 0) {
      is_next_pull_dragging = false;
      finish_next_pull_gesture();
    }
  }

  /// 顶部下拉手势结束：距离足够则切换上一篇，不够则回弹。
  void finish_previous_pull_gesture() {
    if (previous_pull_offset >= previous_pull_trigger_distance) {
      final int? previous_id = host.previous_story_id;
      if (previous_id == null) {
        animate_previous_pull_back();
        return;
      }
      host.switch_to_story(previous_id, slide_up: false);
      return;
    }

    animate_previous_pull_back();
  }

  /// 底部上拉手势结束：距离足够则切换下一篇，不够则回弹。
  void finish_next_pull_gesture() {
    if (next_pull_offset >= next_pull_trigger_distance) {
      final int? next_id = host.next_story_id;
      if (next_id == null) {
        animate_next_pull_back();
        return;
      }
      host.switch_to_story(next_id, slide_up: true);
      return;
    }

    animate_next_pull_back();
  }

  /// 轻微下拉时回弹到当前小说顶部。
  void animate_previous_pull_back() {
    if (previous_pull_offset <= 0 || is_previous_pull_rebounding) return;

    _previous_pull_animation_controller.stop();
    _previous_pull_animation_controller.reset();
    is_previous_pull_rebounding = true;

    final double begin_visual = previous_pull_offset;
    final Animation<double> animation =
        Tween<double>(begin: begin_visual, end: 0).animate(
          CurvedAnimation(
            parent: _previous_pull_animation_controller,
            curve: Curves.easeOutCubic,
          ),
        );

    void listener() {
      if (!host.host_mounted) return;
      previous_pull_offset = animation.value;
      previous_pull_raw_offset = animation.value;
      host.on_pull_offsets_changed();
    }

    void status_listener(AnimationStatus status) {
      if (status != AnimationStatus.completed &&
          status != AnimationStatus.dismissed) {
        return;
      }
      animation.removeListener(listener);
      _previous_pull_animation_controller.removeStatusListener(status_listener);
      if (!host.host_mounted) return;
      previous_pull_raw_offset = 0;
      previous_pull_offset = 0;
      is_previous_pull_dragging = false;
      is_previous_pull_rebounding = false;
      host.on_pull_offsets_changed();
    }

    animation.addListener(listener);
    _previous_pull_animation_controller.addStatusListener(status_listener);
    _previous_pull_animation_controller.forward();
  }

  /// 轻微上拉时回弹到当前小说底部。
  void animate_next_pull_back() {
    if (next_pull_offset <= 0 || is_next_pull_rebounding) return;

    _next_pull_animation_controller.stop();
    _next_pull_animation_controller.reset();
    is_next_pull_rebounding = true;

    final double begin_visual = next_pull_offset;
    final Animation<double> animation =
        Tween<double>(begin: begin_visual, end: 0).animate(
          CurvedAnimation(
            parent: _next_pull_animation_controller,
            curve: Curves.easeOutCubic,
          ),
        );

    void listener() {
      if (!host.host_mounted) return;
      next_pull_offset = animation.value;
      next_pull_raw_offset = animation.value;
      host.on_pull_offsets_changed();
      host.schedule_next_story_overlay_update();
    }

    void status_listener(AnimationStatus status) {
      if (status != AnimationStatus.completed &&
          status != AnimationStatus.dismissed) {
        return;
      }
      animation.removeListener(listener);
      _next_pull_animation_controller.removeStatusListener(status_listener);
      if (!host.host_mounted) return;
      next_pull_raw_offset = 0;
      next_pull_offset = 0;
      is_next_pull_dragging = false;
      is_next_pull_rebounding = false;
      host.on_pull_offsets_changed();
      host.schedule_next_story_overlay_update();
    }

    animation.addListener(listener);
    _next_pull_animation_controller.addStatusListener(status_listener);
    _next_pull_animation_controller.forward();
  }
}
