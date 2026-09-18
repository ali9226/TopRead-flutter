// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';

import '../logic.dart';
import '../style.dart';
import 'composer_actions.dart';
import 'composer_input.dart';
import 'image_strip.dart';
import 'quote_preview.dart';

/// 键盘上方的编辑区域；受限高度下只滚动内容，底部输入面板保持独立。
class ParagraphCommentComposerBody extends StatelessWidget {
  const ParagraphCommentComposerBody({
    required this.logic,
    required this.quote,
    required this.is_dark,
    super.key,
  });

  final ParagraphCommentComposerLogic logic;
  final String quote;
  final bool is_dark;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    primary: false,
    padding: const EdgeInsets.symmetric(
      horizontal: ParagraphCommentComposerStyle.horizontal_padding,
      vertical: ParagraphCommentComposerStyle.vertical_padding,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ParagraphQuotePreview(quote: quote, is_dark: is_dark),
        const SizedBox(height: ParagraphCommentComposerStyle.section_spacing),
        ParagraphCommentComposerInput(logic: logic, is_dark: is_dark),
        const SizedBox(height: ParagraphCommentComposerStyle.section_spacing),
        if (logic.images.isNotEmpty) ...<Widget>[
          ParagraphCommentImageStrip(logic: logic, is_dark: is_dark),
          const SizedBox(height: ParagraphCommentComposerStyle.section_spacing),
        ],
        if (logic.error_key != null)
          Text(
            tr(logic.error_key!),
            key: const ValueKey<String>('paragraph_comment_error'),
            style: TextStyle(
              color: ColorConstants.dangerColor,
              fontSize: ParagraphCommentComposerStyle.error_font_size,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
            ),
          ),
        ParagraphCommentComposerActions(logic: logic, is_dark: is_dark),
      ],
    ),
  );
}
