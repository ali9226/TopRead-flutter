import 'package:app/components/comment_list/widgets/comment_avatar.dart';
import 'package:flutter/material.dart';

import 'style.dart';

/// 热门书评与完整评论列表使用同一头像规则；同用户的默认插图保持一致。
class ReadReviewerAvatar extends StatelessWidget {
  const ReadReviewerAvatar({
    super.key,
    required this.avatar_url,
    required this.user_id,
    required this.is_dark,
  });
  final String avatar_url;
  final int user_id;
  final bool is_dark;

  @override
  Widget build(BuildContext context) => CommentAvatar(
    avatar_url: avatar_url,
    user_id: user_id,
    size: CommentItemStyle.avatar_size,
    is_dark: is_dark,
  );
}
