// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app/components/paragraph_comment_composer/logic.dart';
import 'package:app/components/paragraph_comment_composer/style.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/util/language_util/index.dart';

/// 图片/表情入口靠左，发送按钮靠右，共享输入框的点击区域以避免误失焦。
class ParagraphCommentComposerActions extends StatelessWidget {
  final ParagraphCommentComposerLogic logic;
  final bool is_dark;

  const ParagraphCommentComposerActions({
    super.key,
    required this.logic,
    required this.is_dark,
  });

  @override
  Widget build(BuildContext context) {
    final bool is_cjk = LanguageUtil.is_cjk_language(
      context.locale.languageCode,
    );
    final Color icon_color = ParagraphCommentComposerStyle.text(is_dark);
    return Row(
      children: <Widget>[
        IconButton(
          key: const ValueKey<String>('paragraph_comment_add_image'),
          tooltip: tr('paragraph_comment.add_image'),
          onPressed: logic.is_busy ? null : logic.add_images,
          color: icon_color,
          iconSize: ParagraphCommentComposerStyle.action_icon_size,
          constraints: const BoxConstraints.tightFor(
            width: ParagraphCommentComposerStyle.action_size,
            height: ParagraphCommentComposerStyle.action_size,
          ),
          icon: logic.is_picking || logic.is_uploading
              ? SizedBox.square(
                  dimension: ParagraphCommentComposerStyle.progress_size,
                  child: CircularProgressIndicator(
                    color: ColorConstants.themeColor,
                    strokeWidth: ParagraphCommentComposerStyle.progress_stroke,
                  ),
                )
              : const Icon(Icons.image_outlined),
        ),
        IconButton(
          key: const ValueKey<String>('paragraph_comment_toggle_emoji'),
          tooltip: tr(
            logic.show_emoji
                ? 'paragraph_comment.keyboard'
                : 'paragraph_comment.emoji',
          ),
          onPressed: logic.is_busy ? null : logic.toggle_emoji,
          color: logic.show_emoji ? ColorConstants.themeColor : icon_color,
          iconSize: ParagraphCommentComposerStyle.action_icon_size,
          constraints: const BoxConstraints.tightFor(
            width: ParagraphCommentComposerStyle.action_size,
            height: ParagraphCommentComposerStyle.action_size,
          ),
          icon: Icon(
            logic.show_emoji
                ? Icons.keyboard_alt_outlined
                : Icons.sentiment_satisfied_alt_rounded,
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              key: const ValueKey<String>('paragraph_comment_send'),
              onPressed: logic.can_send ? logic.send : null,
              style: FilledButton.styleFrom(
                backgroundColor: ColorConstants.themeColor,
                foregroundColor: ColorConstants.lightTextColor,
                disabledBackgroundColor:
                    ParagraphCommentComposerStyle.quote_background(is_dark),
                disabledForegroundColor:
                    ParagraphCommentComposerStyle.secondary_text(is_dark),
                minimumSize: Size(
                  is_cjk
                      ? ParagraphCommentComposerStyle.send_min_width_cjk
                      : ParagraphCommentComposerStyle.send_min_width_alphabetic,
                  ParagraphCommentComposerStyle.action_size,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    ParagraphCommentComposerStyle.send_radius,
                  ),
                ),
                textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: is_cjk
                      ? ParagraphCommentComposerStyle.send_font_size_cjk
                      : ParagraphCommentComposerStyle.send_font_size_alphabetic,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                ),
              ),
              child: logic.is_sending
                  ? SizedBox.square(
                      dimension: ParagraphCommentComposerStyle.progress_size,
                      child: CircularProgressIndicator(
                        color: ParagraphCommentComposerStyle.secondary_text(
                          is_dark,
                        ),
                        strokeWidth:
                            ParagraphCommentComposerStyle.progress_stroke,
                      ),
                    )
                  : Text(
                      tr('paragraph_comment.send'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
