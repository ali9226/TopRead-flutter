import 'dart:async';

import 'package:app/api/bookshelf.dart';
import 'package:app/pages/read/logic.dart';
import 'package:app/pages/read/reading_chapter_anchor.dart';
import 'package:app/pages/read/style.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// 长篇章节跳转与进度恢复的宿主能力。
abstract class ChapterJumpHost {
  /// 宿主是否仍然挂载。
  bool get host_mounted;

  /// 当前小说 ID。
  int get novel_id;

  /// 页面逻辑层。
  Logic get logic;

  /// 章节锚点协调器。
  ReadingChapterAnchor get anchor;

  /// 滚动控制器。
  ScrollController get scroll_controller;

  /// 恢复服务器进度期间的标记（阻止展示第一章与广告）。
  set is_restoring_progress(bool value);

  /// 是否需要恢复滚动位置。
  set needs_restore_scroll_position(bool value);

  /// 章节布局事务标记。
  set is_chapter_transaction_active(bool value);

  /// 写入章内进度缓存。
  set cached_chapter_progress(double value);

  /// 标记进度已稳定。
  set has_stable_progress(bool value);

  /// 标记用户已交互。
  set has_user_engaged(bool value);

  /// 通知“已有阅读历史”（续读 UI）。
  set has_reading_history(bool value);

  /// 更新全书阅读进度。
  void set_reading_progress(double progress_percent);

  /// 更新“已开始阅读”标记。
  void set_has_started_reading(bool value);

  /// 启动进度定时保存。
  void start_progress_save_timer();

  /// 事务结束后恢复视口变化前的章内位置。
  void try_restore_pending_viewport_change();

  /// 跳转落定后补齐预取与进度（页面滚动协调器入口）。
  void on_jump_settled();

  /// 打开评论弹窗。
  Future<void> open_comment_sheet({int scroll_to_comment_id = 0});
}

/// 长篇阅读页章节跳转事务与服务器进度恢复。
///
/// 跳转事务串起：窗口重建 → 布局就绪 → 百分比定位 → 进度回写；
/// 通过锚点协调器的事务代数保证并发操作只认最后一次。
class ReadingChapterJump {
  ReadingChapterJump({required this.host});

  /// 页面能力宿主。
  final ChapterJumpHost host;

  /// 初始化并按服务器进度静默跳到目标章节。
  ///
  /// 流程：查询阅读记录 → fetch_info → 有进度则执行跳转事务 → 撤下恢复标记。
  Future<void> init_with_progress_restore() async {
    final Logic logic = host.logic;
    host.is_restoring_progress = true;

    final Future<void> info_future = logic.fetch_info();
    final Future<LastReadRecord?> record_future =
        Get.find<UserInformation>().isLoggedIn.value
        ? get_last_read_record(novel_id: host.novel_id)
        : Future<LastReadRecord?>.value();

    final LastReadRecord? record = await record_future;
    await info_future;
    if (!host.host_mounted) return;

    final bool has_progress =
        record != null && (record.chapter_id > 0 || record.read_progress > 0);

    if (has_progress && logic.chapter_list.isNotEmpty) {
      host.has_reading_history = true;
      showBottomTip(easy.tr('read.restoring_progress'));
      final int target_index = resolve_restore_chapter_index(record);
      final double restore_chapter_progress = resolve_restore_chapter_progress(
        record: record,
        target_chapter_index: target_index,
      );

      await execute_chapter_jump(
        target_index,
        chapter_progress_percent: restore_chapter_progress,
        mark_user_engaged: false,
      );
    } else {
      host.has_stable_progress = logic.chapter_list.isNotEmpty;
      host.set_reading_progress(0);
      host.set_has_started_reading(false);
    }

    if (!host.host_mounted) return;
    host.is_restoring_progress = false;
    host.start_progress_save_timer();
  }

