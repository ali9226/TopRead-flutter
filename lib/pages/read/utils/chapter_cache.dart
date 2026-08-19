import 'dart:io';

/// 长篇小说章节正文磁盘缓存。
///
/// 将远程加载的章节正文缓存到本地临时目录，
/// 避免重复下载，减少网络请求。
class ChapterCache {
  ChapterCache._();

  /// 缓存目录。
  static Directory get _directory =>
      Directory('${Directory.systemTemp.path}/read_chapter_content_cache');

  /// 缓存有效期。
  static const Duration _ttl = Duration(days: 7);

  /// 将章节正文 url 转换成可安全落盘的文件名。
  static String _file_name(String content_url) {
    final String encoded = Uri.encodeComponent(
      content_url,
    ).replaceAll('%', '_').replaceAll('.', '_').replaceAll('-', '_');
    if (encoded.length <= 180) {
      return '$encoded.txt';
    }
    return '${encoded.substring(0, 180)}_${content_url.hashCode.abs()}.txt';
  }

  /// 获取指定章节正文 url 对应的缓存文件。
  static File _file(String content_url) {
    return File('${_directory.path}/${_file_name(content_url)}');
  }

  /// 从磁盘缓存读取章节正文。
  ///
  /// 返回缓存文本；缓存不存在、过期或读取失败时返回 null。
  static Future<String?> read(String content_url) async {
    try {
      final File file = _file(content_url);
      if (!await file.exists()) {
        return null;
      }

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

  /// 将章节正文写入磁盘缓存。
  static Future<void> write(String content_url, String content) async {
    if (content_url.isEmpty || content.isEmpty) {
      return;
    }

    try {
      final Directory directory = _directory;
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final File file = _file(content_url);
      await file.writeAsString(content, flush: false);
    } catch (_) {
      // 缓存失败不影响阅读。
    }
  }
}
