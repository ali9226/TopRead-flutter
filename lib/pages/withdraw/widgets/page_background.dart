import 'package:app/components/page_backdrop/index.dart';
import 'package:app/components/page_backdrop/style.dart';
import 'package:app/components/page_backdrop/widgets/decor_glow_spot.dart';
import 'package:app/config/color_config.dart';
import 'package:flutter/material.dart';

import '../style.dart';

/// 提现页背景层。
///
/// 只负责纯视觉底板：整页渐变与装饰光斑。
/// 拆出后路由页不必在主结构里堆 `Positioned`，页面骨架更易读。
class WithdrawPageBackground extends StatelessWidget {
  /// 当前是否为深色主题。
  final bool isDark;

  const WithdrawPageBackground({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        // 页面最底层的渐变底板，统一定义整页的冷暖色氛围。
        PageBackdropGradient(
          colors: isDark
              ? PageBackdropStyle.night_wallet_colors
              : WithdrawStyle.lightBackgroundGradient,
        ),
        // 右上角主光斑，强化顶部区域的视觉重心。
        DecorGlowSpot(
          size: WithdrawStyle.decorCircleOneSize,
          top: WithdrawStyle.decorCircleOneTop,
          right: WithdrawStyle.decorCircleOneRight,
          color: ColorConstants.themeColor.withValues(
            alpha: isDark
                ? WithdrawStyle.decorCircleOneDarkOpacity
                : WithdrawStyle.decorCircleOneLightOpacity,
          ),
        ),
        // 左侧辅助光斑，与右上角对角呼应，避免背景过于单薄。
        DecorGlowSpot(
          size: WithdrawStyle.decorCircleTwoSize,
          top: WithdrawStyle.decorCircleTwoTop,
          left: WithdrawStyle.decorCircleTwoLeft,
          color: ColorConstants.util_dialog_show_upgrade_dialog_tone_ff8db7ff
              .withValues(alpha: WithdrawStyle.decorCircleTwoOpacity),
        ),
      ],
    );
  }
}
