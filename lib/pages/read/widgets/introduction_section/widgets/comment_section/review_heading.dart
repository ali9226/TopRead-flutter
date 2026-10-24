import 'package:app/config/font_config.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';

import 'style.dart';

/// 标题与真实总数自然换行，右侧操作始终保留完整触控区域。
class ReadReviewHeading extends StatelessWidget {
  const ReadReviewHeading({
    super.key,
    required this.is_dark,
    this.comment_count,
    this.on_view_all,
  });
  final bool is_dark;
  final int? comment_count;
  final VoidCallback? on_view_all;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final cjk = LanguageUtil.is_cjk_language(locale);
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: CommentStyle.header_action_gap,
        runSpacing: CommentStyle.heading_bottom_gap,
        children: [
          Wrap(
            spacing: CommentStyle.count_gap,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                easy.tr('read.hot_review_title'),
                key: const ValueKey('read_comments_heading'),
                style: TextStyle(
                  fontFamily: cjk ? null : 'Georgia',
                  fontFamilyFallback: cjk
                      ? null
                      : const ['Times New Roman', 'serif'],
                  color: CommentStyle.ink(is_dark),
                  fontSize: cjk
                      ? CommentStyle.heading_size_cjk
                      : CommentStyle.heading_size_alphabetic,
                  height: cjk
                      ? CommentStyle.heading_height_cjk
                      : CommentStyle.heading_height_alphabetic,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                ),
              ),
              if (comment_count != null && comment_count! >= 0)
                Text(
                  easy.NumberFormat.compact(
                    locale: locale,
                  ).format(comment_count),
                  key: const ValueKey('read_comments_count'),
                  semanticsLabel: easy.tr(
                    'comment.count_label',
                    namedArgs: {
                      'count': easy.NumberFormat.decimalPattern(
                        locale,
                      ).format(comment_count),
                    },
                  ),
                  style: TextStyle(
                    color: CommentStyle.muted(is_dark),
                    fontSize: cjk
                        ? CommentStyle.count_size_cjk
                        : CommentStyle.count_size_alphabetic,
                    fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                  ),
                ),
            ],
          ),
          if (on_view_all != null) ...[
            TextButton(
              key: const ValueKey('read_comments_all'),
              onPressed: on_view_all,
              style: TextButton.styleFrom(
                foregroundColor: CommentStyle.ink(is_dark),
                backgroundColor: CommentStyle.soft_surface(is_dark),
                minimumSize: const Size(0, CommentStyle.action_extent),
                padding: const EdgeInsets.symmetric(
                  horizontal: CommentStyle.action_padding,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    CommentStyle.action_radius,
                  ),
                ),
                textStyle: Theme.of(context).textTheme.labelLarge!.copyWith(
                  fontSize: cjk
                      ? CommentStyle.action_size_cjk
                      : CommentStyle.action_size_alphabetic,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(easy.tr('read.more_review')),
                  const SizedBox(width: CommentStyle.action_icon_gap),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: CommentStyle.action_icon_size,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
