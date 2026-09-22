// ignore_for_file: non_constant_identifier_names

import 'package:app/components/paragraph_selection/index.dart';
import 'package:app/config/font_config.dart';
import 'package:app/stores/novel_reading_store.dart';
import 'package:app/util/language_util/index.dart';
import 'package:flutter/material.dart';

import 'style.dart';

/// 章节标题保持普通文字，正文复用短篇的原生选区、操作菜单和段评气泡。
class ReaderParagraphItem extends StatelessWidget {
  const ReaderParagraphItem({
    super.key,
    required this.item,
    required this.is_dark,
    required this.body_font_size,
    required this.text_color,
    this.on_comment,
    this.on_comments,
    this.on_share,
    this.on_selection_changed,
    this.on_tap_position,
  });

  final ReadingContentItem item;
  final bool is_dark;
  final double body_font_size;
  final Color text_color;
  final ValueChanged<TextSelection>? on_comment;
  final VoidCallback? on_comments;
  final ValueChanged<TextSelection>? on_share;
  final ValueChanged<bool>? on_selection_changed;
  final ValueChanged<Offset>? on_tap_position;

  @override
  Widget build(BuildContext context) {
    final is_cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    final style = TextStyle(
      color: text_color,
      fontSize: item.is_title
          ? ContentStyle.reading_title_font_size
          : body_font_size,
      height: is_cjk
          ? ContentStyle.reading_paragraph_height_cjk
          : ContentStyle.reading_paragraph_height_alphabetic,
      fontWeight: FontConfig.adjustedWeight(
        item.is_title ? FontWeight.w500 : FontWeight.w400,
      ),
    );
    if (item.is_title || on_comment == null) {
      return SelectionContainer.disabled(child: Text(item.text, style: style));
    }
    return ParagraphSelection(
      text: item.text,
      start_offset: item.start_offset,
      text_style: style,
      is_dark: is_dark,
      paragraph_id: item.anchor?.id,
      comment_count: item.anchor?.comment_count ?? 0,
      on_comment: on_comment!,
      on_share: on_share,
      on_comment_count_tap: on_comments,
      on_selection_changed: on_selection_changed,
      on_tap_position: on_tap_position,
    );
  }
}
