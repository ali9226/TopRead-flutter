import 'dart:async';

import 'package:app/pages/read/logic.dart';
import 'package:app/pages/read/style.dart';
import 'package:flutter/material.dart';

/// 长篇章节锚点与滚动恢复的宿主能力。
abstract class ChapterAnchorHost {
  /// 宿主是否仍然挂载。
  bool get host_mounted;

  /// 屏幕信息取用上下文。
  BuildContext get host_context;

  /// 页面逻辑层。
  Logic get logic;

  /// 主滚动控制器。
  ScrollController get scroll_controller;

  /// 是否需要恢复滚动位置。
  bool get needs_restore_scroll_position;

  /// 写入恢复标记。
  set needs_restore_scroll_position(bool value);

  /// 待恢复的目标章节索引。
  int get pending_restore_chapter_index;

  /// 待恢复的章节内百分比。
  double get pending_restore_chapter_progress;

  /// 章节布局事务是否进行中。
  bool get is_chapter_transaction_active;

  /// 更新章节布局事务标记。
  set is_chapter_transaction_active(bool value);

  /// 是否处于程序化滚动（跳过导航栏显隐）。
  set is_programmatic_scroll(bool value);

  /// 滚动/跳转完成后回调（页面负责刷新进度与预取）。
  void on_scroll_settled();
}

/// 长篇阅读页章节锚点、进度测量与位置恢复协调器。
///
/// 统一以章节标题的真实渲染位置为坐标系：恢复、进度、插入上一章时的
/// 位置补偿都在这里换算，避免各处用 maxScrollExtent 互相猜。
class ReadingChapterAnchor {
  ReadingChapterAnchor({required this.host});

  /// 页面能力宿主。
  final ChapterAnchorHost host;

  /// 章节布局事务代数；新事务使旧的恢复流程失效。
  int _transaction_generation = 0;

  /// 滚动完全停止时的完成器（供等待 idle 的流程挂起）。
  Completer<void>? _scroll_idle_completer;

  /// 是否有滚动活动（拖动或惯性）。
  bool is_scroll_activity_active = false;

  /// 通知：滚动活动开始。
  void notify_scroll_activity_started() {
    is_scroll_activity_active = true;
  }

