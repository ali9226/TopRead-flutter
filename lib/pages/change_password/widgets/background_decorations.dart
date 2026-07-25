import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';
import 'package:app/pages/change_password/style.dart';

/// 修改密码页面背景装饰组件。
///
/// 包含：
/// 1. 页面背景渐变。
/// 2. 右上角主题色装饰光斑。
/// 3. 左侧绿色辅助光斑。
/// 4. 顶部边缘淡出过渡层。
///
/// 参数说明：
/// [isDark] - 当前是否为夜间模式。
/// [safePaddingTop] - 顶部安全区高度。
class BackgroundDecorations extends StatelessWidget {
  /// 当前是否为夜间模式。
  final bool isDark;

  /// 顶部安全区高度。
  final double safePaddingTop;

  const BackgroundDecorations({
    super.key,
    required this.isDark,
    required this.safePaddingTop,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        /// 页面背景渐变。
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? Style.darkBackgroundGradient
                    : Style.lightBackgroundGradient,
              ),
            ),
          ),
        ),

        /// 右上装饰光斑（主题色圆形，半透明）。
        Positioned(
          top: Style.decorCircleOneTop + safePaddingTop,
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

        /// 左侧辅助光斑（绿色圆形，低透明度）。
        Positioned(
          top: Style.decorCircleTwoTop + safePaddingTop,
          left: Style.decorCircleTwoLeft,
          child: IgnorePointer(
            child: Container(
              width: Style.decorCircleTwoSize,
              height: Style.decorCircleTwoSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ColorConstants.successColor.withValues(
                  alpha: Style.decorCircleTwoOpacity,
                ),
              ),
            ),
          ),
        ),

        /// 顶部边缘淡出过渡层（白/深色到透明的渐变，衔接导航栏与内容）。
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Container(
              height: safePaddingTop + Style.pageEdgeFadeHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Style.backgroundColor(isDark: isDark)
                        .withValues(alpha: isDark ? 0.18 : 0.96),
                    Style.backgroundColor(isDark: isDark)
                        .withValues(alpha: isDark ? 0.06 : 0.52),
                    Style.backgroundColor(isDark: isDark).withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
