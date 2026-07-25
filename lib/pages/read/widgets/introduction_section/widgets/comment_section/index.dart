import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/pages/read/logic.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/comment_item/index.dart';

/// 阅读页评论列表组件。
///
/// 展示小说的热门书评列表。
class ReadCommentSection extends StatelessWidget {
  /// 当前是否为夜间主题。
  final bool is_dark;

  /// 评论数据列表。
  final List<ReadComment> comment_list;

  const ReadCommentSection({
    super.key,
    required this.is_dark,
    required this.comment_list,
  });

  @override
  Widget build(BuildContext context) {
    final Color title_color = is_dark
        ? ColorConstants.whiteColor
        : ColorConstants.lightTextColor;

    final Color empty_text_color = is_dark
        ? ColorConstants.whiteColor.withValues(alpha: 0.48)
        : const Color(0xFF8D7D68);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          easy.tr('read.hot_review_title'),
          style: TextStyle(
            color: title_color,
            fontSize: 16,
            fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
          ),
        ),
        const SizedBox(height: 14),
        if (comment_list.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              easy.tr('comment.empty'),
              style: TextStyle(
                color: empty_text_color,
                fontSize: 13,
                height: 1.5,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
              ),
            ),
          ),
        ...comment_list.map(
          (ReadComment comment) => ReadCommentItem(
            is_dark: is_dark,
            comment: comment,
          ),
        ),
      ],
    );
  }
}
