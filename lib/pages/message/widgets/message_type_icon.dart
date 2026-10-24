import 'package:app/pages/message/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 同一个类型图标用于无封面消息左侧、以及有封面消息右侧。
class MessageTypeIcon extends StatelessWidget {
  const MessageTypeIcon({
    super.key,
    required this.icon_name,
    required this.background_color,
    required this.foreground_color,
  });

  final String icon_name;
  final Color background_color;
  final Color foreground_color;

  @override
  Widget build(BuildContext context) => Container(
    width: MessageStyle.icon_wrap_size,
    height: MessageStyle.icon_wrap_size,
    decoration: BoxDecoration(color: background_color, shape: BoxShape.circle),
    alignment: Alignment.center,
    child: SvgPicture.asset(
      'assets/svg/$icon_name.svg',
      width: MessageStyle.icon_size,
      height: MessageStyle.icon_size,
      colorFilter: ColorFilter.mode(foreground_color, BlendMode.srcIn),
      excludeFromSemantics: true,
    ),
  );
}
