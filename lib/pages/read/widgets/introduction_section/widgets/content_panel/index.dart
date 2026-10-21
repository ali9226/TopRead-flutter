import 'package:app/components/window_content_layout/index.dart';
import 'package:app/pages/read/widgets/introduction_section/style.dart';
import 'package:flutter/material.dart';

/// 分类、简介与热评共用同一圆角纸面，内容随安全区调整而背景保持全幅。
class ReadIntroductionPanel extends StatelessWidget {
  const ReadIntroductionPanel({
    super.key,
    required this.is_dark,
    required this.child,
  });
  final bool is_dark;
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    key: const ValueKey('novel_introduction_content_panel'),
    color: is_dark
        ? IntroductionStyle.content_background_dark
        : IntroductionStyle.content_background_light,
    borderRadius: const BorderRadius.vertical(
      top: Radius.circular(IntroductionStyle.content_panel_radius),
    ),
    clipBehavior: Clip.antiAlias,
    child: WindowReservedRegionPadding(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          IntroductionStyle.content_horizontal_padding,
          IntroductionStyle.tag_section_top_spacing,
          IntroductionStyle.content_horizontal_padding,
          IntroductionStyle.content_bottom_spacing,
        ),
        child: child,
      ),
    ),
  );
}
