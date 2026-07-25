import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:app/config/color_config.dart';
import 'package:app/pages/short_story_read/style.dart';
import 'package:app/util/number_format_util.dart';

/// 卡片内评论栏组件。
///
/// 展开状态下显示在正文下方，包含评论输入框、评论数和点赞数。
/// 与 [BottomCommentBar] 不同，此组件嵌入在卡片内部，不包含安全区域适配。
class InlineCommentBar extends StatelessWidget {
  /// 是否为夜间模式。
  final bool is_dark;

  /// 评论数。
  final int comment_count;

  /// 点赞数。
  final int like_count;

  /// 是否已点赞。
  final bool is_liked;

  /// 评论输入框点击回调。
  final VoidCallback on_comment_tap;

  /// 点赞按钮点击回调。
  final VoidCallback on_like_tap;

  const InlineCommentBar({
    super.key,
    required this.is_dark,
    required this.comment_count,
    required this.like_count,
    required this.is_liked,
    required this.on_comment_tap,
    required this.on_like_tap,
  });

  @override
  Widget build(BuildContext context) {
    /// 输入框背景色。
    final Color input_bg_color = is_dark
        ? ShortStoryReadStyle.comment_input_dark_bg
        : ShortStoryReadStyle.comment_input_light_bg;

    /// 输入框文字/图标颜色。
    final Color input_text_color = is_dark
        ? ShortStoryReadStyle.comment_input_dark_color
        : ShortStoryReadStyle.comment_input_light_color;

    /// 次要文字/图标颜色。
    final Color secondary_color = is_dark
        ? ShortStoryReadStyle.secondary_dark_color
        : ShortStoryReadStyle.secondary_light_color;

    return Row(
      children: <Widget>[
        /// 评论输入框（模拟样式，点击后触发评论弹窗）。
        Expanded(
          child: GestureDetector(
            onTap: on_comment_tap,
            child: Container(
              height: ShortStoryReadStyle.comment_input_height,
              padding: const EdgeInsets.symmetric(
                horizontal: ShortStoryReadStyle.comment_input_horizontal_padding,
              ),
              decoration: BoxDecoration(
                color: input_bg_color,
                borderRadius: BorderRadius.circular(
                  ShortStoryReadStyle.comment_input_radius,
                ),
              ),
              alignment: Alignment.centerLeft,
              child: Row(
                children: <Widget>[
                  /// 编辑图标。
                  SvgPicture.asset(
                    'assets/svg/edit.svg',
                    width: 16,
                    height: 16,
                    colorFilter:
                        ColorFilter.mode(input_text_color, BlendMode.srcIn),
                  ),
                  const SizedBox(width: 8),

                  /// 输入框占位文字。
                  Text(
                    tr('short_story_read.comment_input_hint'),
                    style: TextStyle(
                      fontSize: 14,
                      color: input_text_color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),

        /// 评论数（图标 + 数字）。
        GestureDetector(
          onTap: on_comment_tap,
          child: Row(
            children: <Widget>[
              SvgPicture.asset(
                'assets/svg/message_selected_no.svg',
                width: 20,
                height: 20,
                colorFilter:
                    ColorFilter.mode(secondary_color, BlendMode.srcIn),
              ),
              const SizedBox(width: 4),
              Text(
                NumberFormatUtil.format_count(comment_count),
                style: TextStyle(
                  fontSize: 12,
                  color: secondary_color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),

        /// 点赞数（图标 + 数字，已点赞时使用红色）。
        GestureDetector(
          onTap: on_like_tap,
          child: Row(
            children: <Widget>[
              SvgPicture.asset(
                is_liked ? 'assets/svg/love_02.svg' : 'assets/svg/love.svg',
                width: 20,
                height: 20,
                colorFilter: is_liked
                    ? ColorFilter.mode(
                        ColorConstants.dangerColor, BlendMode.srcIn)
                    : ColorFilter.mode(secondary_color, BlendMode.srcIn),
              ),
              const SizedBox(width: 4),
              Text(
                NumberFormatUtil.format_count(like_count),
                style: TextStyle(
                  fontSize: 12,
                  color: is_liked
                      ? ColorConstants.dangerColor
                      : secondary_color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
