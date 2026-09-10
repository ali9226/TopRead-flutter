// ignore_for_file: non_constant_identifier_names

import 'dart:io';
import 'style.dart';
import 'package:app/api/creator_workspace.dart';
import 'package:app/pages/author_center/models/creator_work.dart';
import 'package:app/pages/work_editor/_shared/backend_draft_loader.dart';
import 'package:app/pages/work_editor/_shared/style.dart';
import 'package:app/pages/work_editor/single_chapter/logic.dart';
import 'package:app/pages/work_editor/workspace/logic.dart';
import 'package:app/stores/language_store.dart';
import 'package:app/stores/preference_store.dart';
import 'package:app/util/upload_file.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

/// 三个 Tab 独立编辑；提交只采纳当前 Tab，其他 Tab 的未保存输入保持不变。
class PublishedNovelController extends ChangeNotifier {
  PublishedNovelController(
    this.novel_id, {
    this.call = CreatorWorkspaceApi.call,
    Future<CreatorWorkDraft> Function(int)? load_work,
  }) : load_work = load_work ?? _load_work;
  final Future<Map<String, dynamic>> Function(String, Map<String, dynamic>)
  call;
  final Future<CreatorWorkDraft> Function(int) load_work;
  static Future<CreatorWorkDraft> _load_work(int id) =>
      loadCreatorWorkDraft(id, includeChapters: false);
  final int novel_id;
  final title = TextEditingController();
  final introduction = TextEditingController();
  CreatorWorkDraft? saved;
  Map<int, Set<int>> preferences = {};
  String language_code = '';
  String? cover_url;
  String? cover_local_path;
  bool uploading = false;
  bool loading = false;
  bool chapters_loading = false;
  bool saving = false;
  bool details_dirty = false;
  bool settings_dirty = false;
  bool descending = true;
  bool ordering = false;
  bool order_dirty = false;
  List<int> base_order = [];
  Map<String, dynamic>? _order_pending;
  Map<String, dynamic>? _delete_pending;
  String? error;
  List<Map<String, dynamic>> chapters = [];
  Map<String, dynamic>? _pending;
  int? pending_section;
  bool _disposed = false;

