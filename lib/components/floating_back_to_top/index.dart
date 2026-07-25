import 'package:flutter/material.dart';
import 'package:app/components/back_to_top_button/index.dart';

/// 可复用的页面级“返回顶部”悬浮模块。
///
/// 负责：
/// 1. 统一管理右下角定位；
/// 2. 统一管理显隐动画；
/// 3. 统一接入 [BackToTopButton] 视觉样式。
class FloatingBackToTop extends StatelessWidget {
  /// 当前是否显示。
  final bool show;

  /// 当前是否夜间模式。
  final bool isDark;

  /// 按钮点击回调。
  final VoidCallback onTap;

  /// 右侧偏移。
  final double right;

  /// 显示态底部偏移。
  final double visibleBottom;

  /// 隐藏态底部偏移。
  final double hiddenBottom;

  /// 定位动画时长。
  final Duration positionDuration;

  /// 透明度动画时长。
  final Duration opacityDuration;

  const FloatingBackToTop({
    super.key,
    required this.show,
    required this.isDark,
    required this.onTap,
    required this.right,
    required this.visibleBottom,
    required this.hiddenBottom,
    this.positionDuration = const Duration(milliseconds: 220),
    this.opacityDuration = const Duration(milliseconds: 180),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: positionDuration,
      curve: Curves.easeOutCubic,
      right: right,
      bottom: show ? visibleBottom : hiddenBottom,
      child: IgnorePointer(
        ignoring: !show,
        child: AnimatedOpacity(
          duration: opacityDuration,
          curve: Curves.easeOutCubic,
          opacity: show ? 1 : 0,
          child: BackToTopButton(isDark: isDark, onTap: onTap),
        ),
      ),
    );
  }
}
