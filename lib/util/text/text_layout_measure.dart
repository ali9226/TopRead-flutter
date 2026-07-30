import 'package:flutter/material.dart';

/// 判断指定文本在真实渲染环境中是否需要超过一行。
///
/// [context] 提供当前设备的默认文字样式、语种、文字方向和文字缩放比例。
/// [text] 是需要测量的完整文本。
/// [text_style] 必须与最终 Text 组件使用的样式一致。
/// [max_width] 必须是最终 Text 组件能够获得的真实最大宽度。
bool text_requires_multiple_lines({
  required BuildContext context,
  required String text,
  required TextStyle text_style,
  required double max_width,
}) {
  if (text.isEmpty) {
    return false;
  }
  if (max_width <= 0) {
    return true;
  }

  final TextPainter text_painter = _build_text_painter(
    context: context,
    text: text,
    text_style: text_style,
    max_lines: 1,
    ellipsis: '…',
  )..layout(maxWidth: max_width);

  return text_painter.didExceedMaxLines;
}

/// 测量指定文本完整显示在单行中所需的真实宽度。
///
/// [context] 提供当前设备的默认文字样式、语种、文字方向和文字缩放比例。
/// [text] 是需要测量的完整文本。
/// [text_style] 必须与最终 Text 组件使用的样式一致。
double measure_single_line_text_width({
  required BuildContext context,
  required String text,
  required TextStyle text_style,
}) {
  if (text.isEmpty) {
    return 0;
  }

  final TextPainter text_painter = _build_text_painter(
    context: context,
    text: text,
    text_style: text_style,
    max_lines: 1,
  )..layout();

  return text_painter.width;
}

/// 创建与当前 Text 组件渲染环境一致的文字测量器。
///
/// [context] 用于补全默认样式和读取当前设备文字配置。
/// [text] 是需要测量的文本。
/// [text_style] 是 Text 组件显式指定的样式。
/// [max_lines] 是测量允许的最大行数。
/// [ellipsis] 是超过最大行数时使用的省略符。
TextPainter _build_text_painter({
  required BuildContext context,
  required String text,
  required TextStyle text_style,
  required int max_lines,
  String? ellipsis,
}) {
  final TextStyle effective_text_style = DefaultTextStyle.of(
    context,
  ).style.merge(text_style);

  return TextPainter(
    text: TextSpan(text: text, style: effective_text_style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    locale: Localizations.maybeLocaleOf(context),
    maxLines: max_lines,
    ellipsis: ellipsis,
  );
}
