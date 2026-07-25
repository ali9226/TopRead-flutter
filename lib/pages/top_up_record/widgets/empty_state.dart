import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

import '../style.dart';

/// 充值记录页空状态组件。
///
/// 当列表为空且当前不在 loading 时，由页面展示这个组件。
class TopUpRecordEmptyState extends StatelessWidget {
  final bool isDark;

  const TopUpRecordEmptyState({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // 空状态和正文卡片保持同一套色彩体系，但对比度更柔和。
    final textColor = isDark
        ? ColorConstants.whiteColor
        : ColorConstants.lightTextColor;
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
            easy.tr('top_up_record_page.empty_title'),
            style: TextStyle(
              color: textColor,
              fontSize: TopUpRecordStyle.emptyTitleSize,
              fontWeight: TopUpRecordStyle.emptyTitleWeight,
            ),
          ),
          const SizedBox(height: TopUpRecordStyle.emptyTitleBottomSpacing),
          Text(
            easy.tr('top_up_record_page.empty_subtitle'),
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
