import 'package:flutter/material.dart';
import 'package:app/components/page_top_gradient_overlay/style.dart';
import 'package:app/components/top_header_gradient/index.dart';

/// 页面顶部渐变过渡公共组件。
class PageTopGradientOverlay extends StatelessWidget {
  /// 页面背景色。
  final Color background_color;

  const PageTopGradientOverlay({super.key, required this.background_color});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: TopHeaderGradient(
          background_color: background_color,
          height: PageTopGradientOverlayStyle.height,
          start_opacity: PageTopGradientOverlayStyle.start_opacity,
          middle_opacity: PageTopGradientOverlayStyle.middle_opacity,
        ),
      ),
    );
  }
}
