// ignore_for_file: non_constant_identifier_names

import 'package:app/models/preference.dart';
import 'package:app/pages/author_center/models/creator_work.dart';
import 'package:app/pages/work_editor/_shared/style.dart';
import 'package:app/stores/preference_store.dart';
import 'package:get/get.dart';

/// 作品编辑器表单管理 Mixin。
///
/// 负责偏好管理、步骤校验、数据构建等表单相关逻辑。
mixin WorkEditorFormMixin {
  /// 各偏好分类的选中项（key 为偏好类别 id，value 为已选选项 id 集合）。
  Map<int, Set<int>> get selected_preference_map;

  /// 存在错误的步骤索引集合。
  Set<int> get error_steps;

  /// 标题输入控制器。
  dynamic get title_controller;

  /// 简介输入控制器。
  dynamic get introduction_controller;

  /// 短篇正文输入控制器。
  dynamic get short_content_controller;

  /// 长篇章节标题输入控制器。
  dynamic get chapter_title_controller;

  /// 长篇章节正文输入控制器。
  dynamic get chapter_content_controller;

  /// 长篇章节列表。
  List<CreatorChapterDraft> get chapters;

  /// 当前编辑的章节索引。
  int get active_chapter_index;

  /// 是否已确认原创和授权声明。
  bool get rights_confirmed;

  /// 发布方式。
  CreatorReleaseMode get release_mode;

  /// 定时发布时刻。
  DateTime? get scheduled_publish_time;

  /// 通知状态变更的回调。
  void Function(void Function()) get notifyStateChanged;

  /// 兼容偏好配置暂未加载或旧稿未保存偏好的情况。
  CreatorWorkType get fallback_work_type => CreatorWorkType.short;

  /// 当前选择的篇幅类型（从偏好 map 推导）。
  CreatorWorkType get work_type {
    final int? pref_id = find_preference_group_by_item_id(
      WorkEditorStyle.long_work_id,
    );
    if (pref_id == null) return fallback_work_type;
    final Set<int> selected = selected_preference_map[pref_id] ?? <int>{};
    if (selected.isEmpty) return fallback_work_type;
    return selected.contains(WorkEditorStyle.long_work_id)
        ? CreatorWorkType.long
        : CreatorWorkType.short;
  }

  /// 当前选择的分类 id（从偏好 map 中提取）。
  Set<int> get selected_category_ids {
    return selected_preference_map[WorkEditorStyle.preference_category_id] ??
        <int>{};
  }

  /// 根据选项 ID 查找其所属偏好分组 ID。
  int? find_preference_group_by_item_id(int item_id) {
    final PreferenceStore store = Get.find<PreferenceStore>();
    for (final Preference pref in store.preference_list) {
      for (final PreferenceItem item in pref.data_list) {
        if (item.id == item_id) {
          return pref.id;
        }
      }
    }
    return null;
  }

  /// 新增作品时设置各偏好默认值。
  void set_default_preferences() {
    final PreferenceStore store = Get.find<PreferenceStore>();
    set_preference_by_id(store, WorkEditorStyle.gender_any_id);
    set_preference_by_id(store, WorkEditorStyle.short_work_id);

    for (final Preference pref in store.preference_list) {
      final String title = pref.title;
      if (title.contains('完结') || title.toLowerCase().contains('complet')) {
        for (final PreferenceItem item in pref.data_list) {
          if (item.title.contains('连载') ||
              item.title.toLowerCase().contains('serial')) {
            selected_preference_map[pref.id] = <int>{item.id};
            return;
          }
        }
        return;
      }
    }
  }

  /// 根据选项 ID 设置其所属偏好分组的默认选中。
  void set_preference_by_id(PreferenceStore store, int item_id) {
    for (final Preference pref in store.preference_list) {
      for (final PreferenceItem item in pref.data_list) {
        if (item.id == item_id) {
          selected_preference_map[pref.id] = <int>{item_id};
          return;
        }
      }
    }
  }

  /// 判断是否为强制单选偏好（状态、篇幅）。
  bool is_force_single_preference(Preference pref) {
    final String title = pref.title;
    if (title.contains('完结') || title.toLowerCase().contains('complet')) {
      return true;
    }
    return title.contains('篇幅') || title.toLowerCase().contains('length');
  }

  /// 切换偏好选中状态。
  void toggle_preference(int preference_id, int item_id) {
    final CreatorWorkType old_type = work_type;

    notifyStateChanged(() {
      final Set<int> current =
          selected_preference_map[preference_id] ?? <int>{};
      final PreferenceStore store = Get.find<PreferenceStore>();
      final Preference? pref = store.find_preference_by_id(preference_id);
      final bool is_single = pref != null
          ? is_force_single_preference(pref) || pref.is_single_select
          : true;

      if (is_single) {
        if (!current.contains(item_id)) {
          selected_preference_map[preference_id] = <int>{item_id};
        }
      } else {
        final Set<int> next = Set<int>.from(current);
        if (next.contains(item_id)) {
          next.remove(item_id);
        } else {
          next.add(item_id);
        }
        selected_preference_map[preference_id] = next;
      }
    });

    final CreatorWorkType new_type = work_type;
    if (old_type != new_type) {
      sync_content_between_modes(old_type, new_type);
    }
  }

  /// 切换篇幅类型时同步正文内容。
  void sync_content_between_modes(
    CreatorWorkType from_type,
    CreatorWorkType to_type,
  ) {
    final String short_content = short_content_controller.text;
    final String chapter_content = chapter_content_controller.text;

    if (from_type == CreatorWorkType.short && to_type == CreatorWorkType.long) {
      if (chapter_content.isEmpty && short_content.isNotEmpty) {
        chapter_content_controller.text = short_content;
      }
    } else if (from_type == CreatorWorkType.long &&
        to_type == CreatorWorkType.short) {
      if (short_content.isEmpty && chapter_content.isNotEmpty) {
        short_content_controller.text = chapter_content;
      }
    }
  }

  /// 校验指定步骤是否填写完整。
  bool validate_step(int step) {
    switch (step) {
      case 0:
        return title_controller.text.trim().isNotEmpty;
      case 1:
        return true;
      case 2:
        if (work_type == CreatorWorkType.long) {
          if (chapters.isNotEmpty) return true;
          return chapter_title_controller.text.trim().isNotEmpty &&
              chapter_content_controller.text.trim().isNotEmpty;
        }
        return short_content_controller.text.trim().isNotEmpty;
      case 3:
        if (release_mode == CreatorReleaseMode.scheduled) {
          return scheduled_publish_time != null && rights_confirmed;
        }
        return rights_confirmed;
      default:
        return true;
    }
  }

  /// 刷新所有步骤的错误状态集合。
  void refresh_error_steps() {
    error_steps.clear();
    for (int i = 0; i < 4; i++) {
      if (!validate_step(i)) {
        error_steps.add(i);
      }
    }
  }

  /// 把输入中的完整章节移入列表，并清空输入，失败重试时不会重复添加。
  bool commit_current_chapter() {
    final String title = chapter_title_controller.text.trim();
    final String content = chapter_content_controller.text;
    if (title.isEmpty || content.trim().isEmpty) return false;
    final now = DateTime.now();
    chapters.add(CreatorChapterDraft(
      local_id: 'chapter_${now.microsecondsSinceEpoch}',
      title: title,
      content: content,
      update_time: now,
    ));
    chapter_title_controller.clear();
    chapter_content_controller.clear();
    return true;
  }

  /// 构造要返回给创作者中心的本地作品模型。
  CreatorWorkDraft build_work(
    CreatorWorkStatus status, {
    required String local_id,
    required String language_code,
    required int current_step,
    String? cover_url,
  }) {
    final DateTime now = DateTime.now();
    final Map<String, List<int>> prefs = {};
    selected_preference_map.forEach((key, value) {
      prefs[key.toString()] = value.toList();
    });
    // 保存当前章节索引到 preferences 中，用于恢复进度。
    prefs['_lastChapter'] = [active_chapter_index];

    return CreatorWorkDraft(
      local_id: local_id,
      title: title_controller.text.trim(),
      introduction: introduction_controller.text.trim(),
      work_type: work_type,
      is_completed: false,
      language_code: language_code,
      category_ids: selected_category_ids.toList(growable: false),
      short_content: work_type == CreatorWorkType.short
          ? short_content_controller.text
          : '',
      chapters: work_type == CreatorWorkType.long
          ? List<CreatorChapterDraft>.unmodifiable(chapters)
          : const <CreatorChapterDraft>[],
      status: status,
      release_mode: release_mode,
      scheduled_publish_time: release_mode == CreatorReleaseMode.scheduled
          ? scheduled_publish_time
          : null,
      update_time: now,
      is_demo: false,
      cover_url: cover_url,
      saved_step: current_step,
      preferences: prefs,
      rights_confirmed: rights_confirmed,
      chapter_title: chapter_title_controller.text.trim(),
      chapter_content: chapter_content_controller.text,
      lastEditedChapterIndex: active_chapter_index,
    );
  }
}
