import 'dart:convert';
import 'dart:io';

/// 短篇小说正文磁盘缓存。
///
/// 将正文代理接口加载的内容缓存到本地临时目录，
/// 避免重复下载，减少网络请求。
///
/// 缓存格式为 JSON，包含版本标识用于检测内容更新。
class ShortStoryContentCache {
  ShortStoryContentCache._();

  /// 缓存目录。
  static Directory get _directory =>
      Directory('${Directory.systemTemp.path}/short_story_read_content_cache');

  /// 缓存有效期。
  static const Duration _ttl = Duration(days: 7);

  /// 把小说语种数据库 ID 转成安全的缓存文件名。
  static String _file_name(String novel_language_id) {
    final String encoded = Uri.encodeComponent(
      novel_language_id,
    ).replaceAll('%', '_').replaceAll('.', '_').replaceAll('-', '_');
    if (encoded.length <= 180) return '$encoded.json';
    return '${encoded.substring(0, 180)}_${novel_language_id.hashCode.abs()}.json';
  }

  /// 获取缓存文件。
  static File _file(String novel_language_id) {
    return File('${_directory.path}/${_file_name(novel_language_id)}');
  }

  /// 从磁盘缓存读取正文。
  ///
  /// [novel_language_id] 小说语种ID。
  /// [published_revision_id] 当前公开的修订ID，用于检测内容是否更新。
  ///
  /// 返回缓存文本；缓存不存在、过期、版本不匹配或读取失败时返回 null。
  static Future<String?> read(
    String novel_language_id, {
    String? published_revision_id,
  }) async {
    try {
      final File file = _file(novel_language_id);
      if (!await file.exists()) return null;

      final DateTime modified = await file.lastModified();
      if (DateTime.now().difference(modified) > _ttl) {
        await file.delete();
        return null;
      }

      final String raw = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(raw);

      // 版本校验：如果提供了版本ID，检查是否匹配
      if (published_revision_id != null &&
          data['version'] != null &&
          data['version'] != published_revision_id) {
        await file.delete();
        return null;
      }

      return data['content'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// 将正文写入磁盘缓存。
  ///
  /// [novel_language_id] 小说语种ID。
  /// [text] 正文内容。
  /// [published_revision_id] 当前公开的修订ID，用于后续版本校验。
  static Future<void> write(
    String novel_language_id,
    String text, {
    String? published_revision_id,
  }) async {
    if (novel_language_id.isEmpty || text.isEmpty) return;

    try {
      final Directory directory = _directory;
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final File file = _file(novel_language_id);
      final Map<String, dynamic> data = {
        'version': published_revision_id,
        'content': text,
        'cached_at': DateTime.now().toIso8601String(),
      };
      await file.writeAsString(jsonEncode(data), flush: false);
    } catch (_) {
      // 缓存失败不影响阅读。
    }
  }

  /// 清除指定小说的缓存。
  static Future<void> clear(String novel_language_id) async {
    try {
      final File file = _file(novel_language_id);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // 清除失败不影响阅读。
    }
  }

  /// 清除所有缓存。
  static Future<void> clearAll() async {
    try {
      final Directory directory = _directory;
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    } catch (_) {
      // 清除失败不影响阅读。
    }
  }
}
