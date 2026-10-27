import 'package:app/components/window_content_layout/index.dart';
import 'package:app/pages/short_story_read/style.dart';
import 'package:app/pages/short_story_read/widgets/skeleton_content.dart';
import 'package:flutter/material.dart';

/// TODO 首次进入短篇也预示封面后的正文，不再把整段阅读区域留白。
class ShortStorySkeletonBody extends StatelessWidget {
  const ShortStorySkeletonBody({super.key, required this.is_dark});
  final bool is_dark;

  @override
  Widget build(BuildContext context) => WindowReservedRegionPadding(
    child: Padding(
      key: const ValueKey('work_detail_skeleton_reading'),
      padding: EdgeInsets.fromLTRB(
        ShortStoryReadStyle.page_horizontal_padding,
        0,
        ShortStoryReadStyle.page_horizontal_padding,
        ShortStoryReadStyle.page_bottom_padding +
            MediaQuery.paddingOf(context).bottom,
      ),
      child: SkeletonContent(is_dark: is_dark, with_pulse: false),
    ),
  );
}
