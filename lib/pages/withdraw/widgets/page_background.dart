import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

import '../style.dart';

/// 提现页背景层。
///
/// 这个组件只负责“纯视觉底板”：
/// 1. 从上到下的页面渐变。
/// 2. 右上和左侧的装饰光斑。
///
/// 把这部分单独拆出来后，路由页就不需要在主结构里堆很多 `Positioned`，
/// 页面骨架会更容易读。
class WithdrawPageBackground extends StatelessWidget {
  /// 当前是否为深色主题。
  final bool isDark;

  const WithdrawPageBackground({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        // 页面最底层的渐变底板，统一定义整页的冷暖色氛围。
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? WithdrawStyle.darkBackgroundGradient
                    : WithdrawStyle.lightBackgroundGradient,
              ),
            ),
          ),
        ),
        // 右上角主光斑，用来强化顶部区域的视觉重心。
        Positioned(
          top: WithdrawStyle.decorCircleOneTop,
          right: WithdrawStyle.decorCircleOneRight,
          child: IgnorePointer(
            child: Container(
              width: WithdrawStyle.decorCircleOneSize,
              height: WithdrawStyle.decorCircleOneSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ColorConstants.themeColor.withValues(
                  alpha: isDark
                      ? WithdrawStyle.decorCircleOneDarkOpacity
                      : WithdrawStyle.decorCircleOneLightOpacity,
                ),
              ),
            ),
          ),
        ),
        // 左侧辅助光斑，和右上角形成对角呼应，避免背景过于单薄。
        Positioned(
          top: WithdrawStyle.decorCircleTwoTop,
          left: WithdrawStyle.decorCircleTwoLeft,
          child: IgnorePointer(
            child: Container(
              width: WithdrawStyle.decorCircleTwoSize,
              height: WithdrawStyle.decorCircleTwoSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(
                  0xFF8DB7FF,
                ).withValues(alpha: WithdrawStyle.decorCircleTwoOpacity),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
