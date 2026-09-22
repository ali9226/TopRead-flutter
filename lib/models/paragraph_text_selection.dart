// ignore_for_file: non_constant_identifier_names

import 'package:flutter/services.dart';

/// 正文连续选区：局部偏移属于最后选中的段落，完整引用保留原文换行。
///
/// [baseOffset] 与 [extentOffset] 继续兼容现有段落操作；[content_start] 与
/// [content_end] 使用当前章节或短篇正文的 UTF-16 闭开区间。
class ParagraphTextSelection extends TextSelection {
  /// 包含所有选中段落的原始文字，用于复制、分享及段评引用。
  final String selected_text;

  /// 完整正文中第一个选中字符的 UTF-16 偏移。
  final int content_start;

  /// 完整正文中最后一个选中字符之后的 UTF-16 偏移。
  final int content_end;

  const ParagraphTextSelection({
    required super.baseOffset,
    required super.extentOffset,
    required this.selected_text,
    required this.content_start,
    required this.content_end,
    super.affinity,
    super.isDirectional,
  });

  /// 校验完整正文引用与末段局部选区一致，拒绝过期或跨正文的选区。
  ///
  /// 跨段选区的 [content_end] 可能超出 [paragraph_end]（选区从前段延伸到末段），
  /// 此时 [content_start] < [paragraph_start]，末段局部偏移从 0 开始。
  bool matches_paragraph({
    required String content,
    required int paragraph_start,
    required int paragraph_end,
  }) {
    if (!isValid ||
        isCollapsed ||
        paragraph_start < 0 ||
        paragraph_start >= paragraph_end ||
        paragraph_end > content.length ||
        content_start < 0 ||
        content_start >= content_end ||
        content_end <= paragraph_start ||
        content_end > content.length) {
      return false;
    }
    final local_start = content_start > paragraph_start
        ? content_start - paragraph_start
        : 0;
    // 跨段选区 content_end > paragraph_end 时，末段局部 end 只覆盖段内部分。
    final local_end = content_end > paragraph_end
        ? paragraph_end - paragraph_start
        : content_end - paragraph_start;
    return start == local_start &&
        end == local_end &&
        selected_text == content.substring(content_start, content_end);
  }
}

/// 跨段选区返回完整引用；普通段内选区沿用 Flutter 的文本截取规则。
String selected_paragraph_text(String text, TextSelection selection) =>
    selection is ParagraphTextSelection
    ? selection.selected_text
    : selection.textInside(text);
