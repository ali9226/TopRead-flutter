import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';

import 'package:app/components/comment_list/widgets/comment_avatar.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/pages/read/logic.dart';
import 'package:app/util/language_util/index.dart';

/// 阅读页单条评论组件。
///
/// 极简布局：头像 + 昵称 + 正文，无背景无分割线。
class ReadCommentItem extends StatelessWidget {
  /// 当前是否为夜间主题。
  final bool is_dark;

  /// 单条评论数据。
  final ReadComment comment;

  const ReadCommentItem({
    super.key,
    required this.is_dark,
    required this.comment,
  });

  @override
  Widget build(BuildContext context) {
    final bool is_cjk = LanguageUtil.is_cjk_language(
      easy.EasyLocalization.of(context)!.locale.languageCode,
    );

    final Color text_color = is_dark
        ? ColorConstants.whiteColor
        : ColorConstants.lightTextColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CommentAvatar(
            avatar_url: comment.avatar_url,
            user_id: comment.user_id,
            size: 34,
            is_dark: is_dark,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  comment.user_name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: text_color,
                    fontSize: 13,
                    fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  comment.content,
                  style: TextStyle(
                    color: text_color.withValues(alpha: 0.8),
                    fontSize: is_cjk ? 14.5 : 14,
                    height: is_cjk ? 1.55 : 1.6,
                    fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
