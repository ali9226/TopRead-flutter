import 'package:app/config/font_config.dart';
import 'package:app/pages/message/style.dart';
import 'package:app/util/language_util/index.dart';
import 'package:flutter/material.dart';

import 'message_type_icon.dart';

/// 有封面时将类型图标移到右侧；无封面时保留原文字标签。
class MessageTypeBadge extends StatelessWidget {
  const MessageTypeBadge({
    super.key,
    required this.icon_name,
    required this.label,
    required this.background_color,
    required this.foreground_color,
    required this.icon_only,
  });

  final String icon_name;
  final String label;
  final Color background_color;
  final Color foreground_color;
  final bool icon_only;

  @override
  Widget build(BuildContext context) {
    if (icon_only) {
      return Semantics(
        label: label,
        child: Tooltip(
          message: label,
          excludeFromSemantics: true,
          child: MessageTypeIcon(
            key: const ValueKey('message_type_icon'),
            icon_name: icon_name,
            background_color: background_color,
            foreground_color: foreground_color,
          ),
        ),
      );
    }
    final cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    return Container(
      padding: MessageStyle.badge_padding,
      decoration: BoxDecoration(
        color: background_color,
        borderRadius: BorderRadius.circular(MessageStyle.badge_radius),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foreground_color,
          fontSize: cjk
              ? MessageStyle.badge_font_size_cjk
              : MessageStyle.badge_font_size_alphabetic,
          fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
        ),
      ),
    );
  }
}
