import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';
import '../style.dart';

/// 提现页顶部摘要卡。
///
/// 这个卡片专门负责告诉用户两件最关键的事实：
/// 1. 现在还有多少可提现余额。
/// 2. 当前最小/最大允许提现多少。
///
/// 让用户在真正输入金额前，先明确边界条件。
class WithdrawSummaryCard extends StatelessWidget {
  /// 当前是否为深色主题。
  final bool isDark;

  /// 已格式化的余额文本。
  final String balanceText;

  /// 已格式化的最小提现金额文本。
  final String minText;

  const WithdrawSummaryCard({
    super.key,
    required this.isDark,
    required this.balanceText,
    required this.minText,
  });

  @override
  Widget build(BuildContext context) {
    // 余额大数字使用的主色。
    final titleColor = isDark
        ? ColorConstants.whiteColor
        : ColorConstants.lightTextColor;

    // 标签和说明文案的次级颜色。
    final hintColor = isDark
        ? ColorConstants.whiteColor.withValues(
            alpha: WithdrawStyle.subtitleDarkOpacity,
          )
        : ColorConstants.hintColor;

    return Container(
      padding: WithdrawStyle.cardPadding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(WithdrawStyle.cardRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? WithdrawStyle.darkCardGradient
              : WithdrawStyle.lightCardGradient,
        ),
        border: Border.all(
          color: isDark
              ? const Color(0xFF8DB7FF).withValues(alpha: 0.14)
              : ColorConstants.themeColor.withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark
                  ? WithdrawStyle.cardShadowDarkOpacity
                  : WithdrawStyle.cardShadowLightOpacity,
            ),
            blurRadius: WithdrawStyle.cardShadowBlur,
            offset: const Offset(0, WithdrawStyle.cardShadowOffsetY),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            // 左上角主题色短条只承担“卡片标题锚点”的视觉作用。
            width: WithdrawStyle.headerAccentWidth,
            height: WithdrawStyle.headerAccentHeight,
            decoration: BoxDecoration(
              color: ColorConstants.themeColor,
              borderRadius: BorderRadius.circular(
                WithdrawStyle.headerAccentRadius,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            easy.tr('withdraw_page.balance_title'),
            style: TextStyle(
              color: hintColor,
              fontSize: WithdrawStyle.balanceHintSize,
              fontWeight: WithdrawStyle.balanceHintWeight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            balanceText,
            style: TextStyle(
              color: titleColor,
              fontSize: WithdrawStyle.balanceValueSize,
              fontWeight: WithdrawStyle.balanceValueWeight,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            // 下方的信息包裹区把“最小金额 / 最大金额”并排展示，
            // 避免两条信息分散到页面不同位置。
            width: double.infinity,
            padding: WithdrawStyle.summaryWrapPadding,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(
                      alpha: WithdrawStyle.summaryWrapDarkOpacity,
                    )
                  : Colors.black.withValues(
                      alpha: WithdrawStyle.summaryWrapLightOpacity,
                    ),
              borderRadius: BorderRadius.circular(
                WithdrawStyle.summaryWrapRadius,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _MiniMetric(
                    label: easy.tr('withdraw_page.min_amount'),
                    value: minText,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniMetric(
                    label: easy.tr('withdraw_page.max_amount'),
                    value: balanceText,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  /// 当前是否为深色主题。
  final bool isDark;

  /// 指标标题。
  final String label;

  /// 指标值。
  final String value;

  const _MiniMetric({
    required this.isDark,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark
                ? ColorConstants.whiteColor.withValues(alpha: 0.58)
                : ColorConstants.hintColor,
            fontSize: 11,
            fontWeight: FontConfig.adjustedWeight(FontWeight.w700),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            color: isDark
                ? ColorConstants.whiteColor
                : ColorConstants.lightTextColor,
            fontSize: 15,
            fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
