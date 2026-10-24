import 'package:app/config/color_config.dart';
import 'package:flutter/material.dart';

import '../style.dart';

/// 夜间模式底部导航装饰层。
///
/// 这个组件只负责纯视觉效果：
/// 1. 顶部柔光；
/// 2. 右下角柔和光晕；
/// 3. 左上角和左下角的环境光。
///
/// 需要感知底部安全距离，确保装饰覆盖完整高度。
class NightPanelDecor extends StatelessWidget {
  const NightPanelDecor({super.key});

  @override
  Widget build(BuildContext context) {
    final double bottom_inset = MediaQuery.viewPaddingOf(context).bottom;

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 顶部向下渐变的柔光
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  ColorConstants.util_dialog_show_upgrade_dialog_tone_fffffff,
                  ColorConstants.transparent,
                ],
              ),
            ),
          ),
          // 右下角柔和光晕
          Positioned(
            right: -40,
            bottom: -30 - bottom_inset,
            child: Container(
              width: 200,
              height: 200 + bottom_inset,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(0.3, 0.3),
                  radius: 0.8,
                  colors: [
                    ColorConstants.components_fixed_bottom_navigation_widgets_night_panel_decor_tone,
                    ColorConstants.util_dialog_show_upgrade_dialog_tone_fffffff,
                    ColorConstants.components_fixed_bottom_navigation_widgets_night_panel_decor_tone_5ffffff,
                    ColorConstants.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.6, 1.0],
                ),
              ),
            ),
          ),
          // 左上角柔和光晕
          Positioned(
            top: Style.night_highlight_top,
            left: Style.night_highlight_left,
            child: Container(
              width: Style.night_highlight_height,
              height: Style.night_highlight_height,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    ColorConstants.util_dialog_show_upgrade_dialog_tone_fffffff,
                    ColorConstants.transparent,
                  ],
                ),
              ),
            ),
          ),
          // 左下角环境光
          Positioned(
            left: Style.night_ambient_glow_left,
            bottom: Style.night_ambient_glow_bottom - bottom_inset,
            child: Container(
              width: Style.night_ambient_glow_size,
              height: Style.night_ambient_glow_size + bottom_inset,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    ColorConstants.util_dialog_show_upgrade_dialog_tone_1a8db7ff,
                    ColorConstants.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
