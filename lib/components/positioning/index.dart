import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app/components/positioning/style.dart';

/// 定位按钮组件。
///
/// 圆形白底带投影的按钮，中间显示定位图标。
/// 支持日间/夜间模式，图标颜色可外部传入。
/// 带淡入淡出动画效果。
class PositioningButton extends StatelessWidget {
  /// 是否显示。
  final bool show;

  /// 是否为夜间模式。
  final bool is_dark;

  /// 点击回调。
  final VoidCallback on_tap;

  /// 图标颜色（可选，不传则使用默认颜色）。
  final Color? icon_color;

  /// 右侧偏移。
  final double right;

  /// 底部偏移。
  final double bottom;

  const PositioningButton({
    super.key,
    required this.show,
    required this.is_dark,
    required this.on_tap,
    this.icon_color,
    this.right = 16.0,
    this.bottom = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    /// 背景色。
    final Color bg_color = is_dark
        ? PositioningStyle.bg_dark
        : PositioningStyle.bg_light;

    /// 阴影颜色。
    final Color shadow_color = Colors.black.withValues(
      alpha: is_dark
          ? PositioningStyle.shadow_opacity_dark
          : PositioningStyle.shadow_opacity_light,
    );

    /// 图标颜色。
    final Color effective_icon_color = icon_color ??
        (is_dark
            ? PositioningStyle.icon_color_dark
            : PositioningStyle.icon_color_light);

    return Positioned(
      right: right,
      bottom: bottom,
      child: AnimatedOpacity(
        duration: PositioningStyle.fade_duration,
        curve: Curves.easeOutCubic,
        opacity: show ? 1.0 : 0.0,
        child: IgnorePointer(
          ignoring: !show,
          child: GestureDetector(
            onTap: on_tap,
            child: Container(
              width: PositioningStyle.size,
              height: PositioningStyle.size,
              decoration: BoxDecoration(
                color: bg_color,
                borderRadius: BorderRadius.circular(
                  PositioningStyle.border_radius,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: shadow_color,
                    offset: PositioningStyle.shadow_offset,
                    blurRadius: PositioningStyle.shadow_blur_radius,
                    spreadRadius: PositioningStyle.shadow_spread_radius,
                  ),
                ],
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/svg/positioning.svg',
                  width: PositioningStyle.icon_size,
                  height: PositioningStyle.icon_size,
                  colorFilter: ColorFilter.mode(
                    effective_icon_color,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
