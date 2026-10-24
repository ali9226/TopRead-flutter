import 'package:app/pages/read/logic.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/comment_item/index.dart';
import 'package:flutter/material.dart';

import 'empty_review.dart';
import 'review_heading.dart';
import 'style.dart';

/// 封面下的书评预览：标题、读者署名和正文在同一纸面上连续排版。
class ReadCommentSection extends StatelessWidget {
  const ReadCommentSection({
    super.key,
    required this.is_dark,
    required this.comment_list,
    this.comment_count,
    this.on_view_all,
  });
  final bool is_dark;
  final List<ReadComment> comment_list;

  /// 服务端真实总数；未提供时不把预览条数伪装成总数。
  final int? comment_count;

  /// 打开已有评论面板，阅读完整列表或发表评论。
  final VoidCallback? on_view_all;

  @override
  Widget build(BuildContext context) {
    // 只有提供完整列表入口才限制预览数量，独立使用时不吞掉传入数据。
    final visible_comments = on_view_all == null
        ? comment_list
        : comment_list.take(CommentStyle.preview_limit).toList();
    return Column(
      key: const ValueKey('read_comments_section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(
          height: CommentStyle.rule_width,
          thickness: CommentStyle.rule_width,
          color: CommentStyle.rule(is_dark),
        ),
        const SizedBox(height: CommentStyle.heading_top_gap),
        ReadReviewHeading(
          is_dark: is_dark,
          comment_count: comment_count,
          on_view_all: on_view_all,
        ),
        const SizedBox(height: CommentStyle.heading_bottom_gap),
        // 详情接口可能只返回总数；已有书评时保留完整列表入口，不误报无人评论。
        if (visible_comments.isEmpty && (comment_count ?? 0) <= 0)
          ReadEmptyReview(is_dark: is_dark, on_comment: on_view_all),
        for (var index = 0; index < visible_comments.length; index++) ...[
          if (index > 0)
            Divider(
              height: CommentStyle.rule_width,
              thickness: CommentStyle.rule_width,
              color: CommentStyle.rule(is_dark),
            ),
          ReadCommentItem(
            key: ValueKey((visible_comments[index].user_id, index)),
            is_dark: is_dark,
            comment: visible_comments[index],
          ),
        ],
      ],
    );
  }
}
