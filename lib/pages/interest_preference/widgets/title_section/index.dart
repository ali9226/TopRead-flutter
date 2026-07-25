import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' as easy;

import 'package:app/pages/interest_preference/style.dart';

/// 兴趣偏好页面标题区域组件。
///
/// 展示页面主标题和副标题，位于页面顶部可滚动内容区起始位置。
/// 支持日间/夜间主题切换。
class TitleSection extends StatelessWidget {
  /// 是否为夜间模式。
  final bool isDark;

  const TitleSection({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      /// 顶部留白，与导航栏拉开间距。
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          /// 页面主标题：引导用户选择兴趣偏好。
          Text(
            easy.tr('interest_preference.title'),
            style: TextStyle(
              fontSize: InterestPreferenceStyle.titleFontSize,
              fontWeight: InterestPreferenceStyle.titleFontWeight,
              color: InterestPreferenceStyle.titleColor(isDark: isDark),
            ),
          ),

          /// 主标题与副标题之间的间距。
          const SizedBox(height: InterestPreferenceStyle.titleBottomSpacing),

          /// 页面副标题：说明完善信息的作用。
          Text(
            easy.tr('interest_preference.subtitle'),
            style: TextStyle(
              fontSize: InterestPreferenceStyle.subtitleFontSize,
              fontWeight: InterestPreferenceStyle.subtitleFontWeight,
              color: InterestPreferenceStyle.subtitleColor(isDark: isDark),
            ),
          ),
        ],
      ),
    );
  }
}