  /// 执行一次完整章节跳转事务。
  ///
  /// 章节窗口重建、目标布局与精确定位全部完成后才收尾。连续操作时
  /// 通过事务代数校验，旧任务不会覆盖最后一次选择。
  /// [reuse_loaded_chapter] 为 true 时复用已在正文列表中的章节，只执行定位。
  Future<void> execute_chapter_jump(
    int target_index, {
    double chapter_progress_percent = 0,
    bool mark_user_engaged = true,
    bool animate_scroll = false,
    bool reuse_loaded_chapter = false,
  }) async {
    final Logic logic = host.logic;
    final ReadingChapterAnchor anchor = host.anchor;
    if (target_index < 0 || target_index >= logic.chapter_list.length) return;

    host.needs_restore_scroll_position = false;
    final int transaction = anchor.begin_transaction();
    host.is_chapter_transaction_active = true;
    final bool rebuild_window =
        !reuse_loaded_chapter ||
        !logic.loaded_chapter_indexes.contains(target_index);
    logic.show_navigation.value = false;
    int? logic_generation;
    try {
      if (rebuild_window) {
        logic.is_switching_chapter.value = true;
        logic_generation = await logic.jump_to_chapter(target_index);
        if (logic_generation == null) return;
      }
      if (!host.host_mounted || !anchor.is_transaction_current(transaction)) {
        return;
      }

      await anchor.wait_until_reading_layout_ready(target_index);
      if (!host.host_mounted || !anchor.is_transaction_current(transaction)) {
        return;
      }

      await anchor.scroll_to_chapter_progress(
        target_index,
        chapter_progress_percent: chapter_progress_percent,
        animate: animate_scroll,
      );
      if (!host.host_mounted || !anchor.is_transaction_current(transaction)) {
        return;
      }

      host.cached_chapter_progress = chapter_progress_percent.clamp(0.0, 100.0);
      logic.update_chapter_progress(chapter_progress_percent.clamp(0.0, 100.0));
      host.set_reading_progress(
        logic.calculate_total_progress_percent_for_chapter(
          chapter_index: target_index,
          chapter_progress_percent: chapter_progress_percent.clamp(0.0, 100.0),
        ),
      );
      host.set_has_started_reading(
        target_index > 0 ||
            chapter_progress_percent > Style.scroll_offset_epsilon ||
            anchor.is_first_chapter_title_past_start_threshold(),
      );
      host.has_stable_progress = true;
      if (mark_user_engaged) {
        host.has_user_engaged = true;
      }

      await WidgetsBinding.instance.endOfFrame;
      if (host.scroll_controller.hasClients) {
        logic.sync_scroll_offset(host.scroll_controller.offset);
      }
    } finally {
      if (logic_generation != null) {
        logic.complete_chapter_jump(logic_generation);
      }
      if (anchor.is_transaction_current(transaction)) {
        host.is_chapter_transaction_active = false;
        logic.is_switching_chapter.value = false;
        host.try_restore_pending_viewport_change();
        // 若跳章窗口中的上一章曾短暂加载失败，结束事务后立即检查并补齐顶部缺口。
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (host.host_mounted) {
            host.on_jump_settled();
          }
        });
      }
    }
  }

  /// 从阅读记录中解析需要恢复到的章节索引。
  ///
  /// 优先按 chapter_id 匹配章节数据库 id；只有完全没有章节记录时，
  /// 才使用全书阅读百分比推算。
  int resolve_restore_chapter_index(LastReadRecord record) {
    final Logic logic = host.logic;
    if (record.chapter_id > 0) {
      // chapter_id 是后端保存的数据库 id，直接按数据库 id 匹配。
      final int? db_id_index = find_chapter_index_by_db_id(record.chapter_id);
      if (db_id_index != null) {
        return db_id_index;
      }

      // 数据库 id 匹配失败时，尝试将 chapter_id 视为 chapter_no 兼容旧数据。
      final int? chapter_no_index = find_chapter_index_by_chapter_no(
        record.chapter_id,
      );
      if (chapter_no_index != null) {
        return chapter_no_index;
      }
    }

    if (record.read_progress <= 0) {
      return 0;
    }

    int target_index = logic.find_chapter_index_by_progress(
      record.read_progress,
    );
    if (record.chapter_offset < 20 && target_index > 0) {
      target_index--;
    }
    return target_index.clamp(0, logic.chapter_list.length - 1);
  }

  /// 按章节数据库 id 查找目录索引。
  int? find_chapter_index_by_db_id(int chapter_id) {
    final List chapter_list = host.logic.chapter_list;
    for (int i = 0; i < chapter_list.length; i++) {
      final int current_chapter_id = int.tryParse(chapter_list[i].id) ?? 0;
      if (current_chapter_id == chapter_id) {
        return i;
      }
    }
    return null;
  }

  /// 按章节序号查找目录索引。
  int? find_chapter_index_by_chapter_no(int chapter_no) {
    final List chapter_list = host.logic.chapter_list;
    for (int i = 0; i < chapter_list.length; i++) {
      if (chapter_list[i].chapter_no == chapter_no) {
        return i;
      }
    }
    return null;
  }

  /// 从阅读记录中解析章节内恢复百分比。
  ///
  /// chapter_offset 是后端保存的章节内百分比；缺失时才用全书百分比反推。
  double resolve_restore_chapter_progress({
    required LastReadRecord record,
    required int target_chapter_index,
  }) {
    if (record.chapter_offset > 0) {
      return record.chapter_offset.toDouble().clamp(0.0, 100.0);
    }

    return host.logic.calculate_chapter_progress_percent(
      reading_progress_percent: record.read_progress,
      chapter_index: target_chapter_index,
    );
  }
}
