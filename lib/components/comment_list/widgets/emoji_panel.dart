import 'package:flutter/material.dart';

import 'package:app/components/comment_list/style.dart';

/// 评论区表情选择面板。
///
/// 面板与评论弹窗使用同一背景色，仅通过顶部细分隔线表达层级，
/// 避免夜间模式下出现紫黑色块。网格限制最大宽度，同时适配手机和 Web。
class CommentEmojiPanel extends StatelessWidget {
  final bool is_dark;
  final void Function(String emoji) on_emoji_selected;

  const CommentEmojiPanel({
    super.key,
    required this.is_dark,
    required this.on_emoji_selected,
  });

  @override
  Widget build(BuildContext context) {
    final Color background_color = is_dark
        ? CommentListStyle.emoji_panel_dark_bg
        : CommentListStyle.emoji_panel_light_bg;
    final Color divider_color = is_dark
        ? CommentListStyle.emoji_panel_divider_dark_color
        : CommentListStyle.emoji_panel_divider_light_color;
    final Color feedback_color = is_dark
        ? CommentListStyle.emoji_item_feedback_dark_color
        : CommentListStyle.emoji_item_feedback_light_color;

    return RepaintBoundary(
      child: Material(
        key: const ValueKey<String>('comment_emoji_panel'),
        color: background_color,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: divider_color,
                width: CommentListStyle.emoji_panel_divider_thickness,
              ),
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: CommentListStyle.emoji_panel_max_width,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: CommentListStyle.emoji_panel_horizontal_padding,
                  vertical: CommentListStyle.emoji_panel_vertical_padding,
                ),
                child: GridView.builder(
                  primary: false,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: CommentListStyle.emoji_list.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: CommentListStyle.emoji_columns,
                    mainAxisExtent: CommentListStyle.emoji_item_height,
                    crossAxisSpacing:
                        CommentListStyle.emoji_item_horizontal_spacing,
                    mainAxisSpacing:
                        CommentListStyle.emoji_item_vertical_spacing,
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    final String emoji = CommentListStyle.emoji_list[index];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => on_emoji_selected(emoji),
                        borderRadius: BorderRadius.circular(
                          CommentListStyle.emoji_item_radius,
                        ),
                        splashColor: feedback_color,
                        highlightColor: feedback_color,
                        hoverColor: feedback_color,
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(
                              fontSize: CommentListStyle.emoji_font_size,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