  /// 通知：滚动完全停止，唤醒 idle 等待者。
  void notify_scroll_activity_ended() {
    is_scroll_activity_active = false;
    final Completer<void>? completer = _scroll_idle_completer;
    _scroll_idle_completer = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  /// 等待主列表完全停止拖动或惯性滚动。
  Future<void> wait_until_scroll_idle() {
    if (!is_scroll_activity_active) {
      return Future<void>.value();
    }
    final Completer<void> completer = _scroll_idle_completer ??=
        Completer<void>();
    return completer.future;
  }

  /// 恢复到上次阅读的章节内百分比位置。
  Future<void> restore_scroll_position_after_layout() async {
    if (!host.host_mounted ||
        !host.needs_restore_scroll_position ||
        host.is_chapter_transaction_active) {
      return;
    }

    final int transaction = begin_transaction();
    host.is_chapter_transaction_active = true;
    try {
      await wait_until_reading_layout_ready(host.pending_restore_chapter_index);
      if (!host.host_mounted ||
          !host.needs_restore_scroll_position ||
          !is_transaction_current(transaction)) {
        return;
      }

      await scroll_to_chapter_progress(
        host.pending_restore_chapter_index,
        chapter_progress_percent: host.pending_restore_chapter_progress,
      );
      if (is_transaction_current(transaction)) {
        host.needs_restore_scroll_position = false;
      }
    } finally {
      if (is_transaction_current(transaction)) {
        host.is_chapter_transaction_active = false;
      }
    }
  }

  /// 等待主列表具备滚动度量且目标章节标题已挂载。
  Future<void> wait_until_reading_layout_ready(
    int target_chapter_index,
  ) async {
    int wait_count = 0;
    while (host.host_mounted &&
        wait_count < Style.restore_layout_max_attempts) {
      final ScrollController controller = host.scroll_controller;
      final bool has_scroll_metrics =
          controller.hasClients &&
          controller.position.maxScrollExtent > Style.scroll_offset_epsilon;
      final bool has_chapter_context =
          host.logic.get_chapter_key(target_chapter_index).currentContext !=
          null;
      if (has_scroll_metrics && has_chapter_context) {
        return;
      }

      await WidgetsBinding.instance.endOfFrame;
      wait_count++;
    }
  }

  /// 开启新的章节布局事务，返回事务代数。
  int begin_transaction() => ++_transaction_generation;

  /// 指定事务代数是否仍是最新。
  bool is_transaction_current(int transaction) =>
      transaction == _transaction_generation;

  /// 获取指定章节标题当前在屏幕上的全局位置；未渲染返回 null。
  double? get_chapter_title_global_top(int chapter_index) {
    final BuildContext? chapter_context = host.logic
        .get_chapter_key(chapter_index)
        .currentContext;
    if (chapter_context == null) {
      return null;
    }

    final RenderObject? render_object = chapter_context.findRenderObject();
    if (render_object is! RenderBox || !render_object.hasSize) {
      return null;
    }

    return render_object.localToGlobal(Offset.zero).dy;
  }

  /// 计算章节标题滚动到“可视顶部 + [top_offset]”时的目标滚动偏移。
  double? get_chapter_title_target_scroll_offset(
    int chapter_index, {
    required double top_offset,
  }) {
    final ScrollController controller = host.scroll_controller;
    if (!controller.hasClients) {
      return null;
    }

    final double? chapter_title_top = get_chapter_title_global_top(
      chapter_index,
    );
    if (chapter_title_top == null) {
      return null;
    }

    final double screen_top_inset = MediaQuery.viewPaddingOf(
      host.host_context,
    ).top;
    final double target_global_top = screen_top_inset + top_offset;
    final double target_offset =
        controller.offset + chapter_title_top - target_global_top;

    return target_offset.clamp(0.0, controller.position.maxScrollExtent);
  }

  /// 第一章标题是否已进入可视区域底部阈值以内。
  bool is_first_chapter_title_past_start_threshold() {
    final double? first_title_top = get_chapter_title_global_top(0);
    if (first_title_top == null) {
      return true;
    }

    final double viewport_height = MediaQuery.sizeOf(host.host_context).height;
    final double trigger_top =
        viewport_height - Style.first_chapter_title_bottom_trigger_distance;
    return first_title_top <= trigger_top;
  }

  /// 等待章节标题完成布局，并返回其 BuildContext。
  Future<BuildContext?> wait_for_chapter_title_context(
    int chapter_index,
  ) async {
    final GlobalKey chapter_key = host.logic.get_chapter_key(chapter_index);
    BuildContext? chapter_context = chapter_key.currentContext;
    if (chapter_context != null) {
      return chapter_context;
    }

    await WidgetsBinding.instance.endOfFrame;
    if (!host.host_mounted) {
      return null;
    }
    chapter_context = chapter_key.currentContext;
    if (chapter_context != null) {
      return chapter_context;
    }

    await WidgetsBinding.instance.endOfFrame;
    if (!host.host_mounted) {
      return null;
    }
    return chapter_key.currentContext;
  }

  /// 将指定章节标题平滑滚动到可视区域顶部下方指定距离。
  Future<void> scroll_to_chapter_title_with_top_offset(
    int chapter_index, {
    required double top_offset,
  }) async {
    final ScrollController controller = host.scroll_controller;
    if (!controller.hasClients || !host.host_mounted) {
      return;
    }

    final BuildContext? chapter_context = await wait_for_chapter_title_context(
      chapter_index,
    );
    if (chapter_context == null ||
        !host.host_mounted ||
        !controller.hasClients) {
      return;
    }

    final double? target_offset = get_chapter_title_target_scroll_offset(
      chapter_index,
      top_offset: top_offset,
    );
    if (target_offset == null) {
      return;
    }

    await controller.animateTo(
      target_offset,
      duration: Duration(
        milliseconds: Style.scroll_to_reading_section_duration_ms,
      ),
      curve: Curves.easeInOutCubic,
    );
    if (host.host_mounted) {
      host.on_scroll_settled();
    }
  }

  /// 滚动到指定章节内的百分比位置（0-100）。
  ///
  /// 用当前章节标题与下一章标题的真实渲染位置计算章节高度，
  /// 避免把整个页面 maxScrollExtent 当作单章高度造成恢复位置漂移。
  Future<void> scroll_to_chapter_progress(
    int chapter_index, {
    required double chapter_progress_percent,
    bool animate = false,
  }) async {
    final ScrollController controller = host.scroll_controller;
    final Logic logic = host.logic;
    if (!controller.hasClients || !host.host_mounted) {
      return;
    }

    final BuildContext? chapter_context = await wait_for_chapter_title_context(
      chapter_index,
    );
    if (chapter_context == null ||
        !host.host_mounted ||
        !controller.hasClients) {
      return;
    }

    await WidgetsBinding.instance.endOfFrame;
    if (!host.host_mounted || !controller.hasClients) {
      return;
    }

    final double? chapter_start_offset = get_chapter_title_target_scroll_offset(
      chapter_index,
      top_offset: Style.chapter_progress_restore_top_offset,
    );
    if (chapter_start_offset == null) {
      await scroll_to_chapter_title_with_top_offset(
        chapter_index,
        top_offset: Style.chapter_progress_restore_top_offset,
      );
      return;
    }

    final double max_extent = controller.position.maxScrollExtent;
    double chapter_end_offset = max_extent;
    final int next_chapter_index = chapter_index + 1;
    if (next_chapter_index <= logic.loaded_chapter_index) {
      final double? next_chapter_start_offset =
          get_chapter_title_target_scroll_offset(
            next_chapter_index,
            top_offset: Style.chapter_progress_restore_top_offset,
          );
      if (next_chapter_start_offset != null &&
          next_chapter_start_offset > chapter_start_offset) {
        chapter_end_offset = next_chapter_start_offset;
      }
    }

    final double chapter_scroll_extent =
        (chapter_end_offset - chapter_start_offset).clamp(0.0, max_extent);
    final double progress_ratio =
        chapter_progress_percent.clamp(0.0, 100.0) / 100;
    final double target_offset =
        (chapter_start_offset + chapter_scroll_extent * progress_ratio).clamp(
          0.0,
          max_extent,
        );

    if (animate) {
      await controller.animateTo(
        target_offset,
        duration: Duration(
          milliseconds: Style.scroll_to_reading_section_duration_ms,
        ),
        curve: Curves.easeInOutCubic,
      );
    } else {
      controller.jumpTo(target_offset);
    }
    logic.sync_scroll_offset(target_offset);

    if (chapter_index >= 0 && chapter_index < logic.chapter_list.length) {
      logic.current_chapter_index.value = chapter_index;
      logic.current_chapter_db_id =
          int.tryParse(logic.chapter_list[chapter_index].id) ?? 0;
    }
  }

  /// 基于真实章节标题位置计算当前章节内阅读百分比。
  ///
  /// 优先使用布局位置而不是全书字数反推，让定时保存的 chapter_offset
  /// 与恢复时的章节内百分比保持同一种坐标系。
  double? calculate_current_chapter_progress_from_layout(int chapter_index) {
    final ScrollController controller = host.scroll_controller;
    final Logic logic = host.logic;
    if (!controller.hasClients || !host.host_mounted) {
      return null;
    }

    final double? chapter_start_offset = get_chapter_title_target_scroll_offset(
      chapter_index,
      top_offset: Style.chapter_progress_restore_top_offset,
    );
    if (chapter_start_offset == null) {
      return null;
    }

    final double max_extent = controller.position.maxScrollExtent;
    double chapter_end_offset = max_extent;
    final int next_chapter_index = chapter_index + 1;
    if (next_chapter_index <= logic.loaded_chapter_index) {
      final double? next_chapter_start_offset =
          get_chapter_title_target_scroll_offset(
            next_chapter_index,
            top_offset: Style.chapter_progress_restore_top_offset,
          );
      if (next_chapter_start_offset != null &&
          next_chapter_start_offset > chapter_start_offset) {
        chapter_end_offset = next_chapter_start_offset;
      }
    }

    final double chapter_scroll_extent =
        chapter_end_offset - chapter_start_offset;
    if (chapter_scroll_extent <= Style.scroll_offset_epsilon) {
      return 0;
    }

    final double progress_ratio =
        ((controller.offset - chapter_start_offset) / chapter_scroll_extent)
            .clamp(0.0, 1.0);
    return progress_ratio * 100;
  }

  /// 在插入上一章时保持原列表顶部章节的屏幕坐标不变。
  Future<void> preserve_chapter_anchor(
    VoidCallback mutation,
    int anchor_chapter_index,
  ) async {
    final ScrollController controller = host.scroll_controller;
    if (!host.host_mounted || !controller.hasClients) {
      mutation();
      return;
    }

    final double old_offset = controller.offset;
    final double old_max_extent = controller.position.maxScrollExtent;
    final double? old_anchor_top = get_chapter_title_global_top(
      anchor_chapter_index,
    );

    mutation();
    await WidgetsBinding.instance.endOfFrame;
    if (!host.host_mounted || !controller.hasClients) return;

    final double? new_anchor_top = get_chapter_title_global_top(
      anchor_chapter_index,
    );
    final double fallback_delta =
        controller.position.maxScrollExtent - old_max_extent;
    final double anchor_delta = old_anchor_top != null && new_anchor_top != null
        ? new_anchor_top - old_anchor_top
        : fallback_delta;
    if (anchor_delta.abs() <= Style.scroll_offset_epsilon) return;

    final ScrollPosition position = controller.position;
    final double target_offset = (old_offset + anchor_delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    host.is_programmatic_scroll = true;
    try {
      position.jumpTo(target_offset);
      host.logic.sync_scroll_offset(target_offset);
    } finally {
      host.is_programmatic_scroll = false;
    }
  }
}
