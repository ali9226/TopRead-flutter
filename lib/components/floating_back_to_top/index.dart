import 'package:app/components/back_to_top_button/index.dart';
import 'package:app/components/window_content_layout/index.dart';
import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';

/// 页面级回顶入口：以正文列的宽度和安全区定位，避免展开窗口后贴到屏幕边缘。
///
/// 放在 Stack 中。默认与页面公共左右边距对齐；Stack 本身已含正文边距时，
/// 将 [horizontalPadding] 设为零，避免重复留白。
class FloatingBackToTop extends StatelessWidget {
  const FloatingBackToTop({
    super.key,
    required this.show,
    required this.isDark,
    required this.onTap,
    required this.visibleBottom,
    required this.hiddenBottom,
    this.horizontalPadding = LayoutConfig.page_horizontal_padding,
    this.positionDuration = const Duration(milliseconds: 220),
    this.opacityDuration = const Duration(milliseconds: 180),
  }) : assert(horizontalPadding >= 0);

  final bool show;
  final bool isDark;
  final VoidCallback onTap;

  /// 当前正文列内部的左右边距，不含安全区或居中内容列之外的空间。
  final double horizontalPadding;
  final double visibleBottom;
  final double hiddenBottom;
  final Duration positionDuration;
  final Duration opacityDuration;

  @override
  Widget build(BuildContext context) {
    final reduce_motion = MediaQuery.disableAnimationsOf(context);
    return AnimatedPositioned(
      duration: reduce_motion ? Duration.zero : positionDuration,
      curve: Curves.easeOutCubic,
      left: 0,
      right: 0,
      bottom: show ? visibleBottom : hiddenBottom,
      child: IgnorePointer(
        ignoring: !show,
        child: WindowContentLayout(
          expand_height: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Align(
              alignment: Alignment.centerRight,
              heightFactor: 1,
              child: AnimatedOpacity(
                duration: reduce_motion ? Duration.zero : opacityDuration,
                curve: Curves.easeOutCubic,
                opacity: show ? 1 : 0,
                child: BackToTopButton(isDark: isDark, onTap: onTap),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
