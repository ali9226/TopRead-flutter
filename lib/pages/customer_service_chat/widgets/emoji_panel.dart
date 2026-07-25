// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import '../style.dart';

/// 表情面板组件。
class EmojiPanel extends StatelessWidget {
    final bool is_dark;
    final void Function(String emoji) on_emoji_selected;

    const EmojiPanel({
        super.key,
        required this.is_dark,
        required this.on_emoji_selected,
    });

    @override
    Widget build(BuildContext context) {
        // TODO 计算实际需要的高度：行数 * (表情大小 + 间距) + 上下padding
        final int emoji_count = CustomerServiceChatStyle.emoji_list.length;
        final int columns = CustomerServiceChatStyle.emoji_columns;
        final int rows = (emoji_count / columns).ceil();
        const double item_size = 36;
        const double spacing = 6;
        const double padding_h = 12;
        const double padding_v = 8;
        final double panel_height = rows * item_size + (rows - 1) * spacing + padding_v * 2;

        return ColoredBox(
            color: is_dark
                ? CustomerServiceChatStyle.emoji_panel_bg_dark
                : CustomerServiceChatStyle.emoji_panel_bg_light,
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: padding_h, vertical: padding_v),
                child: Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: CustomerServiceChatStyle.emoji_list.map((emoji) {
                        return GestureDetector(
                            onTap: () => on_emoji_selected(emoji),
                            child: SizedBox(
                                width: item_size,
                                height: item_size,
                                child: Center(
                                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                                ),
                            ),
                        );
                    }).toList(),
                ),
            ),
        );
    }
}
