// ignore_for_file: non_constant_identifier_names

import 'package:app/models/paragraph_anchor.dart';

/// 保留原始正文偏移的可见段落，不使用过滤后的列表索引猜测数据库 ID。
class StoryParagraph {
  /// 保留缩进的原始段落文字，选区与摘要均以此字符串为准。
  final String text;

  /// 在完整正文中的 UTF-16 起始偏移，包含该位置。
  final int start_offset;

  /// 在完整正文中的 UTF-16 结束偏移，不包含该位置。
  final int end_offset;

  /// 仅在正文偏移与摘要全部匹配时绑定的服务端段落信息。
  final ParagraphAnchor? anchor;

  const StoryParagraph({
    required this.text,
    required this.start_offset,
    required this.end_offset,
    this.anchor,
  });
}
