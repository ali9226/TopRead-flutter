// ignore_for_file: non_constant_identifier_names

/// 指向具体已发布正文版本的段落锚点，偏移统一使用 UTF-16 闭开区间。
class ParagraphAnchor {
  final String id;
  final int paragraph_no;
  final int start_offset;
  final int end_offset;
  final String content_hash;
  final int comment_count;

  const ParagraphAnchor({
    required this.id,
    required this.paragraph_no,
    required this.start_offset,
    required this.end_offset,
    required this.content_hash,
    required this.comment_count,
  });

  factory ParagraphAnchor.from_json(Map<String, dynamic> json) {
    return ParagraphAnchor(
      id: json['id'].toString(),
      paragraph_no: int.parse(json['paragraph_no'].toString()),
      start_offset: int.parse(json['start_offset'].toString()),
      end_offset: int.parse(json['end_offset'].toString()),
      content_hash: json['content_hash']?.toString() ?? '',
      comment_count: int.tryParse(json['comment_count'].toString()) ?? 0,
    );
  }

  /// 发送成功后使用服务端计数，避免把失败请求计入段评数量。
  ParagraphAnchor with_comment_count(int count) => ParagraphAnchor(
    id: id,
    paragraph_no: paragraph_no,
    start_offset: start_offset,
    end_offset: end_offset,
    content_hash: content_hash,
    comment_count: count,
  );
}
