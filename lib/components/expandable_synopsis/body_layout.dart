import 'package:flutter/material.dart';

import 'style.dart';

/// 小双箭头贴合正文的渐变末端，完整触控区域仍留在简介布局范围内。
class SynopsisBodyLayout extends StatelessWidget {
  const SynopsisBodyLayout({
    super.key,
    required this.body,
    required this.compact,
    required this.expanded,
    this.toggle,
    this.toggle_gap = ExpandableSynopsisStyle.toggle_top_gap,
  });

  final Widget body;
  final Widget? toggle;
  final bool compact;
  final bool expanded;
  final double toggle_gap;

  @override
  Widget build(BuildContext context) {
    final action = toggle;
    if (!compact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          body,
          if (action != null) ...[SizedBox(height: toggle_gap), action],
        ],
      );
    }
    return Stack(
      children: [
        AnimatedPadding(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : expanded
              ? ExpandableSynopsisStyle.expand_duration
              : ExpandableSynopsisStyle.collapse_duration,
          curve: Curves.easeInOutCubic,
          padding: EdgeInsets.only(
            bottom: action == null
                ? 0
                : ExpandableSynopsisStyle.toggle_extent +
                      ExpandableSynopsisStyle.compact_toggle_top_gap -
                      (expanded
                          ? 0
                          : ExpandableSynopsisStyle
                                .compact_toggle_body_overlap),
          ),
          child: body,
        ),
        if (action != null)
          Positioned(left: 0, right: 0, bottom: 0, child: action),
      ],
    );
  }
}
