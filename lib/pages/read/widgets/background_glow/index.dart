import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';
import './style.dart';

/// 阅读页顶部背景光斑组件。
///
/// 提供纯视觉氛围层，不参与滚动、点击或数据渲染。
/// 通过两个不同颜色的圆形光斑营造出光感背景效果。
class ReadBackgroundGlow extends StatelessWidget {
  /// 当前是否为夜间主题，用于区分光斑透明度与颜色。
  final bool is_dark;

  const ReadBackgroundGlow({super.key, required this.is_dark});

  @override
  Widget build(BuildContext context) {
    // 日间模式下第一层主题光斑更亮，夜间模式下透明度降低避免刺眼。
    final Color first_glow_color = ColorConstants.themeColor.withValues(
      alpha: is_dark
          ? BackgroundGlowStyle.top_glow_one_night_alpha
          : BackgroundGlowStyle.top_glow_one_light_alpha,
    );
    // 第二层辅助光斑在夜间偏冷色、日间偏暖色，强化顶部层次感。
    final Color second_glow_color = is_dark
        ? const Color(
            0xFF8DB7FF,
          ).withValues(alpha: BackgroundGlowStyle.top_glow_two_night_alpha)
        : const Color(
            0xFFFFC76A,
          ).withValues(alpha: BackgroundGlowStyle.top_glow_two_light_alpha);

    return Stack(
      children: <Widget>[
        // 第一层圆形光斑固定在左上角偏外侧位置。
        Positioned(
          top: BackgroundGlowStyle.top_glow_one_top,
          left: BackgroundGlowStyle.top_glow_one_left,
          child: IgnorePointer(
            child: Container(
              width: BackgroundGlowStyle.top_glow_one_size,
              height: BackgroundGlowStyle.top_glow_one_size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: first_glow_color,
              ),
            ),
          ),
        ),
        // 第二层圆形光斑固定在右上角偏外侧位置。
        Positioned(
          top: BackgroundGlowStyle.top_glow_two_top,
          right: BackgroundGlowStyle.top_glow_two_right,
          child: IgnorePointer(
            child: Container(
              width: BackgroundGlowStyle.top_glow_two_size,
              height: BackgroundGlowStyle.top_glow_two_size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: second_glow_color,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