  bool get dirty => details_dirty || settings_dirty || order_dirty;
  bool get locked =>
      loading ||
      chapters_loading ||
      saving ||
      uploading ||
      _pending != null ||
      _order_pending != null ||
      _delete_pending != null;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      saved = await load_work(novel_id);
      if (_disposed) return;
      title.text = saved!.title;
      introduction.text = saved!.introduction;
      language_code = saved!.language_code;
      cover_url = saved!.cover_url;
      preferences = {
        for (final entry in saved!.preferences.entries)
          if (int.tryParse(entry.key) != null)
            int.parse(entry.key): entry.value.toSet(),
      };
      preferences.putIfAbsent(
        WorkEditorStyle.preference_category_id,
        () => saved!.category_ids.toSet(),
      );
      // 数据库定义：4 为连载状态；114 完结，115 连载。
      preferences[PublishedEditorStyle.status_group] = {
        saved!.is_completed
            ? PublishedEditorStyle.completed_item
            : PublishedEditorStyle.serializing_item,
      };
      title.addListener(mark_details);
      introduction.addListener(mark_details);
      await load_chapters();
    } catch (e) {
      error = '$e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// 取消排序丢弃本地顺序，再读取服务器最新目录以解除并发冲突。
  Future<void> cancel_order() async {
    if (locked) return;
    try {
      await load_chapters();
      ordering = false;
      notifyListeners();
    } catch (_) {
      /* 保留错误，允许再次刷新。 */
    }
  }

  void mark_details() {
    details_dirty = true;
    notifyListeners();
  }

  void set_language(String code) {
    language_code = code;
    mark_details();
  }

  void toggle_preference(int group, int item) {
    final pref = Get.find<PreferenceStore>().find_preference_by_id(group);
    final selected = preferences[group] ?? <int>{};
    if (group == PublishedEditorStyle.status_group ||
        pref?.is_single_select == true) {
      preferences[group] = {item};
    } else {
      if (!selected.contains(item) &&
          selected.length >= PublishedEditorStyle.max_categories) {
        return;
      }
      preferences[group] = {...selected};
      selected.contains(item)
          ? preferences[group]!.remove(item)
          : preferences[group]!.add(item);
    }
    settings_dirty = true;
    notifyListeners();
  }

  Future<void> pick_cover(ImageSource source) async {
    if (locked) return;
    uploading = true;
    error = null;
    notifyListeners();
    try {
      final image = await ImagePicker().pickImage(
        source: source,
        maxWidth: PublishedEditorStyle.cover_max_width,
        imageQuality: PublishedEditorStyle.cover_quality,
      );
      if (image == null || _disposed) return;
      cover_local_path = image.path;
      notifyListeners();
      final url = await uploadFile(File(image.path));
      if (url == null) {
        throw Exception(tr('creator_center.cover_upload_failed'));
      }
      cover_url = url;
      details_dirty = true;
    } catch (e) {
      error = '$e';
    } finally {
      uploading = false;
      cover_local_path = null;
      notifyListeners();
    }
  }

  /// 后端一次返回完整元数据；正文只在打开单章时读取。
  Future<void> load_chapters() async {
    if (chapters_loading) return;
    chapters_loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await call('creator_chapter/directory', {
        'novel_id': novel_id,
        'novel_language_id': saved!.novel_language_id,
        'all': true,
        'state': 'all',
      });
      if (_disposed) return;
      final rows = creatorRows(result['list'])
          .where(
            (row) =>
                creatorNumber(row['chapter_id']) > 0 ||
                row['is_scheduled'] == true ||
                creatorNumber(row['is_scheduled']) == 1 ||
                creatorNumber(row['release_status']) == 2,
          )
          .toList();
      chapters = rows
          .map(
            (row) => creatorNumber(row['chapter_id']) > 0
                ? <String, dynamic>{
                    ...row,
                    'title': row['published_title'] ?? row['title'],
                    'chapter_no': row['published_no'] ?? row['chapter_no'],
                    'word_count':
                        row['published_word_count'] ?? row['word_count'],
                  }
                : row,
          )
          .toList();
      final published =
          chapters.where((r) => creatorNumber(r['chapter_id']) > 0).toList()
            ..sort(
              (a, b) => creatorNumber(
                a['chapter_no'],
              ).compareTo(creatorNumber(b['chapter_no'])),
            );
      base_order = published
          .map((r) => creatorNumber(r['chapter_id']))
          .toList();
      order_dirty = false;
    } catch (e) {
      error = '$e';
      rethrow;
    } finally {
      chapters_loading = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> get visible_chapters {
    if (ordering) {
      return chapters.where((r) => creatorNumber(r['chapter_id']) > 0).toList();
    }
    final rows = List<Map<String, dynamic>>.of(chapters);
    rows.sort((a, b) {
      // 尚未分配公开章号的定时章节排在正序末尾、倒序开头。
      final a_no = creatorNumber(a['chapter_no']);
      final b_no = creatorNumber(b['chapter_no']);
      var order = (a_no == 0 ? 1 : 0).compareTo(b_no == 0 ? 1 : 0);
      if (order == 0) order = a_no.compareTo(b_no);
      if (order == 0) {
        order = creatorNumber(
          a['revision_id'] ?? a['chapter_id'],
        ).compareTo(creatorNumber(b['revision_id'] ?? b['chapter_id']));
      }
      return descending ? -order : order;
    });
    return rows;
  }

  /// 排序模式固定正序，未公开的定时章节不占据公开章节位置。
  void toggle_ordering() {
    if (locked) return;
    if (!ordering && !order_dirty) {
      chapters.sort(
        (a, b) => creatorNumber(
          a['chapter_no'],
        ).compareTo(creatorNumber(b['chapter_no'])),
      );
    }
    ordering = !ordering;
    notifyListeners();
  }

  void reorder(int old_index, int target_index) {
    if (locked || !ordering) return;
    final rows = visible_chapters;
    final moved = rows.removeAt(old_index);
    rows.insert(target_index, moved);
    final positions = rows.map((r) => creatorNumber(r['chapter_no'])).toList()
      ..sort();
    chapters = [
      for (var i = 0; i < rows.length; i++)
        {...rows[i], 'chapter_no': positions[i]},
      ...chapters.where((r) => creatorNumber(r['chapter_id']) == 0),
    ];
    order_dirty = true;
    notifyListeners();
  }

  /// 网络结果未知时保留相同请求标识，重试不会重复执行排序。
  Future<void> update_order() async {
    if (saving ||
        saved == null ||
        (!order_dirty && _order_pending == null) ||
        (pending_section != null && pending_section != 2)) {
      return;
    }
    saving = true;
    error = null;
    notifyListeners();
    try {
      _order_pending ??= {
        'novel_id': novel_id,
        'novel_language_id': saved!.novel_language_id,
        'chapter_ids': chapters
            .where((r) => creatorNumber(r['chapter_id']) > 0)
            .map((r) => creatorNumber(r['chapter_id']))
            .toList(),
        'base_order': List.of(base_order),
        'request_key': creatorRequestKey(),
      };
      pending_section = 2;
      await call('creator_chapter/reorder', _order_pending!);
      _order_pending = null;
      pending_section = null;
      order_dirty = false;
      await load_chapters();
      ordering = false;
    } catch (e) {
      if (e is CreatorWorkspaceException && e.serverRejected) {
        _order_pending = null;
        pending_section = null;
      }
      error = '$e';
      rethrow;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> delete_work() async {
    if (saving || (pending_section != null && pending_section != 3)) return;
    saving = true;
    error = null;
    notifyListeners();
    try {
      _delete_pending ??= {
        'novel_id': novel_id,
        'confirm_published': true,
        'request_key': creatorRequestKey(),
      };
      pending_section = 3;
      await call('creator_work/delete', _delete_pending!);
      _delete_pending = null;
      pending_section = null;
    } catch (e) {
      if (e is CreatorWorkspaceException && e.serverRejected) {
        _delete_pending = null;
        pending_section = null;
      }
      error = '$e';
      rethrow;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  /// 当前表单与上次公开快照合并，另一 Tab 的本地修改不会被顺带提交。
  Future<void> update_section(int section) async {
    if (saving || uploading || saved == null) return;
    if (pending_section != null && pending_section != section) return;
    saving = true;
    error = null;
    notifyListeners();
    try {
      if (_pending == null) {
        if (section == 0 && title.text.trim().isEmpty) {
          throw Exception(tr('creator_center.required_title'));
        }
        final categories = section == 1
            ? preferences[WorkEditorStyle.preference_category_id]?.toList() ??
                  <int>[]
            : saved!.category_ids;
        if (categories.isEmpty) {
          throw Exception(tr('creator_center.required_category'));
        }
        final language_id =
            section == 0 && language_code != saved!.language_code
            ? Get.find<LanguageStore>()
                  .find_supported_language_by_code(language_code)
                  ?.id
            : saved!.language_id;
        if (language_id == null) {
          throw Exception(tr('creator_center.config_not_loaded'));
        }
        _pending = {
          'novel_id': novel_id,
          'novel_language_id': saved!.novel_language_id,
          'base_revision_id': saved!.revision_id,
          'request_key': creatorRequestKey(),
          'rights_confirmed': true,
          'release_mode': 1,
          'title': section == 0 ? title.text.trim() : saved!.title,
          'introduction': section == 0
              ? introduction.text
              : saved!.introduction,
          'cover_url': section == 0 ? cover_url ?? '' : saved!.cover_url ?? '',
          'work_language_id': language_id,
          'serialization_status': section == 1
              ? (preferences[PublishedEditorStyle.status_group]?.contains(
                          PublishedEditorStyle.completed_item,
                        ) ==
                        true
                    ? 2
                    : 1)
              : (saved!.is_completed ? 2 : 1),
          'preferences': section == 1
              ? {
                  for (final e in preferences.entries)
                    '${e.key}': e.value.toList(),
                }
              : saved!.preferences,
          'category_snapshot': categories
              .map((id) => {'category_id': id})
              .toList(),
        };
        pending_section = section;
      }
      await call('creator_work/publish_long', _pending!);
      // 更新版本号后才能提交另一 Tab，避免用旧基线覆盖新版本。
      saved = await load_work(novel_id);
      _pending = null;
      pending_section = null;
      if (section == 0) {
        details_dirty = false;
      } else {
        settings_dirty = false;
      }
    } catch (e) {
      if (e is CreatorWorkspaceException && e.serverRejected) {
        _pending = null;
        pending_section = null;
      }
      error = '$e';
      rethrow;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    title.dispose();
    introduction.dispose();
    super.dispose();
  }
}
