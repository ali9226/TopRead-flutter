import 'package:flutter/material.dart';

import 'package:app/components/comment_list/style.dart';

/// 评论区表情面板组件。
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
    final int emoji_count = CommentListStyle.emoji_list.length;
    final int columns = CommentListStyle.emoji_columns;
    final int rows = (emoji_count / columns).ceil();
    const double item_size = 36;
    const double spacing = 6;
    const double padding_h = 12;
    const double padding_v = 8;
    final double panel_height =
        rows * item_size + (rows - 1) * spacing + padding_v * 2;

    return Container(
      height: panel_height,
      color: is_dark
          ? CommentListStyle.emoji_panel_dark_bg
          : CommentListStyle.emoji_panel_light_bg,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: padding_h,
          vertical: padding_v,
        ),
        child: Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: CommentListStyle.emoji_list.map((emoji) {
            return GestureDetector(
              onTap: () => on_emoji_selected(emoji),
              child: SizedBox(
                width: item_size,
                height: item_size,
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
