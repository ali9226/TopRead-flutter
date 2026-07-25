import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';
import 'package:app/pages/withdraw_record/style.dart';

/// 提现记录页顶部 Hero 卡片。
///
/// 它的作用不是展示业务明细，而是先建立页面标题和语义氛围，
/// 让记录页进入后第一眼就能知道当前位置。
class WithdrawRecordHeroCard extends StatelessWidget {
  /// 当前是否为深色主题。
  final bool isDark;

  const WithdrawRecordHeroCard({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Hero 主标题颜色。
    final textColor = isDark
        ? ColorConstants.whiteColor
        : ColorConstants.lightTextColor;

    // Hero 副标题颜色。
    final secondaryColor = isDark
        ? ColorConstants.whiteColor.withValues(
            alpha: TopUpRecordStyle.heroSubtitleDarkOpacity,
          )
        : ColorConstants.hintColor;

    return Container(
      padding: TopUpRecordStyle.heroPadding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TopUpRecordStyle.heroRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? TopUpRecordStyle.darkHeroGradient
              : TopUpRecordStyle.lightHeroGradient,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark
                  ? TopUpRecordStyle.heroShadowDarkOpacity
                  : TopUpRecordStyle.heroShadowLightOpacity,
            ),
            blurRadius: TopUpRecordStyle.heroShadowBlur,
            offset: const Offset(0, TopUpRecordStyle.heroShadowOffsetY),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('withdraw_record_page.title'),
            style: TextStyle(
              color: textColor,
              fontSize: TopUpRecordStyle.heroTitleSize,
              fontWeight: TopUpRecordStyle.heroTitleWeight,
            ),
          ),
          const SizedBox(height: TopUpRecordStyle.heroTitleBottomSpacing),
          Text(
            context.tr('withdraw_record_page.subtitle'),
            style: TextStyle(
              color: secondaryColor,
              fontSize: TopUpRecordStyle.heroSubtitleSize,
              height: TopUpRecordStyle.heroSubtitleHeight,
              fontWeight: TopUpRecordStyle.heroSubtitleWeight,
            ),
          ),
        ],
      ),
    );
  }
}
