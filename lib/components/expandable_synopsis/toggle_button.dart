import 'package:app/config/color_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'style.dart';

/// 展开文案保留给辅助功能及悬停提示，漫画可使用透明背景的小双箭头。
class SynopsisToggleButton extends StatelessWidget {
  const SynopsisToggleButton({
    super.key,
    required this.expanded,
    required this.label,
    required this.key_prefix,
    required this.on_pressed,
    this.compact = false,
    this.is_dark = false,
    this.foreground_color,
  });

  final bool expanded;
  final String label;
  final String key_prefix;
  final VoidCallback on_pressed;
  final bool compact;
  final bool is_dark;
  final Color? foreground_color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    expanded: expanded,
    button: true,
    child: Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: GestureDetector(
        key: ValueKey('${key_prefix}_toggle'),
        onTap: on_pressed,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: ExpandableSynopsisStyle.toggle_extent,
          height: ExpandableSynopsisStyle.toggle_extent,
          decoration: compact
              ? null
              : const BoxDecoration(
                  color: ColorConstants.themeColor,
                  shape: BoxShape.circle,
                ),
          alignment: Alignment.center,
          child: Transform.translate(
            offset: Offset(
              0,
              compact ? -ExpandableSynopsisStyle.compact_toggle_icon_lift : 0,
            ),
            child: AnimatedRotation(
              turns: compact ? (expanded ? 0 : 0.5) : (expanded ? 0.5 : 0),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : ExpandableSynopsisStyle.expand_duration,
              curve: Curves.easeInOutCubic,
              child: compact
                  ? SvgPicture.asset(
                      'assets/svg/up.svg',
                      width: ExpandableSynopsisStyle.compact_toggle_icon_size,
                      height: ExpandableSynopsisStyle.compact_toggle_icon_size,
                      colorFilter: ColorFilter.mode(
                        foreground_color ??
                            (is_dark
                                ? ExpandableSynopsisStyle.embedded_text_dark
                                : ExpandableSynopsisStyle.embedded_text_light),
                        BlendMode.srcIn,
                      ),
                      excludeFromSemantics: true,
                    )
                  : const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: ExpandableSynopsisStyle.toggle_icon_size,
                      color: ColorConstants.lightTextColor,
                    ),
            ),
          ),
        ),
      ),
    ),
  );
}
