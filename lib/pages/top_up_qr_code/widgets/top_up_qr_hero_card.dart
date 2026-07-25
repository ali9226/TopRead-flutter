import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/recharge_add_result.dart';
import '../style.dart';

/// 充值二维码页顶部金额摘要卡。
///
/// 负责集中展示当前支付金额和记录入口，避免主页面同时管理标题结构和二维码逻辑。
class TopUpQrHeroCard extends StatelessWidget {
  /// 当前是否为深色主题。
  final bool isDark;

  /// 当前充值订单详情。
  ///
  /// 为空时说明详情还没拉回来，金额区会先显示占位值。
  final RechargeAddResult? detail;

  /// 已格式化的金额文案。
  final String amountText;

  /// 点击“记录”后的回调。
  final VoidCallback onTapRecords;

  const TopUpQrHeroCard({
    super.key,
    required this.isDark,
    required this.detail,
    required this.amountText,
    required this.onTapRecords,
  });

  @override
  Widget build(BuildContext context) {
    // 金额主文案颜色。
    final Color amountTextColor = isDark
        ? ColorConstants.whiteColor
        : ColorConstants.lightTextColor;

    // 右上记录入口按钮背景色。
    final Color recordsChipBackground = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.42);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Style.cardRadius),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.06),
            blurRadius: Style.cardShadowBlur,
            offset: const Offset(0, Style.cardShadowOffsetY),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          // 整张卡的主背景渐变。
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? const <Color>[Color(0xFF263046), Color(0xFF181C29)]
                      : const <Color>[Color(0xFFFFF2B2), Color(0xFFF0D86B)],
                ),
              ),
            ),
          ),
          // 右上浅色光斑。
          Positioned(
            top: -38,
            right: -18,
            child: Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.22),
              ),
            ),
          ),
          // 左下深色圆斑。
          Positioned(
            bottom: -34,
            left: -12,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: isDark ? 0.10 : 0.05),
              ),
            ),
          ),
          Padding(
            padding: Style.heroPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        easy.tr('top_up_qr_code_page.amount_label'),
                        style: TextStyle(
                          color: isDark
                              ? ColorConstants.whiteColor.withValues(alpha: 0.74)
                              : ColorConstants.lightTextColor.withValues(
                                  alpha: 0.72,
                                ),
                          fontSize: 12,
                          fontWeight: FontConfig.adjustedWeight(FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      // 记录入口放在金额卡右上角，方便用户在付款流程中快速切去看历史记录。
                      onTap: onTapRecords,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: recordsChipBackground,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.10)
                                : Colors.white.withValues(alpha: 0.34),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            SvgIcon(
                              name: 'bill',
                              width: 14,
                              height: 14,
                              color: isDark
                                  ? ColorConstants.themeColor
                                  : amountTextColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              easy.tr('top_up_qr_code_page.records'),
                              style: TextStyle(
                                color: amountTextColor,
                                fontSize: 12,
                                fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  // 详情未就绪时先显示占位值，避免金额区域直接留空。
                  detail == null ? '--' : amountText,
                  style: TextStyle(
                    color: amountTextColor,
                    fontSize: Style.amountValueSize,
                    fontWeight: FontConfig.adjustedWeight(FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  easy.tr('top_up_qr_code_page.amount_hint'),
                  style: TextStyle(
                    color: isDark
                        ? ColorConstants.whiteColor.withValues(alpha: 0.64)
                        : ColorConstants.lightTextColor.withValues(alpha: 0.64),
                    fontSize: 12,
                    fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
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
