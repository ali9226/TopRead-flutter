import 'package:flutter/material.dart';

import 'style.dart';

/// 漫画简介用小饰条标记标题；微调视觉位置，不改变正文的测量宽度。
class CompactSynopsisHeading extends StatelessWidget {
  const CompactSynopsisHeading({
    super.key,
    required this.title,
    required this.key_prefix,
  });

  final Widget title;
  final String key_prefix;

  @override
  Widget build(BuildContext context) => Transform.translate(
    offset: const Offset(0, -ExpandableSynopsisStyle.compact_title_lift),
    child: Row(
      children: [
        Container(
          key: ValueKey('${key_prefix}_accent'),
          width: ExpandableSynopsisStyle.compact_accent_width,
          height: ExpandableSynopsisStyle.compact_accent_height,
          decoration: BoxDecoration(
            color: ExpandableSynopsisStyle.accent_color,
            borderRadius: BorderRadius.circular(
              ExpandableSynopsisStyle.accent_radius,
            ),
          ),
        ),
        const SizedBox(width: ExpandableSynopsisStyle.compact_accent_gap),
        Flexible(child: title),
      ],
    ),
  );
}
