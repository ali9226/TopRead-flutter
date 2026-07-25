import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

import '../style.dart';

/// 账单页背景装饰层。
///
/// 这个组件只负责铺底色和装饰光斑，
/// 把纯视觉层从主页面拆出去后，`index.dart` 可以更聚焦在状态切换。
class BillPageBackground extends StatelessWidget {
  final bool isDark;

  const BillPageBackground({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? const <Color>[
                        Color(0xFF1A1D2C),
                        Color(0xFF12121C),
                        Color(0xFF0D0E14),
                      ]
                    : const <Color>[
                        Color(0xFFF6F0D8),
                        Color(0xFFF7F7F3),
                        Color(0xFFFFFFFF),
                      ],
              ),
            ),
          ),
        ),
        Positioned(
          top: Style.decorCircleOneTop,
          right: Style.decorCircleOneRight,
          child: IgnorePointer(
            child: Container(
              width: Style.decorCircleOneSize,
              height: Style.decorCircleOneSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ColorConstants.themeColor.withValues(
                  alpha: isDark
                      ? Style.decorCircleOneDarkOpacity
                      : Style.decorCircleOneLightOpacity,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: Style.decorCircleTwoTop,
          left: Style.decorCircleTwoLeft,
          child: IgnorePointer(
            child: Container(
              width: Style.decorCircleTwoSize,
              height: Style.decorCircleTwoSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    (isDark
                            ? ColorConstants.successColor
                            : ColorConstants.themeColor)
                        .withValues(alpha: Style.decorCircleTwoOpacity),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
