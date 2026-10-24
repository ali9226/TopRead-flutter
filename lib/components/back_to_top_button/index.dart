import 'package:flutter/material.dart';

import 'style.dart';

/// 共用回顶按钮。定位和显隐由 FloatingBackToTop 处理，点击由页面提供。
class BackToTopButton extends StatelessWidget {
  const BackToTopButton({super.key, required this.isDark, this.onTap});

  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: BackToTopButtonStyle.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BackToTopButtonStyle.radius,
      splashColor: BackToTopButtonStyle.splash,
      highlightColor: BackToTopButtonStyle.pressed,
      child: Container(
        width: BackToTopButtonStyle.size,
        height: BackToTopButtonStyle.size,
        decoration: BoxDecoration(
          borderRadius: BackToTopButtonStyle.radius,
          color: BackToTopButtonStyle.fill(isDark),
          border: Border.all(
            color: BackToTopButtonStyle.border(isDark),
            width: BackToTopButtonStyle.border_width,
          ),
          boxShadow: BackToTopButtonStyle.shadows(isDark),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BackToTopButtonStyle.radius,
            gradient: RadialGradient(
              center: BackToTopButtonStyle.highlight_center,
              radius: BackToTopButtonStyle.highlight_radius,
              colors: BackToTopButtonStyle.highlights(isDark),
              stops: BackToTopButtonStyle.highlight_stops,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.keyboard_double_arrow_up_rounded,
              size: BackToTopButtonStyle.icon_size,
              color: BackToTopButtonStyle.ink(isDark),
            ),
          ),
        ),
      ),
    ),
  );
}
