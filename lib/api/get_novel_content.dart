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

/// 根据数据库 ID 获取并解密小说正文。
///
/// [content_type] 指定长篇章节或短篇语种记录。
/// [content_id] 是数据库记录 ID，不接受 CDN URL。
Future<String> get_novel_content({
  required NovelContentType content_type,
  required String content_id,
}) async {
  final String normalized_content_id = content_id.trim();
  if (normalized_content_id.isEmpty) return '';

  try {
    final String device_token = await WebSocketService()
        .get_or_create_visitor_uuid();
    if (device_token.isEmpty) return '';

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
    if (!results.status || payload == null) return '';
    if (payload.content_type != content_type.value ||
        payload.content_id != normalized_content_id) {
      throw const FormatException('Novel content identity mismatch');
    }
    return await cipher.decrypt(payload);
  } catch (error) {
    logUtil(
      msg:
          'TODO 小说正文获取失败: type=${content_type.value}, id=$normalized_content_id, error=$error',
      type: 'e',
    );
    return '';
  }
}

/// 根据章节数据库 ID 获取长篇正文。
Future<String> get_chapter_content(String chapter_id) {
  return get_novel_content(
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
