// ignore_for_file: non_constant_identifier_names

import 'package:app/models/paragraph_text_selection.dart';
import 'package:flutter/widgets.dart';

/// 海报需要的有限正文上下文。高亮始终依赖准确偏移，重复词不会被错误全部标黑。
class ShareExcerpt {
  const ShareExcerpt({
    required this.selected_text,
    this.before_text = '',
    this.after_text = '',
    this.previous_paragraph = '',
    this.next_paragraph = '',
  });

  final String selected_text;
  final String before_text;
  final String after_text;
  final String previous_paragraph;
  final String next_paragraph;

  /// 兼容旧分享入口：没有原文坐标时只高亮其真实选文，不通过搜词猜测上下文。
  factory ShareExcerpt.selected_only(String text) =>
      ShareExcerpt(selected_text: text);

  /// 从当前可见作用域取选中段和最多前后各一段；普通局部选区只使用所在段。
  static ShareExcerpt? from_selection({
    required String paragraph_text,
    required int paragraph_start,
    required TextSelection selection,
  }) {
    if (!selection.isValid || selection.isCollapsed) return null;
    if (selection is ParagraphTextSelection) {
      final source = selection.source_content;
      final start = selection.content_start - selection.source_offset;
      final end = selection.content_end - selection.source_offset;
      final paragraph_local = paragraph_start - selection.source_offset;
      if (source != null &&
          start >= 0 &&
          end <= source.length &&
          start < end &&
          source.substring(start, end) == selection.selected_text &&
          paragraph_local >= 0 &&
          paragraph_local + paragraph_text.length <= source.length &&
          source.substring(
                paragraph_local,
                paragraph_local + paragraph_text.length,
              ) ==
              paragraph_text) {
        return _from_source(source, start, end);
      }
      if (selection.selected_text.trim().isEmpty) return null;
      return ShareExcerpt.selected_only(selection.selected_text);
    }
    if (selection.start < 0 || selection.end > paragraph_text.length) {
      return null;
    }
    return _from_source(paragraph_text, selection.start, selection.end);
  }

  /// 保留原始CRLF/缩进及选文，邻段只用于浅色语境；不跨越可见作用域边界。
  static ShareExcerpt? _from_source(String source, int start, int end) {
    // 原生选择一般已在字形边界；程序化选区也不能切断表情或组合字符。
    var boundary = 0;
    var safe_start = start;
    var safe_end = end;
    for (final character in source.characters) {
      final next = boundary + character.length;
      if (start > boundary && start < next) safe_start = boundary;
      if (end > boundary && end < next) safe_end = next;
      boundary = next;
      if (boundary >= end) break;
    }
    final selected = source.substring(safe_start, safe_end);
    if (selected.trim().isEmpty) return null;
    final paragraphs = RegExp(r'[^\r\n]+')
        .allMatches(source)
        .where((match) => match.group(0)!.trim().isNotEmpty)
        .toList(growable: false);
    final first = paragraphs.indexWhere(
      (match) => match.end > safe_start && match.start < safe_end,
    );
    if (first < 0) return ShareExcerpt.selected_only(selected);
    var last = first;
    while (last + 1 < paragraphs.length &&
        paragraphs[last + 1].start < safe_end) {
      last++;
    }
    final primary_start = paragraphs[first].start < safe_start
        ? paragraphs[first].start
        : safe_start;
    final primary_end = paragraphs[last].end > safe_end
        ? paragraphs[last].end
        : safe_end;
    return ShareExcerpt(
      selected_text: selected,
      before_text: source.substring(primary_start, safe_start),
      after_text: source.substring(safe_end, primary_end),
      previous_paragraph: first > 0 ? paragraphs[first - 1].group(0)! : '',
      next_paragraph: last + 1 < paragraphs.length
          ? paragraphs[last + 1].group(0)!
          : '',
    );
  }
}
