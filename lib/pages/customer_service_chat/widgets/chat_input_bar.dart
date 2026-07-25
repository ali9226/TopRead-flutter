// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/components/svg_icon/index.dart';
import '../style.dart';

/// 聊天输入栏组件。
///
/// 位于页面底部，键盘弹出时自动上移。
/// 包含表情按钮、图片按钮、输入框和发送按钮。
/// 输入框为空时发送按钮为浅灰色，有内容时为深色。
class ChatInputBar extends StatefulWidget {
    final bool is_dark;
    final TextEditingController text_controller;
    final FocusNode focus_node;
    final bool show_emoji_panel;
    final VoidCallback on_send;
    final VoidCallback on_toggle_emoji;
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
    State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
    /// 输入框是否有内容。
    bool _has_text = false;

    @override
    void initState() {
        super.initState();
        widget.text_controller.addListener(_on_text_changed);
        _has_text = widget.text_controller.text.trim().isNotEmpty;
    }

    @override
    void dispose() {
        widget.text_controller.removeListener(_on_text_changed);
        super.dispose();
    }

    /// 监听输入框文字变化。
    void _on_text_changed() {
        final bool now_has_text = widget.text_controller.text.trim().isNotEmpty;
        if (now_has_text != _has_text) {
            setState(() => _has_text = now_has_text);
        }
    }

    @override
    Widget build(BuildContext context) {
        final Color bar_bg = widget.is_dark
            ? CustomerServiceChatStyle.input_bar_bg_dark
            : CustomerServiceChatStyle.input_bar_bg_light;

        final Color field_bg = widget.is_dark
            ? CustomerServiceChatStyle.input_field_bg_dark
            : CustomerServiceChatStyle.input_field_bg_light;

        final Color text_color = widget.is_dark
            ? CustomerServiceChatStyle.input_text_color_dark
            : CustomerServiceChatStyle.input_text_color_light;

        // TODO 夜间模式图标颜色与首页底部导航一致
        final Color icon_color = widget.is_dark
            ? ColorConstants.hintColor
            : CustomerServiceChatStyle.tool_icon_color_light;

        // TODO 发送按钮颜色：空内容时浅灰色，有内容时深色
        final Color send_bg_color = _has_text
            ? CustomerServiceChatStyle.send_button_color
            : (widget.is_dark ? const Color(0xFF3A3A4A) : const Color(0xFFE0E0E0));

        final Color send_text_color = _has_text
            ? const Color(0xFF111111)
            : (widget.is_dark ? const Color(0xFF666666) : const Color(0xFF999999));

        // TODO 底部安全区 padding
        final double bottom_safe = MediaQuery.of(context).padding.bottom;

        return Container(
            padding: EdgeInsets.only(
                left: CustomerServiceChatStyle.input_bar_padding_h,
                right: CustomerServiceChatStyle.input_bar_padding_h,
                top: CustomerServiceChatStyle.input_bar_padding_v,
                bottom: CustomerServiceChatStyle.input_bar_padding_v + bottom_safe,
            ),
            color: bar_bg,
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                    // TODO 表情按钮
                    GestureDetector(
                        onTap: widget.on_toggle_emoji,
                        child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: widget.show_emoji_panel
                                ? SvgIcon(
                                    name: 'keyboard',
                                    width: CustomerServiceChatStyle.tool_icon_size,
                                    height: CustomerServiceChatStyle.tool_icon_size,
                                    color: widget.is_dark ? Colors.white : ColorConstants.lightTextColor,
                                )
                                : SvgIcon(
                                    name: 'meme',
                                    width: CustomerServiceChatStyle.tool_icon_size,
                                    height: CustomerServiceChatStyle.tool_icon_size,
                                    color: icon_color,
                                ),
                        ),
                    ),
                    const SizedBox(width: 4),
                    // TODO 图片按钮
                    GestureDetector(
                        onTap: widget.on_pick_image,
                        child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: SvgIcon(
                                name: 'image',
                                width: CustomerServiceChatStyle.tool_icon_size,
                                height: CustomerServiceChatStyle.tool_icon_size,
                                color: icon_color,
                            ),
                        ),
                    ),
                    const SizedBox(width: 8),
                    // TODO 输入框
                    Expanded(
                        child: Container(
                            height: 36,
                            decoration: BoxDecoration(
                                color: field_bg,
                                borderRadius: BorderRadius.circular(
                                    CustomerServiceChatStyle.input_radius),
                            ),
                            alignment: Alignment.center,
                            child: TextField(
                                controller: widget.text_controller,
                                focusNode: widget.focus_node,
                                maxLines: 1,
                                style: TextStyle(
                                    fontSize: CustomerServiceChatStyle.input_font_size,
                                    fontWeight: CustomerServiceChatStyle.message_font_weight,
                                    color: text_color,
                                    height: 1.0,
                                ),
                                decoration: InputDecoration(
                                    hintText: '输入消息...',
                                    hintStyle: TextStyle(
                                        fontSize: CustomerServiceChatStyle.input_font_size,
                                        color: CustomerServiceChatStyle.input_hint_color,
                                        height: 1.0,
                                    ),
                                    isDense: true,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    focusedErrorBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 0,
                                    ),
                                ),
                            ),
                        ),
                    ),
                    const SizedBox(width: 8),
                    // TODO 发送按钮（与输入框等高）
                    GestureDetector(
                        onTap: _has_text ? widget.on_send : null,
                        child: Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                                color: send_bg_color,
                                borderRadius: BorderRadius.circular(18),
                            ),
                            child: Center(
                                child: Text(
                                    '发送',
                                    style: TextStyle(
                                        fontSize: CustomerServiceChatStyle.send_button_font_size,
                                        fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
                                        color: send_text_color,
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
