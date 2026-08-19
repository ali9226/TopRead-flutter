// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';
import '../style.dart';

/// 聊天输入栏组件。
///
/// 包含文字输入框、表情按钮、图片按钮和发送按钮。
class ChatInputBar extends StatelessWidget {
    /// 是否为夜间模式。
    final bool is_dark;

    /// 输入框控制器。
    final TextEditingController text_controller;

    /// 焦点节点。
    final FocusNode focus_node;

    /// 是否显示表情面板。
    final bool show_emoji_panel;

    /// 发送文字消息回调。
    final VoidCallback on_send;

    /// 切换表情面板回调。
    final VoidCallback on_toggle_emoji;

    /// 选择图片回调。
    final VoidCallback on_pick_image;

    const ChatInputBar({
        super.key,
        required this.is_dark,
        required this.text_controller,
        required this.focus_node,
        required this.show_emoji_panel,
        required this.on_send,
        required this.on_toggle_emoji,
        required this.on_pick_image,
    });

    @override
    Widget build(BuildContext context) {
        /// 输入栏背景色。
        final Color bar_bg = is_dark
            ? CustomerServiceSheetStyle.input_bar_bg_dark
            : CustomerServiceSheetStyle.input_bar_bg_light;

        /// 输入框背景色。
        final Color field_bg = is_dark
            ? CustomerServiceSheetStyle.input_field_bg_dark
            : CustomerServiceSheetStyle.input_field_bg_light;

        /// 输入框文字颜色。
        final Color text_color = is_dark
            ? CustomerServiceSheetStyle.input_text_color_dark
            : CustomerServiceSheetStyle.input_text_color_light;

        /// 工具图标颜色。
        final Color icon_color = is_dark
            ? CustomerServiceSheetStyle.tool_icon_color_dark
            : CustomerServiceSheetStyle.tool_icon_color_light;

        return Container(
            padding: EdgeInsets.only(
                left: 8,
                right: 8,
                top: 8,
                bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: BoxDecoration(
                color: bar_bg,
                border: Border(
                    top: BorderSide(
                        color: is_dark
                            ? CustomerServiceSheetStyle.divider_color_dark
                            : CustomerServiceSheetStyle.divider_color_light,
                        width: 0.5,
                    ),
                ),
            ),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                    // TODO 表情按钮
                    GestureDetector(
                        onTap: on_toggle_emoji,
                        child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                                show_emoji_panel ? Icons.keyboard : Icons.emoji_emotions_outlined,
                                size: CustomerServiceSheetStyle.tool_icon_size,
                                color: show_emoji_panel
                                    ? CustomerServiceSheetStyle.send_button_color
                                    : icon_color,
                            ),
                        ),
                    ),
                    const SizedBox(width: 4),
                    // TODO 图片按钮
                    GestureDetector(
                        onTap: on_pick_image,
                        child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                                Icons.image_outlined,
                                size: CustomerServiceSheetStyle.tool_icon_size,
                                color: icon_color,
                            ),
                        ),
                    ),
                    const SizedBox(width: 8),
                    // TODO 输入框
                    Expanded(
                        child: Container(
                            constraints: const BoxConstraints(minHeight: 36, maxHeight: 100),
                            decoration: BoxDecoration(
                                color: field_bg,
                                borderRadius: BorderRadius.circular(CustomerServiceSheetStyle.input_radius),
                            ),
                            child: TextField(
                                controller: text_controller,
                                focusNode: focus_node,
                                maxLines: null,
                                textInputAction: TextInputAction.newline,
                                style: TextStyle(
                                    fontSize: CustomerServiceSheetStyle.input_font_size,
                                    fontWeight: CustomerServiceSheetStyle.message_font_weight,
                                    color: text_color,
                                ),
                                decoration: InputDecoration(
                                    hintText: easy.tr('customer_service.input_hint'),
                                    hintStyle: TextStyle(
                                        fontSize: CustomerServiceSheetStyle.input_font_size,
                                        color: CustomerServiceSheetStyle.input_hint_color,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                    ),
                                ),
                            ),
                        ),
                    ),
                    const SizedBox(width: 8),
                    // TODO 发送按钮
                    GestureDetector(
                        onTap: on_send,
                        child: Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                                color: CustomerServiceSheetStyle.send_button_color,
                                borderRadius: BorderRadius.circular(18),
                            ),
                            child: Center(
                                child: Text(
                                    '发送',
                                    style: TextStyle(
                                        fontSize: CustomerServiceSheetStyle.send_button_font_size,
                                        fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
                                        color: CustomerServiceSheetStyle.send_button_text_color,
                                    ),
                                ),
                            ),
                        ),
                    ),
                ],
            ),
        );
    }
}
