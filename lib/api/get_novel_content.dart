// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:app/api/post_request.dart';
import 'package:app/api/results_type.dart';
import 'package:app/models/novel_content_payload.dart';
import 'package:app/util/encryption/novel_content_cipher.dart';
import 'package:app/util/log_util.dart';
import 'package:app/websocket/websocket_service.dart';

/// 正文数据库记录类型。
enum NovelContentType {
  /// 长篇章节记录。
  chapter('chapter'),

  /// 短篇小说语种记录。
  short_story('short_story');

  /// 后端接口使用的类型值。
  final String value;

  const NovelContentType(this.value);
}

/// 小说正文加载结果。
class NovelContentResult {
  /// 解密后的正文内容。
  final String content;

  /// 当前公开的修订版本ID，用于缓存版本校验。
  final String? published_revision_id;

  /// 正文ID，用于查询段落信息。
  final String? body_id;

  const NovelContentResult({
    required this.content,
    this.published_revision_id,
    this.body_id,
  });
}

/// 根据数据库 ID 获取并解密小说正文。
///
/// [content_type] 指定长篇章节或短篇语种记录。
/// [content_id] 是数据库记录 ID，不接受 CDN URL。
///
/// 返回 [NovelContentResult]，包含正文内容和版本信息。
Future<NovelContentResult> get_novel_content_with_version({
  required NovelContentType content_type,
  required String content_id,
}) async {
  final String normalized_content_id = content_id.trim();
  if (normalized_content_id.isEmpty) {
    return const NovelContentResult(content: '');
  }

  try {
    final String device_token = await WebSocketService()
        .get_or_create_visitor_uuid();
    if (device_token.isEmpty) {
      return const NovelContentResult(content: '');
    }

    final NovelContentCipher cipher = NovelContentCipher.instance;
    final Map<String, String> public_key = await cipher
        .get_public_key_parameters();
    final ResultsType<NovelContentPayload> results =
        await postRequest<NovelContentPayload>(
          path: 'novel_content/read',
          parameter: <String, dynamic>{
            'content_type': content_type.value,
            'content_id': normalized_content_id,
            'device_token': device_token,
            ...public_key,
          },
          showTips: false,
          fromJson: NovelContentPayload.from_json,
        );

    final NovelContentPayload? payload = results.content;
    if (!results.status || payload == null) {
      return const NovelContentResult(content: '');
    }
    if (payload.content_type != content_type.value ||
        payload.content_id != normalized_content_id) {
      throw const FormatException('Novel content identity mismatch');
    }
    final String content = await cipher.decrypt(payload);
    return NovelContentResult(
      content: content,
      published_revision_id: payload.published_revision_id,
      body_id: payload.body_id,
    );
  } catch (error) {
    logUtil(
      msg:
          'TODO 小说正文获取失败: type=${content_type.value}, id=$normalized_content_id, error=$error',
      type: 'e',
    );
    return const NovelContentResult(content: '');
  }
}

/// 根据数据库 ID 获取并解密小说正文（兼容旧接口）。
///
/// [content_type] 指定长篇章节或短篇语种记录。
/// [content_id] 是数据库记录 ID，不接受 CDN URL。
Future<String> get_novel_content({
  required NovelContentType content_type,
  required String content_id,
}) async {
  final result = await get_novel_content_with_version(
    content_type: content_type,
    content_id: content_id,
  );
  return result.content;
}

/// 根据章节数据库 ID 获取长篇正文。
Future<String> get_chapter_content(String chapter_id) {
  return get_novel_content(
    content_type: NovelContentType.chapter,
    content_id: chapter_id,
  );
}

/// 根据章节数据库 ID 获取长篇正文及版本信息。
Future<NovelContentResult> get_chapter_content_with_version(String chapter_id) {
  return get_novel_content_with_version(
    content_type: NovelContentType.chapter,
    content_id: chapter_id,
  );
}

/// 根据小说语种数据库 ID 获取短篇正文。
Future<String> get_short_story_content(String novel_language_id) {
  return get_novel_content(
    content_type: NovelContentType.short_story,
    content_id: novel_language_id,
  );
}

/// 根据小说语种数据库 ID 获取短篇正文及版本信息。
Future<NovelContentResult> get_short_story_content_with_version(
    String novel_language_id) {
  return get_novel_content_with_version(
    content_type: NovelContentType.short_story,
    content_id: novel_language_id,
  );
}
