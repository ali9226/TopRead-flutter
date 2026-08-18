import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';

import 'package:app/components/cute_mascot/index.dart';
import 'package:app/pages/change_password/style.dart';

/// 修改密码页面英雄区域组件。
///
/// 包含页面主标题、副标题和右侧猫咪吉祥物。
/// 标题和副标题居左，猫咪居右。
///
/// 参数说明：
/// [isCovering] - 猫咪是否处于遮眼状态。
/// [isDark] - 当前是否为夜间模式。
class HeroSection extends StatelessWidget {
  /// 猫咪是否处于遮眼状态。
  final bool isCovering;

  /// 当前是否为夜间模式。
  final bool isDark;

  const HeroSection({
    super.key,
    required this.isCovering,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        /// 左侧文字区域（标题）。
        Expanded(
          child: Text(
            easy.tr('UserInfo.change_password'),
            style: TextStyle(
              fontSize: Style.heroTitleSize,
              fontWeight: Style.heroTitleWeight,
              color: Style.titleColor(isDark: isDark),
            ),
          ),
        ),

        /// 右侧猫咪吉祥物（带遮眼动画）。
        SizedBox(
          width: Style.heroDecorationWidth,
          height: Style.heroDecorationHeight,
          child: CuteMascot(
            isCovering: isCovering,
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}
