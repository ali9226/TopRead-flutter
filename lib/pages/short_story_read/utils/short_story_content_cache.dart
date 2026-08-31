import 'dart:io';

/// 短篇小说正文磁盘缓存。
///
/// 将正文代理接口加载的内容缓存到本地临时目录，
/// 避免重复下载，减少网络请求。
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
    if (encoded.length <= 180) return '$encoded.txt';
    return '${encoded.substring(0, 180)}_${novel_language_id.hashCode.abs()}.txt';
  }

  /// 获取缓存文件。
  static File _file(String novel_language_id) {
    return File('${_directory.path}/${_file_name(novel_language_id)}');
  }

  /// 从磁盘缓存读取正文。
  ///
  /// 返回缓存文本；缓存不存在、过期或读取失败时返回 null。
  static Future<String?> read(String novel_language_id) async {
    try {
      final File file = _file(novel_language_id);
      if (!await file.exists()) return null;

      final DateTime modified = await file.lastModified();
      if (DateTime.now().difference(modified) > _ttl) {
        await file.delete();
        return null;
      }

      return await file.readAsString();
    } catch (_) {
      return null;
    }
  }

  /// 将正文写入磁盘缓存。
  static Future<void> write(String novel_language_id, String text) async {
    if (novel_language_id.isEmpty || text.isEmpty) return;

    try {
      final Directory directory = _directory;
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final File file = _file(novel_language_id);
      await file.writeAsString(text, flush: false);
    } catch (_) {
      // 缓存失败不影响阅读。
    }
  }
}
