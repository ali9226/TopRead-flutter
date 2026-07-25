import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';

import 'package:app/components/cute_mascot/index.dart';
import 'package:app/pages/change_password/style.dart';
import 'package:app/util/language_util/index.dart';

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
    /// 根据当前语种判断是否为 CJK，用于调整副标题行高。
    final bool is_cjk = LanguageUtil.is_cjk_language(
      context.locale.languageCode,
    );
    final double subtitle_height = is_cjk
        ? Style.heroSubtitleHeightCjk
        : Style.heroSubtitleHeightAlphabetic;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// 左侧文字区域（标题 + 副标题）。
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              /// 页面主标题（"修改密码"）。
              Text(
                easy.tr('UserInfo.change_password'),
                style: TextStyle(
                  fontSize: Style.heroTitleSize,
                  fontWeight: Style.heroTitleWeight,
                  color: Style.titleColor(isDark: isDark),
                ),
              ),
              const SizedBox(height: 8),

              /// 页面副标题（"设置一个新的登录密码…"）。
              Text(
                easy.tr('UserInfo.change_password_subtitle'),
                style: TextStyle(
                  fontSize: Style.heroSubtitleSize,
                  height: subtitle_height,
                  fontWeight: Style.heroSubtitleWeight,
                  color: Style.subtitleColor(isDark: isDark),
                ),
              ),
            ],
          ),
        ),

        /// 右侧猫咪吉祥物（带遮眼动画）。
        SizedBox(
          width: Style.heroDecorationWidth,
          height: Style.heroDecorationHeight,
          child: Center(
            child: CuteMascot(
              isCovering: isCovering,
              isDark: isDark,
            ),
          ),
        ),
      ],
    );
  }
}
