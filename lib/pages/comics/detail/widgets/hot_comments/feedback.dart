// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/comics/detail/widgets/hot_comments/style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 请求失败展示可重试状态；空列表仍保留卡片底部的真实发表入口。
class ComicHotCommentsFeedback extends StatelessWidget {
  const ComicHotCommentsFeedback({
    super.key,
    required this.is_dark,
    required this.failed,
    required this.on_retry,
  });

  final bool is_dark;
  final bool failed;
  final VoidCallback on_retry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(ComicHotCommentsStyle.feedback_padding),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          tr(failed ? 'comics.comments_load_failed' : 'comics.empty_comments'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ComicHotCommentsStyle.secondary(is_dark),
            fontSize: ComicHotCommentsStyle.localized_size(
              context,
              ComicHotCommentsStyle.feedback_size_cjk,
              ComicHotCommentsStyle.feedback_size_alphabetic,
            ),
            height: ComicHotCommentsStyle.line_height(context),
            fontWeight: ComicHotCommentsStyle.regular,
          ),
        ),
        if (failed)
          TextButton(
            key: const ValueKey<String>('comic_hot_comments_retry'),
            onPressed: on_retry,
            child: Text(tr('comics.retry')),
          ),
      ],
    ),
  );
}
