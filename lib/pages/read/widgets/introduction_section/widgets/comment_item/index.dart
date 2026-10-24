import 'package:app/config/font_config.dart';
import 'package:app/pages/read/logic.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';

import 'review_content.dart';
import 'reviewer_avatar.dart';
import 'style.dart';

/// 作者身份与真实评分组成轻量署名，正文单独占满纸面，长评可展开阅读。
class ReadCommentItem extends StatelessWidget {
  const ReadCommentItem({
    super.key,
    required this.is_dark,
    required this.comment,
  });
  final bool is_dark;
  final ReadComment comment;

  @override
  Widget build(BuildContext context) {
    final cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    // 0 表示未评分，不补默认五星；异常评分也不冒充有效评分。
    final has_rating =
        comment.star_count > 0 &&
        comment.star_count <= CommentItemStyle.rating_max;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: CommentItemStyle.vertical_padding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ExcludeSemantics(
                child: ReadReviewerAvatar(
                  avatar_url: comment.avatar_url,
                  user_name: comment.user_name,
                  is_dark: is_dark,
                ),
              ),
              const SizedBox(width: CommentItemStyle.avatar_content_spacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.user_name,
                      maxLines: CommentItemStyle.name_max_lines,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: CommentItemStyle.name_color(is_dark),
                        fontSize: cjk
                            ? CommentItemStyle.name_font_size_cjk
                            : CommentItemStyle.name_font_size_alphabetic,
                        height: cjk
                            ? CommentItemStyle.name_line_height_cjk
                            : CommentItemStyle.name_line_height_alphabetic,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                      ),
                    ),
                    if (has_rating) ...[
                      const SizedBox(height: CommentItemStyle.rating_top_gap),
                      Semantics(
                        label: easy.tr(
                          'read.review_rating',
                          namedArgs: {'rating': '${comment.star_count}'},
                        ),
                        child: ExcludeSemantics(
                          child: Wrap(
                            spacing: CommentItemStyle.star_spacing,
                            children: List.generate(
                              CommentItemStyle.rating_max,
                              (index) => Icon(
                                Icons.star_rounded,
                                size: CommentItemStyle.star_size,
                                color: index < comment.star_count
                                    ? CommentItemStyle.rating_color(is_dark)
                                    : CommentItemStyle.empty_star_color(
                                        is_dark,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: CommentItemStyle.body_top_gap),
          ReadReviewContent(
            key: ValueKey((comment.user_id, comment.content)),
            comment: comment,
            is_dark: is_dark,
          ),
        ],
      ),
    );
  }
}
