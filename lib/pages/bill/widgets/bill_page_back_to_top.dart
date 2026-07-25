import 'package:flutter/material.dart';
import 'package:app/components/back_to_top_button/index.dart';

import '../style.dart';

/// 账单页返回顶部按钮层。
class BillPageBackToTop extends StatelessWidget {
  final bool isDark;
  final bool visible;
  final VoidCallback onTap;

  const BillPageBackToTop({
    super.key,
    required this.isDark,
    required this.visible,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: Style.backToTopSlideDurationMs),
      curve: Curves.easeOutCubic,
      offset: visible
          ? Offset.zero
          : const Offset(0, Style.backToTopHiddenOffsetY),
      child: AnimatedOpacity(
        duration: const Duration(
          milliseconds: Style.backToTopOpacityDurationMs,
        ),
        opacity: visible ? 1 : 0,
        child: IgnorePointer(
          ignoring: !visible,
          child: BackToTopButton(isDark: isDark, onTap: onTap),
        ),
      ),
    );
  }
}
