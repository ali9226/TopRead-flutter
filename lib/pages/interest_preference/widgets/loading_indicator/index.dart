import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' as easy;

import 'package:app/config/color_config.dart';
import 'package:app/pages/interest_preference/style.dart';

/// 兴趣偏好页面加载中指示器组件。
///
/// 在页面初始加载用户偏好数据时居中显示，
/// 包含一个主题色转圈动画和"加载中..."提示文字。
/// 该组件不遮挡页面内容，仅作为视觉提示。
/// 支持日间/夜间主题切换。
class LoadingIndicator extends StatelessWidget {
  /// 是否为夜间模式。
  final bool isDark;

  const LoadingIndicator({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        /// 内容紧凑包裹，避免撑满整个屏幕。
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          /// 主题色转圈动画。
          CircularProgressIndicator(
            strokeWidth: 3,
            color: ColorConstants.themeColor,
          ),

          /// 转圈与文字之间的间距。
          const SizedBox(height: 16),

          /// 加载中提示文字，使用副标题颜色保持视觉一致。
          Text(
            easy.tr('interest_preference.loading'),
            style: TextStyle(
              fontSize: 14,
              color: InterestPreferenceStyle.subtitleColor(isDark: isDark),
            ),
          ),
        ],
      ),
    );
  }
}
