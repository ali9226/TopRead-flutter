// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/config/font_config.dart';
import '../style.dart';
import 'message_bubble.dart';

/// 聊天消息列表项数据。
class ChatMessageItem {
    final int id;
    final int sender_type; // 1=用户 2=管理员
    final int message_type; // 1=文字 2=表情 3=图片
    final String content;
    final String create_time;
    final String sender_name;

    ChatMessageItem({
        required this.id,
        required this.sender_type,
        required this.message_type,
        required this.content,
        required this.create_time,
        this.sender_name = '',
    });
}

/// 聊天消息列表组件。
///
/// 展示聊天消息列表，支持自动滚动到底部。
/// 区分用户消息（右侧）和管理员消息（左侧）。
class ChatMessageList extends StatelessWidget {
    /// 消息列表。
    final List<ChatMessageItem> messages;

    /// 是否为夜间模式。
    final bool is_dark;

    /// 滚动控制器。
    final ScrollController scroll_controller;

    /// 是否正在加载历史消息。
    final bool is_loading;

    const ChatMessageList({
        super.key,
        required this.messages,
        required this.is_dark,
        required this.scroll_controller,
        this.is_loading = false,
    });

    @override
    Widget build(BuildContext context) {
        if (messages.isEmpty && !is_loading) {
            return _build_empty_state(context);
        }

        return Container(
            color: is_dark
                ? CustomerServiceSheetStyle.chat_bg_color_dark
                : CustomerServiceSheetStyle.chat_bg_color_light,
            child: ListView.builder(
                controller: scroll_controller,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: CustomerServiceSheetStyle.message_spacing,
                ),
                itemCount: messages.length + (is_loading ? 1 : 0),
                itemBuilder: (context, index) {
                    // TODO 加载指示器
                    if (is_loading && index == 0) {
                        return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                                child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: CustomerServiceSheetStyle.loading_color,
                                    ),
                                ),
                            ),
                        );
                    }

                    final int msg_index = is_loading ? index - 1 : index;
                    final ChatMessageItem item = messages[msg_index];
                    final bool is_admin = item.sender_type == 2;

                    return Padding(
                        padding: const EdgeInsets.only(
                            bottom: CustomerServiceSheetStyle.message_spacing,
                        ),
                        child: _build_message_row(context, item, is_admin),
                    );
                },
            ),
        );
    }

    /// 构建单条消息行（头像 + 气泡）。
    Widget _build_message_row(BuildContext context, ChatMessageItem item, bool is_admin) {
        final Widget bubble = MessageBubble(
            is_admin: is_admin,
            message_type: item.message_type,
            content: item.content,
            is_dark: is_dark,
            sender_name: item.sender_name,
        );

        // TODO 管理员消息靠左（带头像），用户消息靠右
        if (is_admin) {
            return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                    // TODO 管理员头像
                    _build_avatar(item.sender_name, is_admin),
                    const SizedBox(width: CustomerServiceSheetStyle.avatar_bubble_spacing),
                    // TODO 气泡
                    Flexible(child: bubble),
                    const Spacer(),
                ],
            );
        } else {
            return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                    const Spacer(),
                    // TODO 气泡
                    Flexible(child: bubble),
                    const SizedBox(width: CustomerServiceSheetStyle.avatar_bubble_spacing),
                    // TODO 用户头像
                    _build_avatar('', is_admin),
                ],
            );
        }
    }

    /// 构建头像。
    Widget _build_avatar(String name, bool is_admin) {
        final Color bg_color = is_admin
            ? (is_dark
                ? CustomerServiceSheetStyle.bubble_admin_bg_dark
                : CustomerServiceSheetStyle.bubble_admin_bg_light)
            : CustomerServiceSheetStyle.bubble_user_bg;

        final String display_letter = name.isNotEmpty ? name[0].toUpperCase() : (is_admin ? 'S' : 'U');

        return Container(
            width: CustomerServiceSheetStyle.avatar_size,
            height: CustomerServiceSheetStyle.avatar_size,
            decoration: BoxDecoration(
                color: bg_color,
                borderRadius: BorderRadius.circular(CustomerServiceSheetStyle.avatar_radius),
            ),
            child: Center(
                child: Text(
                    display_letter,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
                        color: is_admin
                            ? (is_dark
                                ? CustomerServiceSheetStyle.bubble_admin_text_dark
                                : CustomerServiceSheetStyle.bubble_admin_text_light)
                            : CustomerServiceSheetStyle.bubble_user_text,
                    ),
                ),
            ),
        );
    }

    /// 构建空状态。
    Widget _build_empty_state(BuildContext context) {
        return Container(
            color: is_dark
                ? CustomerServiceSheetStyle.chat_bg_color_dark
                : CustomerServiceSheetStyle.chat_bg_color_light,
            child: Center(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                        Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: CustomerServiceSheetStyle.empty_text_color,
                        ),
                        const SizedBox(height: 12),
                        Text(
                            easy.tr('customer_service_sheet.empty_hint'),
                            style: TextStyle(
                                fontSize: CustomerServiceSheetStyle.empty_font_size,
                                color: CustomerServiceSheetStyle.empty_text_color,
                            ),
                        ),
                    ],
                ),
            ),
        );
    }
}
