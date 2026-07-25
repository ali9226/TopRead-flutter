import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:app/pages/short_story_read/style.dart';

/// 正文页面右下角浮动按钮。
///
/// 圆形按钮，中间显示旋转 180° 的 up.svg 图标，
/// 带轻微投影效果，支持日间/夜间主题。
///
/// 外部通过 [opacity] 控制淡入淡出（0.0 ~ 1.0），
/// 与顶部导航栏和底部评论栏的显示/隐藏时机保持一致。
///
/// 注意：本组件不包含 [Positioned]，由调用方在 [Stack] 中定位。
class ScrollToBottomButton extends StatelessWidget {
  /// 是否为夜间模式。
  final bool is_dark;

  /// 透明度（0.0 = 完全隐藏，1.0 = 完全显示）。
  final double opacity;

  /// 点击回调。
  final VoidCallback on_tap;

  const ScrollToBottomButton({
    super.key,
    required this.is_dark,
    required this.opacity,
    required this.on_tap,
  });

  @override
  Widget build(BuildContext context) {
    /// 背景色。
    final Color bg_color = is_dark
        ? ShortStoryReadStyle.card_dark_bg
        : ShortStoryReadStyle.card_light_bg;

    /// 图标颜色（与底部评论栏图标/文字颜色一致）。
    final Color icon_color = is_dark
        ? ShortStoryReadStyle.secondary_dark_color
        : ShortStoryReadStyle.secondary_light_color;

    /// 投影颜色。
    final Color shadow_color = is_dark
        ? Colors.black.withValues(alpha: 0.35)
        : Colors.black.withValues(alpha: 0.12);

    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTap: on_tap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bg_color,
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: shadow_color,
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Transform.rotate(
              angle: 3.14159,
              child: SvgPicture.asset(
                'assets/svg/up.svg',
                width: 16,
                height: 16,
                colorFilter: ColorFilter.mode(icon_color, BlendMode.srcIn),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
