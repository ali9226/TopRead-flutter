// ignore_for_file: non_constant_identifier_names

import 'package:app/api/post_request.dart';
import 'package:app/models/paragraph_anchor.dart';

/// 段落元数据包含完整正文摘要，用于阻止旧缓存与新版本段落错配。
class ParagraphMetadata {
  final String body_id;
  final String published_revision_id;
  final String content_hash;
  final List<ParagraphAnchor> paragraphs;

  const ParagraphMetadata({
    required this.body_id,
    required this.published_revision_id,
    required this.content_hash,
    required this.paragraphs,
  });

  factory ParagraphMetadata.from_json(
    Map<String, dynamic> json,
  ) => ParagraphMetadata(
    body_id: json['body_id'].toString(),
    published_revision_id: json['published_revision_id'].toString(),
    content_hash: json['content_hash']?.toString() ?? '',
    paragraphs: (json['paragraphs'] as List<dynamic>? ?? [])
        .map(
          (item) =>
              ParagraphAnchor.from_json(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false),
  );
}

/// 查询当前语种的公开正文段落，不读取草稿或自动迁移历史评论。
Future<ParagraphMetadata?> get_short_story_paragraphs(
  String novel_language_id,
) async {
  final results = await postRequest<ParagraphMetadata>(
    path: 'novel_content/get_paragraphs',
    parameter: {'novel_language_id': novel_language_id},
    showTips: false,
    fromJson: ParagraphMetadata.from_json,
  );
  return results.status ? results.content : null;
}

/// 发送选区段评，返回事务提交后的段落评论数；失败返回 null。
Future<int?> create_paragraph_comment({
  required String paragraph_id,
  required String content,
  required List<String> images,
  required int selection_start,
  required int selection_end,
}) async {
  final results = await postRequest<Map<String, dynamic>>(
    path: 'paragraph_comment/create',
    parameter: {
      'paragraph_id': paragraph_id,
      'content': content,
      'images': images,
      'selection_start': selection_start,
      'selection_end': selection_end,
    },
    showTips: false,
    fromJson: (json) => json,
  );
  if (!results.status || results.content == null) return null;
  return int.tryParse(results.content!['comment_count'].toString());
}
