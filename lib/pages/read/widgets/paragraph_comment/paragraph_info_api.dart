// ignore_for_file: non_constant_identifier_names

import 'package:app/api/post_request.dart';
import 'package:app/api/results_type.dart';

/// 段落信息数据模型。
class ParagraphInfo {
  final int id;
  final int paragraph_no;
  final int start_offset;
  final int end_offset;
  final String content_hash;
  final int comment_count;

  const ParagraphInfo({
    required this.id,
    required this.paragraph_no,
    required this.start_offset,
    required this.end_offset,
    required this.content_hash,
    this.comment_count = 0,
  });

  factory ParagraphInfo.from_json(Map<String, dynamic> json) {
    return ParagraphInfo(
      id: _parse_int(json['id']),
      paragraph_no: _parse_int(json['paragraph_no']),
      start_offset: _parse_int(json['start_offset']),
      end_offset: _parse_int(json['end_offset']),
      content_hash: json['content_hash']?.toString() ?? '',
      comment_count: _parse_int(json['comment_count']),
    );
  }

  static int _parse_int(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}

/// 段落信息 API 服务。
class ParagraphInfoApi {
  /// 查询正文段落信息。
  static Future<List<ParagraphInfo>> get_paragraphs({
    required int body_id,
  }) async {
    final ResultsType<Map<String, dynamic>> results =
        await postRequest<Map<String, dynamic>>(
      path: 'novel_content/get_paragraphs',
      parameter: <String, dynamic>{
        'body_id': body_id,
      },
    );

    if (!results.status || results.content == null) {
      throw Exception(results.message ?? '查询段落信息失败');
    }

    final List<dynamic> paragraphs = results.content!['paragraphs'] ?? [];
    return paragraphs
        .map((e) => ParagraphInfo.from_json(Map<String, dynamic>.from(e)))
        .toList();
  }
}
