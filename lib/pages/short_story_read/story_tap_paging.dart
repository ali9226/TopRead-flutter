import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:app/pages/short_story_read/style.dart';

/// TODO 管理正文上三分区的单击翻屏，不让程序位移触发导航栏显隐。
class StoryTapPagingController {
  StoryTapPagingController({required this.scroll_controller});

  /// TODO 与正文、阅读进度共用的滚动控制器。
  final ScrollController scroll_controller;

  /// TODO 当前是否由单击翻屏驱动滚动。
  bool is_scrolling = false;

  /// TODO 连续点击或用户接管后，旧动画完成回调不能修改新操作的状态。
  int _generation = 0;

  /// TODO 只让正文的真实手动滚动接管翻屏，嵌套列表与程序动画不改变状态。
  /// TODO [on_pull_at_start] 在顶部真实下拉时显示栏位，即使钳制滚动没有位移。
  bool on_scroll_notification(
    ScrollNotification notification, {
    required ValueChanged<double> on_pull_at_start,
  }) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      cancel();
    } else if (notification is OverscrollNotification &&
        notification.dragDetails != null &&
        notification.overscroll < 0 &&
        notification.metrics.pixels <= notification.metrics.minScrollExtent) {
      cancel();
      on_pull_at_start(notification.metrics.minScrollExtent);
    }
    return false;
  }

  /// TODO 判断触点是否位于正文已经顶到视口上缘时的上三分区。
  /// TODO [position] 为全局触点，[body_start_key] 是正文起点的真实布局锚点。
  bool should_page_up({
    required Offset position,
    required GlobalKey body_start_key,
  }) {
    if (!scroll_controller.hasClients) return false;
    final RenderObject? body = body_start_key.currentContext
        ?.findRenderObject();
    if (body is! RenderBox || !body.hasSize) return false;
    final RenderAbstractViewport? viewport = RenderAbstractViewport.maybeOf(
      body,
    );
    if (viewport == null || viewport is! RenderBox) {
      return false;
    }
    final RenderBox viewport_box = viewport as RenderBox;
    if (!viewport_box.hasSize) return false;

    final double body_top = viewport_box
        .globalToLocal(body.localToGlobal(Offset.zero))
        .dy;
    if (body_top > ShortStoryReadStyle.reading_section_at_top_threshold) {
      return false;
    }
    final Offset local_position = viewport_box.globalToLocal(position);
    return local_position.dx >= 0 &&
        local_position.dx <= viewport_box.size.width &&
        local_position.dy >= 0 &&
        local_position.dy <
            viewport_box.size.height * ShortStoryReadStyle.page_up_tap_fraction;
  }

  /// TODO 上翻一屏并保留衔接正文；[sync_scroll_offset] 只更新方向基准。
  /// TODO [disable_animations] 尊重系统减少动态效果设置。
  Future<void> scroll_page_up({
    required ValueChanged<double> sync_scroll_offset,
    required bool disable_animations,
  }) async {
    if (!scroll_controller.hasClients) return;
    final int generation = ++_generation;
    final ScrollPosition position = scroll_controller.position;
    final double distance = math.max(
      0,
      position.viewportDimension - ShortStoryReadStyle.page_scroll_overlap,
    );
    final double target = (position.pixels - distance).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    is_scrolling = true;
    try {
      if (disable_animations) {
        scroll_controller.jumpTo(target);
      } else {
        await scroll_controller.animateTo(
          target,
          duration: ShortStoryReadStyle.page_scroll_duration,
          curve: Curves.easeInOut,
        );
      }
    } finally {
      if (generation == _generation) {
        if (scroll_controller.hasClients) {
          sync_scroll_offset(scroll_controller.offset);
        }
        is_scrolling = false;
      }
    }
  }

  /// TODO 手动拖动或页面退出时立即交还滚动控制，旧动画不能继续屏蔽栏位。
  void cancel() {
    _generation++;
    is_scrolling = false;
  }
}
