// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:app/components/paragraph_comment_composer/logic.dart';
import 'package:app/components/paragraph_comment_composer/style.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/util/language_util/index.dart';

/// 带底色的段评输入区；共享逻辑层控制器、焦点、选区和内容长度限制。
class ParagraphCommentComposerInput extends StatelessWidget {
  final ParagraphCommentComposerLogic logic;
  final bool is_dark;

  const ParagraphCommentComposerInput({
    super.key,
    required this.logic,
    required this.is_dark,
  });

  @override
  Widget build(BuildContext context) {
    final bool is_cjk = LanguageUtil.is_cjk_language(
      context.locale.languageCode,
    );
    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(
        ParagraphCommentComposerStyle.input_radius,
      ),
      borderSide: BorderSide.none,
    );
    return TextField(
      key: const ValueKey<String>('paragraph_comment_input'),
      controller: logic.controller,
      focusNode: logic.focus_node,
      readOnly: logic.is_sending,
      onTap: logic.activate_input,
      inputFormatters: <TextInputFormatter>[
        TextInputFormatter.withFunction(logic.limit_content),
      ],
      minLines: ParagraphCommentComposerStyle.input_min_lines,
      maxLines: ParagraphCommentComposerStyle.input_max_lines,
      maxLength: ParagraphCommentComposerStyle.max_content_length,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      textCapitalization: TextCapitalization.sentences,
      keyboardAppearance: is_dark ? Brightness.dark : Brightness.light,
      cursorColor: ColorConstants.themeColor,
      style: TextStyle(
        color: ParagraphCommentComposerStyle.text(is_dark),
        fontSize: is_cjk
            ? ParagraphCommentComposerStyle.input_font_size_cjk
            : ParagraphCommentComposerStyle.input_font_size_alphabetic,
        height: is_cjk
            ? ParagraphCommentComposerStyle.line_height_cjk
            : ParagraphCommentComposerStyle.line_height_alphabetic,
        fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
      ),
      decoration: InputDecoration(
        hintText: tr('paragraph_comment.input_hint'),
        hintStyle: TextStyle(
          color: ParagraphCommentComposerStyle.secondary_text(is_dark),
        ),
        filled: true,
        fillColor: ParagraphCommentComposerStyle.input_background(is_dark),
        border: border,
        enabledBorder: border,
        focusedBorder: border,
        contentPadding: const EdgeInsets.all(
          ParagraphCommentComposerStyle.input_padding,
        ),
        counterText: '',
      ),
    );
  }
}
