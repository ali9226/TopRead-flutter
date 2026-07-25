import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:app/components/language_selection/index.dart';

import '../style.dart';

/// 提现页顶部固定标题层。
///
/// 头部不仅负责展示标题，还负责做“顶部实色到底部透明”的渐变过渡，
/// 让固定标题和下方滚动内容衔接更自然。
class WithdrawPageHeader extends StatelessWidget {
  /// 当前是否为深色主题。
  final bool isDark;

  /// 页面基准背景色。
  ///
  /// 渐变的起止透明度会基于这个颜色生成，避免头部颜色和页面底板脱节。
  final Color backgroundColor;

  const WithdrawPageHeader({
    super.key,
    required this.isDark,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.only(
          bottom: WithdrawStyle.headerBottomFadeSpacing,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              backgroundColor.withValues(
                alpha: WithdrawStyle.headerGradientStartOpacity,
              ),
              backgroundColor.withValues(
                alpha: WithdrawStyle.headerGradientMiddleOpacity,
              ),
              backgroundColor.withValues(alpha: 0),
            ],
          ),
        ),
        child: LanguageSelection(
          darkBackground: isDark,
          title: easy.tr('withdraw_page.title'),
        ),
      ),
    );
  }
}
