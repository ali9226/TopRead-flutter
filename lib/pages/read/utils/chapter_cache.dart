import 'dart:convert';
import 'dart:io';

/// 长篇小说章节正文磁盘缓存。
///
/// 将接口加载的章节正文缓存到本地临时目录，
/// 避免重复下载，减少网络请求。
///
/// 缓存格式为 JSON，包含版本标识用于检测内容更新。
class ChapterCache {
  ChapterCache._();

  /// 缓存目录。
  static Directory get _directory =>
      Directory('${Directory.systemTemp.path}/read_chapter_content_cache');

  /// 缓存有效期。
  static const Duration _ttl = Duration(days: 7);

  /// 将章节数据库 ID 转换成可安全落盘的文件名。
  static String _file_name(String chapter_id) {
    final String encoded = Uri.encodeComponent(
      chapter_id,
    ).replaceAll('%', '_').replaceAll('.', '_').replaceAll('-', '_');
    if (encoded.length <= 180) {
      return '$encoded.json';
    }
    return '${encoded.substring(0, 180)}_${chapter_id.hashCode.abs()}.json';
  }

  /// 获取指定章节数据库 ID 对应的缓存文件。
  static File _file(String chapter_id) {
    return File('${_directory.path}/${_file_name(chapter_id)}');
  }

  /// 从磁盘缓存读取章节正文。
  ///
  /// [chapter_id] 章节ID。
  /// [published_revision_id] 当前公开的修订ID，用于检测内容是否更新。
  ///
  /// 返回缓存文本；缓存不存在、过期、版本不匹配或读取失败时返回 null。
  static Future<String?> read(
    String chapter_id, {
    String? published_revision_id,
  }) async {
    try {
      final File file = _file(chapter_id);
      if (!await file.exists()) {
        return null;
      }

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

  /// 将章节正文写入磁盘缓存。
  ///
  /// [chapter_id] 章节ID。
  /// [content] 正文内容。
  /// [published_revision_id] 当前公开的修订ID，用于后续版本校验。
  static Future<void> write(
    String chapter_id,
    String content, {
    String? published_revision_id,
  }) async {
    if (chapter_id.isEmpty || content.isEmpty) {
      return;
    }

    try {
      final Directory directory = _directory;
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final File file = _file(chapter_id);
      final Map<String, dynamic> data = {
        'version': published_revision_id,
        'content': content,
        'cached_at': DateTime.now().toIso8601String(),
      };
      await file.writeAsString(jsonEncode(data), flush: false);
    } catch (_) {
      // 缓存失败不影响阅读。
    }
  }

  /// 清除指定章节的缓存。
  static Future<void> clear(String chapter_id) async {
    try {
      final File file = _file(chapter_id);
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
