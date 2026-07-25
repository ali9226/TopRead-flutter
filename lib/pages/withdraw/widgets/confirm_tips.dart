import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';
import '../style.dart';

/// 提现确认弹窗底部提示。
///
/// 这里统一承接提现前需要再次提醒用户的风险文案，
/// 避免这些说明散落在弹窗主体里影响主信息阅读。
class ConfirmTips extends StatelessWidget {
  /// 当前是否为深色主题。
  final bool isDark;

  const ConfirmTips({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // 依赖 locale，确保语言切换后提示文案即时刷新。
    Localizations.localeOf(context);

    // 正文提示颜色。
    final Color textColor = isDark
        ? ColorConstants.whiteColor.withValues(alpha: 0.60)
        : ColorConstants.lightTextColor.withValues(alpha: 0.58);

    // 标题颜色。
    final Color titleColor = isDark
        ? ColorConstants.whiteColor
        : ColorConstants.lightTextColor;

    // 当前弹窗要展示的注意事项列表。
    final List<String> items = <String>[
      easy.tr('withdraw_page.notice_2'),
      easy.tr('withdraw_page.notice_3'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            easy.tr('withdraw_page.notice_title'),
            style: TextStyle(
              color: titleColor,
              fontSize: WithdrawStyle.submitTipsTitleSize,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: WithdrawStyle.submitTipsBottomSpacing),
          ...items.map((String item) {
            return Padding(
              // 每一条提示单独留出底部间距，避免长文案挤成一团。
              padding: const EdgeInsets.only(
                bottom: WithdrawStyle.submitTipsItemSpacing,
              ),
              child: Text(
                item,
                style: TextStyle(
                  color: textColor,
                  fontSize: WithdrawStyle.submitTipsFontSize,
                  fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
                  height: 1.55,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
