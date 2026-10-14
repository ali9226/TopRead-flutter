// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:app/pages/comics/editor/models.dart';
import 'package:app/util/storage_util/index.dart';

/// 漫画编辑器本地草稿存储。
///
/// 编辑过程中防抖写入 GetStorage，异常退出后可恢复未保存内容。
/// 按漫画 id 隔离：新作统一使用 `new` 作为键后缀。
class ComicDraftStorage {
  const ComicDraftStorage._();

  /// 键前缀，与其它本地缓存隔离。
  static const String _key_prefix = 'comics_editor_draft_';

  /// 组装草稿存储键。
  ///
  /// [comic_id] 为 0 时表示未创建的新作。
  static String draft_key(int comic_id) =>
      '$_key_prefix${comic_id > 0 ? comic_id : 'new'}';

  /// 写入草稿。
  ///
  /// [comic_id] 作品 id（0 为新作）。
  /// [data] 当前编辑器完整状态。
  static Future<void> save(int comic_id, ComicEditorData data) async {
    try {
      await StorageUtil.saveData(draft_key(comic_id), jsonEncode(data.to_draft_json()));
    } catch (_) {
      // 本地空间不足等异常不阻断编辑，草稿尽力而为。
    }
  }

  /// 读取草稿，损坏或不存在时返回 null。
  ///
  /// [comic_id] 作品 id（0 为新作）。
  static Future<ComicEditorData?> load(int comic_id) async {
    try {
      final String? raw = await StorageUtil.getData(draft_key(comic_id));
      if (raw == null || raw.trim().isEmpty) return null;
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return ComicEditorData.from_draft_json(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      return null;
    }
  }

  /// 删除草稿。
  ///
  /// [comic_id] 作品 id（0 为新作）。
  static Future<void> clear(int comic_id) =>
      StorageUtil.removeData(draft_key(comic_id));
}
