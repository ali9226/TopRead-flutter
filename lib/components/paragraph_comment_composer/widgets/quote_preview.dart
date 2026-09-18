// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app/components/paragraph_comment_composer/style.dart';
import 'package:app/config/font_config.dart';
import 'package:app/util/language_util/index.dart';

/// 引用始终只展示三行，完整选文通过无障碍语义保留。
class ParagraphQuotePreview extends StatelessWidget {
  final String quote;
  final bool is_dark;

  const ParagraphQuotePreview({
    super.key,
    required this.quote,
    required this.is_dark,
  });

  @override
  Widget build(BuildContext context) {
    final bool is_cjk = LanguageUtil.is_cjk_language(
      context.locale.languageCode,
    );
    return Semantics(
      label: '${tr('paragraph_comment.quote')}: $quote',
      excludeSemantics: true,
      child: Container(
        key: const ValueKey<String>('paragraph_comment_quote'),
        width: double.infinity,
        padding: const EdgeInsets.only(
          left: ParagraphCommentComposerStyle.quote_padding,
        ),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: ParagraphCommentComposerStyle.secondary_text(is_dark),
              width: ParagraphCommentComposerStyle.quote_border_width,
            ),
          ),
        ),
        child: Text(
          quote,
          maxLines: ParagraphCommentComposerStyle.quote_max_lines,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: ParagraphCommentComposerStyle.secondary_text(is_dark),
            fontSize: is_cjk
                ? ParagraphCommentComposerStyle.quote_font_size_cjk
                : ParagraphCommentComposerStyle.quote_font_size_alphabetic,
            height: is_cjk
                ? ParagraphCommentComposerStyle.line_height_cjk
                : ParagraphCommentComposerStyle.line_height_alphabetic,
            fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
          ),
        ),
      ),
    );
  }
}
