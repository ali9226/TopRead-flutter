// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/author_center/author_style.dart';
import 'package:flutter/material.dart';

/// 段落评论计数标记。
///
/// 显示在段落旁边，点击后打开评论面板。
class ParagraphCommentBadge extends StatelessWidget {
  /// 评论数量。
  final int comment_count;

  /// 当前是否夜间主题。
  final bool is_dark;

  /// 点击回调。
  final VoidCallback? onTap;

  const ParagraphCommentBadge({
    super.key,
    required this.comment_count,
    required this.is_dark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (comment_count <= 0) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AuthorStyle.gold.withValues(alpha: is_dark ? 0.15 : 0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 12,
              color: is_dark ? AuthorStyle.gold : AuthorStyle.deep_gold,
            ),
            const SizedBox(width: 4),
            Text(
              _format_count(comment_count),
              style: TextStyle(
                fontSize: 11,
                color: is_dark ? AuthorStyle.gold : AuthorStyle.deep_gold,
                fontWeight: AuthorStyle.emphasis_weight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _format_count(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}w';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}
