// ignore_for_file: non_constant_identifier_names

import 'package:app/models/paragraph_anchor.dart';

/// 保留原始正文偏移的可见段落，不使用过滤后的列表索引猜测数据库 ID。
class StoryParagraph {
  final String text;
  final int start_offset;
  final int end_offset;
  final ParagraphAnchor? anchor;

  const StoryParagraph({
    required this.text,
    required this.start_offset,
    required this.end_offset,
    this.anchor,
  });
}
