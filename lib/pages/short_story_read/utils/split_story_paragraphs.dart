// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:app/models/paragraph_anchor.dart';
import 'package:app/pages/short_story_read/models/story_paragraph.dart';

/// 与服务端拆段规则保持一致，保留空行、缩进、CRLF 和表情的 UTF-16 偏移。
/// [content_offset] 用于去掉首尾空白的阅读预览，恢复其在完整正文的位置。
List<StoryParagraph> split_story_paragraphs(
  String content, {
  List<ParagraphAnchor> anchors = const [],
  int content_offset = 0,
}) {
  final by_start = {for (final anchor in anchors) anchor.start_offset: anchor};
  return RegExp(r'[^\r\n]+')
      .allMatches(content)
      .where((match) => match.group(0)!.trim().isNotEmpty)
      .map((match) {
        final text = match.group(0)!;
        final start = content_offset + match.start;
        final end = content_offset + match.end;
        final candidate = by_start[start];
        // 被预览截断的段落仍可阅读，但不能误挂整段的评论或选区。
        final anchor =
            candidate != null &&
                candidate.end_offset == end &&
                candidate.content_hash ==
                    sha256.convert(utf8.encode(text)).toString()
            ? candidate
            : null;
        return StoryParagraph(
          text: text,
          start_offset: start,
          end_offset: end,
          anchor: anchor,
        );
      })
      .toList(growable: false);
}
