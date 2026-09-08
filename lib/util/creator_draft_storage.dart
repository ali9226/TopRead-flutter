// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:app/pages/author_center/models/creator_work.dart';
import 'package:app/util/storage_util/index.dart';

/// 创作者草稿本地存储工具。
///
/// 使用 GetStorage 持久化草稿数据，支持保存、读取、删除操作。
class CreatorDraftStorage {
  const CreatorDraftStorage._();

  /// 存储键：草稿列表 JSON 字符串。
  static const String _key_drafts = 'creator_drafts';

  /// 保存草稿到本地。
  ///
  /// 如果已存在相同 [local_id] 的草稿则更新，否则新增。
  ///
  /// [draft] 要保存的草稿对象。
  static Future<void> saveDraft(CreatorWorkDraft draft) async {
    final List<CreatorWorkDraft> drafts = await getAllDrafts();

    // 查找并更新已有草稿。
    final int index =
        drafts.indexWhere((d) => d.local_id == draft.local_id);
    if (index >= 0) {
      drafts[index] = draft;
    } else {
      drafts.insert(0, draft);
    }

    // 按 update_time 降序排列。
    drafts.sort(
        (a, b) => b.update_time.compareTo(a.update_time));

    // 序列化并保存。
    final List<Map<String, dynamic>> jsonList =
        drafts.map((d) => d.to_json()).toList();
    await StorageUtil.saveData(_key_drafts, jsonEncode(jsonList));
  }

  /// 读取所有本地草稿。
  static Future<List<CreatorWorkDraft>> getAllDrafts() async {
    final String? jsonStr = await StorageUtil.getData(_key_drafts);
    if (jsonStr == null || jsonStr.isEmpty) {
      return <CreatorWorkDraft>[];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList
          .map((e) => CreatorWorkDraft.from_json(
              e is Map<String, dynamic> ? e : <String, dynamic>{}))
          .toList();
    } catch (_) {
      return <CreatorWorkDraft>[];
    }
  }

  /// 获取最新的草稿（按 update_time 降序）。
  static Future<CreatorWorkDraft?> getLatestDraft() async {
    final List<CreatorWorkDraft> drafts = await getAllDrafts();
    if (drafts.isEmpty) return null;
    return drafts.first;
  }

  /// 删除指定草稿。
  ///
  /// [local_id] 要删除的草稿的本地 ID。
  static Future<void> deleteDraft(String local_id) async {
    final List<CreatorWorkDraft> drafts = await getAllDrafts();
    drafts.removeWhere((d) => d.local_id == local_id);

    final List<Map<String, dynamic>> jsonList =
        drafts.map((d) => d.to_json()).toList();
    await StorageUtil.saveData(_key_drafts, jsonEncode(jsonList));
  }

  /// 清除所有草稿。
  static Future<void> clearAll() async {
    await StorageUtil.removeData(_key_drafts);
  }
}
