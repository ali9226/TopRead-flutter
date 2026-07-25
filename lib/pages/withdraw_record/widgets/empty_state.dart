import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';
import 'package:app/pages/withdraw_record/style.dart';

/// 提现记录空状态卡片。
///
/// 当列表没有任何记录时，用一个信息密度较低的卡片承接空态，
/// 避免页面只剩大片空白，用户也能快速判断“当前确实没有数据”。
class WithdrawRecordEmptyState extends StatelessWidget {
  /// 当前是否为深色主题。
  final bool isDark;

  const WithdrawRecordEmptyState({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // 空状态主文案颜色。
    final textColor = isDark
        ? ColorConstants.whiteColor
        : ColorConstants.lightTextColor;

    // 空状态副文案颜色。
    final secondaryColor = isDark
        ? ColorConstants.whiteColor.withValues(
            alpha: TopUpRecordStyle.emptySubtitleDarkOpacity,
          )
        : ColorConstants.hintColor;

    return Container(
      padding: TopUpRecordStyle.emptyCardPadding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171A27) : Colors.white,
        borderRadius: BorderRadius.circular(TopUpRecordStyle.emptyCardRadius),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(
                  alpha: TopUpRecordStyle.emptyCardBorderDarkOpacity,
                )
              : Colors.black.withValues(
                  alpha: TopUpRecordStyle.emptyCardBorderLightOpacity,
                ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark
                  ? TopUpRecordStyle.emptyCardShadowDarkOpacity
                  : TopUpRecordStyle.emptyCardShadowLightOpacity,
            ),
            blurRadius: TopUpRecordStyle.emptyCardShadowBlur,
            offset: const Offset(0, TopUpRecordStyle.emptyCardShadowOffsetY),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            // 圆形“0”徽标是空状态的视觉锚点，用最少元素提示“当前数量为零”。
            width: TopUpRecordStyle.emptyCircleSize,
            height: TopUpRecordStyle.emptyCircleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColorConstants.themeColor.withValues(
                alpha: isDark
                    ? TopUpRecordStyle.emptyCircleDarkOpacity
                    : TopUpRecordStyle.emptyCircleLightOpacity,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '0',
              style: TextStyle(
                color: textColor,
                fontSize: TopUpRecordStyle.emptyNumberSize,
                fontWeight: TopUpRecordStyle.emptyNumberWeight,
              ),
            ),
          ),
          const SizedBox(height: TopUpRecordStyle.emptyCircleBottomSpacing),
          Text(
            // 主标题告诉用户当前没有提现记录。
            context.tr('withdraw_record_page.empty_title'),
            style: TextStyle(
              color: textColor,
              fontSize: TopUpRecordStyle.emptyTitleSize,
              fontWeight: TopUpRecordStyle.emptyTitleWeight,
            ),
          ),
          const SizedBox(height: TopUpRecordStyle.emptyTitleBottomSpacing),
          Text(
            // 副标题进一步解释空态，降低用户困惑。
            context.tr('withdraw_record_page.empty_subtitle'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: secondaryColor,
              fontSize: TopUpRecordStyle.emptySubtitleSize,
              height: TopUpRecordStyle.emptySubtitleHeight,
              fontWeight: TopUpRecordStyle.emptySubtitleWeight,
            ),
          ),
        ],
      ),
    );
  }
}
