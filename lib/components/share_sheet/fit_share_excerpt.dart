// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;

import 'package:app/models/share_excerpt.dart';
import 'package:flutter/material.dart';

import 'selection_poster_style.dart';

/// 已按真实海报宽高量出的富文本，不以固定字数假定英文和CJK能放相同内容。
class FittedShareExcerpt {
  const FittedShareExcerpt({
    required this.span,
    required this.selection_truncated,
  });
  final TextSpan span;
  final bool selection_truncated;
}

/// 所选文字最优先，其次完整所在段，最后利用剩余空间加入浅色相邻段。
FittedShareExcerpt fit_share_excerpt({
  required ShareExcerpt excerpt,
  required TextStyle style,
  required Color selected_color,
  required Color context_color,
  required double width,
  required double height,
  required TextDirection direction,
  required TextScaler scaler,
  required Locale locale,
  required double truncation_reserve,
}) {
  final selected_style = SelectionPosterStyle.selected_style(
    style,
  ).copyWith(color: selected_color);
  final context_style = SelectionPosterStyle.context_style(
    style,
  ).copyWith(color: context_color);
  final selection = excerpt.selected_text.characters.toList(growable: false);
  final before = excerpt.before_text.characters.toList(growable: false);
  final after = excerpt.after_text.characters.toList(growable: false);
  final previous = excerpt.previous_paragraph.characters.toList(
    growable: false,
  );
  final next = excerpt.next_paragraph.characters.toList(growable: false);
  final safe_width = math.max(1.0, width);
  final safe_height = math.max(
    0.0,
    height - SelectionPosterStyle.measurement_safety,
  );

  TextSpan context(String text) => TextSpan(text: text, style: context_style);
  TextSpan chosen(String text) => TextSpan(text: text, style: selected_style);
  TextSpan span(List<InlineSpan> children) =>
      TextSpan(style: style, children: children);
  bool fits(TextSpan text, {double reserve = 0}) {
    final painter = TextPainter(
      text: text,
      textDirection: direction,
      textScaler: scaler,
      locale: locale,
    )..layout(maxWidth: safe_width);
    final result = painter.height <= math.max(0, safe_height - reserve);
    painter.dispose();
    return result;
  }

  // TODO 长选文先扩高海报；达到导出高度上限才同时保留头尾，并显式标明省略。
  if (selection.length > SelectionPosterStyle.selection_working_limit ||
      !fits(span([chosen(excerpt.selected_text)]))) {
    TextSpan abbreviated(int count) {
      final front = (count * SelectionPosterStyle.selection_head_ratio).ceil();
      final back = count - front;
      return span([
        chosen(selection.take(front).join()),
        context(' ${SelectionPosterStyle.omission} '),
        if (back > 0) chosen(selection.skip(selection.length - back).join()),
      ]);
    }

    final count = _maximum_fitting_count(
      math.min(selection.length, SelectionPosterStyle.selection_working_limit),
      (count) => fits(abbreviated(count), reserve: truncation_reserve),
    );
    return FittedShareExcerpt(
      span: abbreviated(count),
      selection_truncated: true,
    );
  }

  TextSpan primary(int before_count, int after_count) => span([
    if (before_count < before.length) context(SelectionPosterStyle.omission),
    if (before_count > 0)
      context(before.skip(before.length - before_count).join()),
    chosen(excerpt.selected_text),
    if (after_count > 0) context(after.take(after_count).join()),
    if (after_count < after.length) context(SelectionPosterStyle.omission),
  ]);

  var before_count = before.length;
  var after_count = after.length;
  if (before_count + after_count >
          SelectionPosterStyle.context_character_limit ||
      !fits(primary(before_count, after_count))) {
    if (!fits(primary(0, 0))) {
      return FittedShareExcerpt(
        span: span([chosen(excerpt.selected_text)]),
        selection_truncated: false,
      );
    }
    final total = _maximum_fitting_count(
      math.min(
        before.length + after.length,
        SelectionPosterStyle.context_character_limit,
      ),
      (count) {
        final allocation = _balanced_counts(count, before.length, after.length);
        return fits(primary(allocation.$1, allocation.$2));
      },
    );
    final allocation = _balanced_counts(total, before.length, after.length);
    return FittedShareExcerpt(
      span: primary(allocation.$1, allocation.$2),
      selection_truncated: false,
    );
  }

  final selected_paragraph = primary(before_count, after_count);
  TextSpan surrounded(int previous_count, int next_count) => span([
    if (previous_count > 0) ...[
      if (previous_count < previous.length)
        context(SelectionPosterStyle.omission),
      context(previous.skip(previous.length - previous_count).join()),
      context(SelectionPosterStyle.paragraph_gap),
    ],
    selected_paragraph,
    if (next_count > 0) ...[
      context(SelectionPosterStyle.paragraph_gap),
      context(next.take(next_count).join()),
      if (next_count < next.length) context(SelectionPosterStyle.omission),
    ],
  ]);
  final neighbours = _maximum_fitting_count(
    math.min(
      previous.length + next.length,
      SelectionPosterStyle.context_character_limit,
    ),
    (count) {
      final allocation = _balanced_counts(count, previous.length, next.length);
      return fits(surrounded(allocation.$1, allocation.$2));
    },
  );
  final allocation = _balanced_counts(neighbours, previous.length, next.length);
  return FittedShareExcerpt(
    span: surrounded(allocation.$1, allocation.$2),
    selection_truncated: false,
  );
}

/// 二分查找可容纳的语境数量，复杂度与正文长度无关。
int _maximum_fitting_count(int maximum, bool Function(int) fits) {
  var low = 0, high = maximum;
  while (low < high) {
    final middle = (low + high + 1) ~/ 2;
    if (fits(middle)) {
      low = middle;
    } else {
      high = middle - 1;
    }
  }
  return low;
}

/// 前后公平分配剩余位置，一侧较短时将空余留给另一侧。
(int, int) _balanced_counts(int count, int before, int after) {
  var left = math.min(before, (count + 1) ~/ 2);
  final right = math.min(after, count - left);
  left = math.min(before, count - right);
  return (left, right);
}
