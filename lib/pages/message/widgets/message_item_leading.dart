import 'package:app/components/network_cover_image/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/pages/message/style.dart';
import 'package:flutter/material.dart';

import 'message_type_icon.dart';

/// 小说封面优先，缺少封面时保留原类型图标；两种状态共用未读角标。
class MessageItemLeading extends StatelessWidget {
  const MessageItemLeading({
    super.key,
    required this.icon_name,
    required this.background_color,
    required this.foreground_color,
    required this.is_dark,
    this.cover_url = '',
    this.unread_count = 0,
  });

  final String icon_name;
  final Color background_color;
  final Color foreground_color;
  final bool is_dark;
  final String cover_url;
  final int unread_count;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      if (cover_url.trim().isNotEmpty)
        ExcludeSemantics(
          child: NetworkCoverImage(
            key: const ValueKey('message_cover'),
            image_url: cover_url.trim(),
            width: MessageStyle.cover_width,
            height: MessageStyle.cover_height,
            border_radius: MessageStyle.cover_radius,
            is_dark: is_dark,
          ),
        )
      else
        MessageTypeIcon(
          icon_name: icon_name,
          background_color: background_color,
          foreground_color: foreground_color,
        ),
      if (unread_count > 1)
        PositionedDirectional(
          top: MessageStyle.unread_badge_offset,
          end: MessageStyle.unread_badge_offset,
          child: Container(
            key: const ValueKey('message_unread_count'),
            padding: MessageStyle.unread_badge_padding,
            decoration: BoxDecoration(
              color: ColorConstants.dangerColor,
              borderRadius: BorderRadius.circular(
                MessageStyle.unread_badge_radius,
              ),
            ),
            constraints: const BoxConstraints(
              minWidth: MessageStyle.unread_badge_min_size,
              minHeight: MessageStyle.unread_badge_min_size,
            ),
            alignment: Alignment.center,
            child: Text(
              unread_count > MessageStyle.unread_badge_max_count
                  ? '${MessageStyle.unread_badge_max_count}+'
                  : '$unread_count',
              style: TextStyle(
                color: ColorConstants.whiteColor,
                fontSize: MessageStyle.unread_badge_font_size,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
              ),
            ),
          ),
        ),
    ],
  );
}
