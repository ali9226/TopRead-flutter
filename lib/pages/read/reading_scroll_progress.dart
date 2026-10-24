import 'dart:async';

import 'package:app/components/inline_native_ad/scroll_offset_compensation.dart';
import 'package:app/pages/read/logic.dart';
import 'package:app/pages/read/reading_chapter_anchor.dart';
import 'package:app/pages/read/utils/scroll_utils.dart';
import 'package:app/pages/read/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;

/// 长篇滚动进度与章节预取的宿主能力。
abstract class ScrollProgressHost {
  /// 宿主是否仍然挂载。
  bool get host_mounted;

  /// 布局与 MediaQuery 取用上下文。
  BuildContext get host_context;

  /// 页面逻辑层。
  Logic get logic;

  /// 主滚动控制器。
  ScrollController get scroll_controller;

  /// 正文区块定位 key。
  GlobalKey get reading_section_key;

  /// 是否需要恢复滚动位置（恢复期间跳过进度回写）。
  bool get needs_restore_scroll_position;

  /// 章节布局事务是否进行中。
  bool get is_chapter_transaction_active;

  /// 是否正在恢复服务器进度。
  bool get is_restoring_progress;

  /// 是否处于程序化滚动。
  bool get is_programmatic_scroll;

  /// 标记用户已交互。
  set has_user_engaged(bool value);

  /// 缓存的章内进度。
  double get cached_chapter_progress;

  /// 写入章内进度缓存。
  set cached_chapter_progress(double value);

  /// 标记进度已稳定。
  set has_stable_progress(bool value);

  /// 更新全书阅读进度（只通知小组件）。
  void set_reading_progress(double progress_percent);

  /// 更新“已开始阅读”标记。
  void set_has_started_reading(bool value);

  /// 记录最近一次视口尺寸。
  set last_viewport_dimension(double value);

  /// 记录正文区是否在顶部。
  set is_reading_section_at_top(bool value);

  /// 章节锚点协调器（进度与阈值测量）。
  ReadingChapterAnchor get anchor;

  /// 停止自动阅读。
  void stop_auto_read();

  /// 展示此前延迟的解锁弹窗（滚动停止后）。
  void try_show_deferred_unlock_popup();
}

/// 长篇阅读页滚动进度识别与章节窗口预取器。
///
/// 每次滚动结束（以及章节加载后主动调用）时：
/// 识别当前章节 → 测量章内进度 → 决定是否预取上一章/下一章。
class ReadingScrollProgress {
  ReadingScrollProgress({required this.host});

  /// 页面能力宿主。
  final ScrollProgressHost host;

