import 'package:app/config/font_config.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';

import 'style.dart';

/// 无书评时提供真实的发表评论入口，不伪造评分、用户或占位评论。
class ReadEmptyReview extends StatelessWidget {
  const ReadEmptyReview({super.key, required this.is_dark, this.on_comment});
  final bool is_dark;
  final VoidCallback? on_comment;

  @override
  Widget build(BuildContext context) {
    final cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CommentStyle.empty_padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Container(
              width: CommentStyle.empty_icon_extent,
              height: CommentStyle.empty_icon_extent,
              decoration: BoxDecoration(
                color: CommentStyle.soft_surface(is_dark),
                borderRadius: BorderRadius.circular(CommentStyle.action_radius),
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: CommentStyle.empty_icon_size,
                color: CommentStyle.muted(is_dark),
              ),
            ),
          ),
          const SizedBox(height: CommentStyle.empty_gap),
          Text(
            easy.tr('comment.empty'),
            style: TextStyle(
              color: CommentStyle.muted(is_dark),
              fontSize: cjk
                  ? CommentStyle.empty_text_size_cjk
                  : CommentStyle.empty_text_size_alphabetic,
              height: cjk
                  ? CommentStyle.empty_text_height_cjk
                  : CommentStyle.empty_text_height_alphabetic,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
            ),
          ),
          if (on_comment != null)
            TextButton(
              key: const ValueKey('read_comments_write'),
              onPressed: on_comment,
              style: TextButton.styleFrom(
                foregroundColor: CommentStyle.ink(is_dark),
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, CommentStyle.action_extent),
                alignment: AlignmentDirectional.centerStart,
                textStyle: Theme.of(context).textTheme.labelLarge!.copyWith(
                  fontSize: cjk
                      ? CommentStyle.action_size_cjk
                      : CommentStyle.action_size_alphabetic,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                ),
              ),
              child: Text(easy.tr('comment.input_hint')),
            ),
        ],
      ),
    );
  }
}
