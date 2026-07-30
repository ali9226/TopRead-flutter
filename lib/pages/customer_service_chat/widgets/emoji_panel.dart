// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import '../style.dart';

/// 可滚动的表情选择面板。
///
/// 面板使用与系统键盘相近的固定占位高度，避免切换键盘和表情时
/// 消息列表产生明显跳动；网格结构也能在后续增加表情时保持稳定。
class EmojiPanel extends StatelessWidget {
  /// 是否为夜间模式。
  final bool is_dark;

  /// 选中表情回调。
  final ValueChanged<String> on_emoji_selected;

  const EmojiPanel({
    super.key,
    required this.is_dark,
    required this.on_emoji_selected,
  });

  @override
  Widget build(BuildContext context) {
    final Color panel_color = is_dark
        ? CustomerServiceChatStyle.emoji_panel_bg_dark
        : CustomerServiceChatStyle.emoji_panel_bg_light;
    final double bottom_safe = MediaQuery.viewPaddingOf(context).bottom;

    return RepaintBoundary(
      child: Material(
        color: panel_color,
        child: GridView.builder(
          primary: false,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            CustomerServiceChatStyle.emoji_panel_padding_h,
            CustomerServiceChatStyle.emoji_panel_padding_top,
            CustomerServiceChatStyle.emoji_panel_padding_h,
            bottom_safe + CustomerServiceChatStyle.emoji_panel_padding_top,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: CustomerServiceChatStyle.emoji_columns,
            mainAxisExtent: CustomerServiceChatStyle.emoji_item_size,
          ),
          itemCount: CustomerServiceChatStyle.emoji_list.length,
          itemBuilder: (BuildContext context, int index) {
            final String emoji = CustomerServiceChatStyle.emoji_list[index];
            return Semantics(
              button: true,
              label: emoji,
              child: InkResponse(
                radius: CustomerServiceChatStyle.emoji_item_size / 2,
                containedInkWell: true,
                highlightShape: BoxShape.circle,
                onTap: () => on_emoji_selected(emoji),
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(
                      fontSize: CustomerServiceChatStyle.emoji_font_size,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
