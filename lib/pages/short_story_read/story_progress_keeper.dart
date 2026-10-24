import 'dart:async';

import 'package:app/api/bookshelf.dart';
import 'package:app/pages/short_story_read/logic.dart';
import 'package:app/pages/short_story_read/style.dart';
import 'package:app/pages/short_story_read/utils/calculate_current_story_scroll_extent.dart';
import 'package:app/services/bookshelf_sync_service.dart';
import 'package:app/stores/user_information.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 短篇阅读进度记忆的宿主能力。
abstract class StoryProgressHost {
  /// 宿主是否仍然挂载。
  bool get host_mounted;

  /// 滚动控制器。
  ScrollController get scroll_controller;

  /// 正文末尾锚点。
  GlobalKey get story_end_key;

  /// 可见正文进度上限（简介区不计入）。
  double get visible_progress_limit;

  /// 阅读树代数与尝试次数是否仍然有效。
  bool is_current_initialization(
    ShortStoryReadLogic logic,
    int generation,
    int attempt,
  );

  /// 恢复滚动期间的标记（抑制进度回写）。
  set is_restoring_position(bool value);

  /// 恢复动画需要的页面上下文。
  BuildContext get host_context;

  /// 取正文滚动范围（优先返回已缓存值）。
  double resolve_story_extent();

  /// 写回正文滚动范围缓存。
  void cache_story_extent(double extent);

  /// 界面刷新。
  void refresh_ui();
}

/// 短篇阅读进度的保存与恢复器。
///
/// 保存侧用快照队列合并同一小说的多次写入；恢复侧等待正文布局完成后
/// 优先按百分比回到上次位置，像素偏移只作兼容回退。
class StoryProgressKeeper {
  StoryProgressKeeper({required this.host});

  /// 页面能力宿主。
  final StoryProgressHost host;

  /// 按小说 ID 合并的待保存进度快照。
  final Map<int, ({int chapter_offset, double read_progress, bool notify_bookshelf})>
      _queued_snapshots = {};

  /// 正在落盘的小说 ID，同一小说串行保存。
  final Set<int> _in_flight_ids = <int>{};

  /// 仅在正文已到达阅读位置时保存用于主按钮的本地快照。
  /// 服务器百分比仍沿用现有算法，简介展开和设备重排不改写其含义。
  void remember_body_reading_position({
    required ShortStoryReadLogic logic,
    required bool is_initialization_complete,
    required bool has_user_engaged,
  }) {
    if (!is_initialization_complete || !has_user_engaged) return;
    if (!host.scroll_controller.hasClients) return;
    unawaited(
      save_snapshot(logic, notify_bookshelf: false),
    );
  }

  /// 退出页面时保存阅读进度。
  void save_on_exit({
    required ShortStoryReadLogic logic,
    required bool is_initialization_complete,
    required bool has_user_engaged,
  }) {
    if (!is_initialization_complete || !has_user_engaged) return;
    unawaited(save_snapshot(logic, notify_bookshelf: true));
  }

  /// 保存当前阅读进度到服务器。
  Future<void> save_current({
    required ShortStoryReadLogic logic,
    required bool is_initialization_complete,
    required bool has_user_engaged,
  }) async {
    if (!is_initialization_complete || !has_user_engaged) return;
    await save_snapshot(logic);
  }

