import 'package:app/components/page_backdrop/index.dart';
import 'package:app/components/page_backdrop/style.dart';
import 'package:app/components/page_backdrop/widgets/decor_glow_spot.dart';
import 'package:app/config/color_config.dart';
import 'package:flutter/material.dart';

import '../style.dart';

/// 账单页背景装饰层。
///
/// 只负责铺底色和装饰光斑，把纯视觉层从主页面拆出去后，
/// `index.dart` 可以更聚焦在状态切换。
class BillPageBackground extends StatelessWidget {
  final bool isDark;

  const BillPageBackground({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        PageBackdropGradient(
          colors: isDark
              ? PageBackdropStyle.night_setting_colors
              : const <Color>[
                  ColorConstants.warm_page_gradient_start,
                  ColorConstants.warm_page_gradient_end,
                  ColorConstants.whiteColor,
                ],
        ),
        DecorGlowSpot(
          size: Style.decorCircleOneSize,
          top: Style.decorCircleOneTop,
          right: Style.decorCircleOneRight,
          color: ColorConstants.themeColor.withValues(
            alpha: isDark
                ? Style.decorCircleOneDarkOpacity
                : Style.decorCircleOneLightOpacity,
          ),
        ),
        DecorGlowSpot(
          size: Style.decorCircleTwoSize,
          top: Style.decorCircleTwoTop,
          left: Style.decorCircleTwoLeft,
          color: (isDark
                  ? ColorConstants.successColor
                  : ColorConstants.themeColor)
              .withValues(alpha: Style.decorCircleTwoOpacity),
        ),
      ],
    );
  }
}
