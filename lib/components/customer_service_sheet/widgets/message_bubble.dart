// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';
import '../style.dart';

/// 聊天消息气泡组件。
///
/// 根据发送者类型（用户/管理员）展示不同样式的气泡。
/// 支持文字、表情、图片三种消息类型。
class MessageBubble extends StatelessWidget {
    /// 是否为管理员发送的消息。
    final bool is_admin;

    /// 消息类型：1=文字 2=表情 3=图片。
    final int message_type;

    /// 消息内容。
    final String content;

    /// 是否为夜间模式。
    final bool is_dark;

    /// 发送者名称（管理员消息显示）。
    final String sender_name;

    const MessageBubble({
        super.key,
        required this.is_admin,
        required this.message_type,
        required this.content,
        required this.is_dark,
        this.sender_name = '',
    });

    @override
    Widget build(BuildContext context) {
        final double screen_width = MediaQuery.of(context).size.width;
        final double max_bubble_width = screen_width * CustomerServiceSheetStyle.bubble_max_width_ratio;

        /// 气泡背景色。
        final Color bubble_bg = is_admin
            ? (is_dark
                ? CustomerServiceSheetStyle.bubble_admin_bg_dark
                : CustomerServiceSheetStyle.bubble_admin_bg_light)
            : CustomerServiceSheetStyle.bubble_user_bg;

        /// 气泡文字颜色。
        final Color text_color = is_admin
            ? (is_dark
                ? CustomerServiceSheetStyle.bubble_admin_text_dark
                : CustomerServiceSheetStyle.bubble_admin_text_light)
            : CustomerServiceSheetStyle.bubble_user_text;

        return Container(
            constraints: BoxConstraints(maxWidth: max_bubble_width),
            decoration: BoxDecoration(
                color: bubble_bg,
                borderRadius: BorderRadius.circular(CustomerServiceSheetStyle.bubble_radius),
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: CustomerServiceSheetStyle.bubble_padding_h,
                vertical: CustomerServiceSheetStyle.bubble_padding_v,
            ),
            child: _build_content(text_color),
        );
    }

    /// 根据消息类型构建内容。
    Widget _build_content(Color text_color) {
        switch (message_type) {
            case 2:
                // TODO 表情消息：大号显示
                return Text(
                    content,
                    style: const TextStyle(fontSize: 36),
                );
            case 3:
                // TODO 图片消息
                return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(
                            maxWidth: 200,
                            maxHeight: 200,
                        ),
                        child: Image.network(
                            content,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return SizedBox(
                                    width: 100,
                                    height: 100,
                                    child: Center(
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: CustomerServiceSheetStyle.loading_color,
                                        ),
                                    ),
                                );
                            },
                            errorBuilder: (context, error, stackTrace) {
                                return SizedBox(
                                    width: 100,
                                    height: 100,
                                    child: Center(
                                        child: Icon(
                                            Icons.broken_image,
                                            color: CustomerServiceSheetStyle.empty_text_color,
                                            size: 32,
                                        ),
                                    ),
                                );
                            },
                        ),
                    ),
                );
            default:
                // TODO 文字消息
                return Text(
                    content,
                    style: TextStyle(
                        fontSize: CustomerServiceSheetStyle.message_font_size,
                        fontWeight: CustomerServiceSheetStyle.message_font_weight,
                        color: text_color,
                        height: 1.4,
                    ),
                );
        }
    }
}