  /// 保存指定逻辑实例对应的进度快照；同一小说多次调用合并为最新值。
  Future<void> save_snapshot(
    ShortStoryReadLogic logic, {
    bool notify_bookshelf = false,
  }) async {
    final ScrollController controller = host.scroll_controller;
    if (!controller.hasClients ||
        !Get.find<UserInformation>().isLoggedIn.value) {
      return;
    }

    final int novel_id = logic.story_id;
    final int novel_language_id =
        int.tryParse(logic.story_data.value?.novel_language_id ?? '') ?? 0;
    final previous = _queued_snapshots[novel_id];
    _queued_snapshots[novel_id] = (
      chapter_offset: controller.offset.round(),
      read_progress: logic.reading_progress.value * 100,
      notify_bookshelf:
          notify_bookshelf || (previous?.notify_bookshelf ?? false),
    );
    if (!_in_flight_ids.add(novel_id)) return;

    try {
      while (_queued_snapshots.containsKey(novel_id)) {
        final snapshot = _queued_snapshots.remove(novel_id)!;
        try {
          final bool saved = await save_read_progress(
            novel_id: novel_id,
            novel_language_id: novel_language_id > 0 ? novel_language_id : null,
            chapter_offset: snapshot.chapter_offset,
            read_progress: snapshot.read_progress,
          );
          if (saved && snapshot.notify_bookshelf) {
            await BookshelfSyncService.history_changed();
          }
        } catch (_) {
          // 保存失败不影响阅读；下一次定时保存会提交更新后的快照。
        }
      }
    } finally {
      _in_flight_ids.remove(novel_id);
    }
  }

  /// 根据真实加载结果和正文布局恢复上次阅读位置。
  Future<void> restore_last_position({
    required ShortStoryReadLogic logic,
    required int generation,
    required int attempt,
    required LastReadRecord record,
  }) async {
    final bool has_offset = record.chapter_offset > 0;
    final bool has_progress = record.read_progress > 0;
    await wait_for_story_layout(
      logic: logic,
      generation: generation,
      attempt: attempt,
    );
    if (!host.is_current_initialization(logic, generation, attempt) ||
        (!has_offset && !has_progress)) {
      return;
    }

    do_restore_position(logic: logic, record: record);
  }

  /// 等待正文真实挂载，并计算只属于当前篇的滚动范围。
  Future<void> wait_for_story_layout({
    required ShortStoryReadLogic logic,
    required int generation,
    required int attempt,
  }) async {
    for (int frame = 0; frame < 12; frame++) {
      await WidgetsBinding.instance.endOfFrame;
      if (!host.is_current_initialization(logic, generation, attempt)) return;

      if (host.scroll_controller.hasClients &&
          host.scroll_controller.position.hasContentDimensions &&
          host.story_end_key.currentContext != null) {
        return;
      }
    }
  }

  /// 计算正文末尾对齐可视区域底部时的真实滚动偏移。
  double calculate_story_extent() {
    return calculate_current_story_scroll_extent(
      scroll_controller: host.scroll_controller,
      story_end_key: host.story_end_key,
    );
  }

  /// 执行滚动位置恢复。
  void do_restore_position({
    required ShortStoryReadLogic logic,
    required LastReadRecord record,
  }) {
    final ScrollController controller = host.scroll_controller;
    if (!controller.hasClients) return;

    final double max_extent = host.resolve_story_extent();
    if (max_extent <= 0) return;
    double target_offset = 0;

    // 优先使用百分比恢复，像素偏移在屏幕尺寸或字号变化后会失效。
    if (record.read_progress > 0) {
      final double visible_progress =
          (record.read_progress / 100 / host.visible_progress_limit).clamp(
            0.0,
            1.0,
          );
      target_offset = (visible_progress * max_extent).clamp(0.0, max_extent);
    } else if (record.chapter_offset > 0) {
      target_offset = record.chapter_offset
          .clamp(0, max_extent.toInt())
          .toDouble();
    }

    if (target_offset > 0) {
      host.is_restoring_position = true;
      if (MediaQuery.disableAnimationsOf(host.host_context)) {
        controller.jumpTo(target_offset);
      } else {
        controller.animateTo(
          target_offset,
          duration: ShortStoryReadStyle.read_entry_duration,
          curve: Curves.easeInOutCubic,
        );
      }
      logic.update_reading_progress(
        target_offset,
        max_extent,
        max_progress: host.visible_progress_limit,
      );
      host.is_restoring_position = false;
    }
  }

  /// 释放资源。
  void dispose() {
    _queued_snapshots.clear();
    _in_flight_ids.clear();
  }
}