  /// 处理主滚动通知：滚动活动边界、自动阅读打断与停止后的拼接检查。
  bool handle_main_scroll_notification(ScrollNotification notification) {
    final ReadingChapterAnchor anchor = host.anchor;
    if (notification.depth != 0) {
      return false;
    }

    if (notification is ScrollStartNotification) {
      anchor.notify_scroll_activity_started();
    }

    if (notification is UserScrollNotification &&
        notification.direction != ScrollDirection.idle) {
      host.has_user_engaged = true;
      if (host.logic.is_auto_reading.value) {
        host.stop_auto_read();
      }
    }

    if (notification is ScrollEndNotification ||
        (notification is UserScrollNotification &&
            notification.direction == ScrollDirection.idle)) {
      anchor.notify_scroll_activity_ended();

      // 滚动完全结束后再检查是否需要拼接上一章/下一章，
      // 避免在手指拖动或惯性滚动中改列表高度。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (host.host_mounted) {
          handle_scroll();
        }
      });

      // 滚动停止后尝试展示延迟的解锁免广告弹窗。
      host.try_show_deferred_unlock_popup();
    }

    return false;
  }

  /// 识别当前章节、回写进度并按距离预取相邻章节。
  void handle_scroll() {
    final Logic logic = host.logic;
    final ScrollController controller = host.scroll_controller;
    final ReadingChapterAnchor anchor = host.anchor;
    if (!controller.hasClients || !host.host_mounted) {
      return;
    }

    if (host.needs_restore_scroll_position ||
        host.is_chapter_transaction_active ||
        host.is_restoring_progress ||
        logic.is_jumping_chapter.value) {
      return;
    }

    final double next_scroll_offset = controller.offset;

    // 广告高度补偿只更新方向基准，下一次手动滚动不能累计补偿位移。
    if (is_native_ad_scroll_compensating(controller.position)) {
      logic.sync_scroll_offset(next_scroll_offset);
    } else if (!host.is_programmatic_scroll && !logic.is_auto_reading.value) {
      // 滚动方向检测：自动显示/隐藏导航栏（程序化滚动时不触发）。
      logic.on_scroll(next_scroll_offset);
    }

    final double viewport_dimension = controller.position.viewportDimension;
    final double max_scroll_extent = controller.position.maxScrollExtent;

    // 计算 reading_section_offset，即正文区块距离顶部的绝对偏移量。
    double reading_section_offset = 0;
    final BuildContext? reading_context = host.reading_section_key
        .currentContext;
    if (reading_context != null) {
      final RenderObject? render_object = reading_context.findRenderObject();
      if (render_object is RenderBox && render_object.hasSize) {
        final double reading_section_top = render_object
            .localToGlobal(Offset.zero)
            .dy;
        final double screen_top_inset = MediaQuery.viewPaddingOf(
          host.host_context,
        ).top;
        reading_section_offset =
            next_scroll_offset + reading_section_top - screen_top_inset;
      }
    }

    // 先识别当前章节，再计算章内进度，避免章节边界处用上一章索引算新位置。
    final double chapter_detection_line =
        MediaQuery.viewPaddingOf(host.host_context).top +
        Style.current_chapter_detection_top_offset;
    for (
      int i = logic.loaded_chapter_index;
      i >= logic.min_loaded_chapter_index;
      i--
    ) {
      final BuildContext? chapter_context = logic
          .get_chapter_key(i)
          .currentContext;
      final RenderObject? render_object = chapter_context?.findRenderObject();
      if (render_object is! RenderBox || !render_object.hasSize) continue;

      final double top = render_object.localToGlobal(Offset.zero).dy;
      if (top <= chapter_detection_line) {
        logic.current_chapter_index.value = i;
        if (i >= 0 && i < logic.chapter_list.length) {
          logic.current_chapter_db_id =
              int.tryParse(logic.chapter_list[i].id) ?? 0;
        }
        break;
      }
    }

    final bool is_near_top =
        next_scroll_offset < Style.reading_start_near_top_threshold;
    // 刚回到封面时章节坐标可能仍属于上一帧；用简介是否存在判断顶部区域，
    // 避免旧章节索引把封面误判为正文并覆盖真正的续读目标。
    final bool next_has_started_reading =
        (is_near_top && logic.should_show_introduction)
        ? false
        : anchor.is_first_chapter_title_past_start_threshold();

    final double? layout_progress = anchor
        .calculate_current_chapter_progress_from_layout(
          logic.current_chapter_index.value,
        );
    if (layout_progress != null) {
      host.cached_chapter_progress = layout_progress;
      logic.update_chapter_progress(host.cached_chapter_progress);
      host.has_stable_progress = true;
    }

    // 使用基于章节的逻辑计算全书进度。
    final double next_reading_progress_percent = logic
        .calculate_reading_progress(
          next_scroll_offset,
          max_scroll_extent,
          reading_section_offset: reading_section_offset,
        );
    final bool next_is_reading_section_at_top =
        ScrollUtils.is_reading_section_at_top(
          reading_section_key: host.reading_section_key,
          context: host.host_context,
        );

    // 提前预取/准备上一章。
    //
    // load_prev_chapter 内部会先请求正文并写入缓存；如果当前仍在拖动/惯性滚动，
    // 它会等待 idle 后再 prepend 到 reading_items 并修正 offset。
    // 这样既能提前 2 屏以上拿到内容，又不会在滚动过程中改列表高度导致卡顿。
    final double prev_prefetch_distance =
        (viewport_dimension * Style.chapter_prefetch_viewport_multiplier).clamp(
          Style.load_prev_chapter_threshold,
          double.infinity,
        );
    final bool can_prepare_prev =
        !logic.is_switching_chapter.value &&
        next_is_reading_section_at_top &&
        next_scroll_offset < reading_section_offset + prev_prefetch_distance &&
        logic.min_loaded_chapter_index > 0 &&
        !logic.is_loading_prev;

    if (can_prepare_prev) {
      unawaited(logic.load_prev_chapter());
    }

    // 提前预取/准备下一章：网络/磁盘读取提前发生，
    // 真正 append 到正文列表由 Logic 等到滚动 idle 后执行。
    final double next_prefetch_distance =
        (viewport_dimension * Style.chapter_prefetch_viewport_multiplier).clamp(
          Style.load_next_chapter_threshold,
          double.infinity,
        );
    if (max_scroll_extent - next_scroll_offset < next_prefetch_distance &&
        !logic.is_loading_next) {
      unawaited(logic.load_next_chapter());
    }

    if (next_has_started_reading && !host.anchor.is_scroll_activity_active) {
      unawaited(
        logic.ensure_next_chapter_appended_after(
          logic.current_chapter_index.value,
        ),
      );
    }

    host.set_has_started_reading(next_has_started_reading);
    host.set_reading_progress(next_reading_progress_percent);
    host.last_viewport_dimension = viewport_dimension;
    host.is_reading_section_at_top = next_is_reading_section_at_top;
  }
}
