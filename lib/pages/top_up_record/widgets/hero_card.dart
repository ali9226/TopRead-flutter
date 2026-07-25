import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

import '../style.dart';

/// 充值记录页顶部 hero 卡片。
///
/// 职责很单一：
/// 只负责展示页面标题和说明文案，不参与任何业务逻辑。
class TopUpRecordHeroCard extends StatelessWidget {
  final bool isDark;

  const TopUpRecordHeroCard({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // 深浅主题下分别取更合适的主副文案颜色。
    final textColor = isDark
        ? ColorConstants.whiteColor
        : ColorConstants.lightTextColor;
    final secondaryColor = isDark
        ? ColorConstants.whiteColor.withValues(
            alpha: TopUpRecordStyle.heroSubtitleDarkOpacity,
          )
        : ColorConstants.hintColor;

    return Container(
      // 整块卡片使用和充值页一致的金色 / 深蓝渐变语言，保持视觉连续性。
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
            easy.tr('top_up_record_page.title'),
            style: TextStyle(
              color: textColor,
              fontSize: TopUpRecordStyle.heroTitleSize,
              fontWeight: TopUpRecordStyle.heroTitleWeight,
            ),
          ),
          const SizedBox(height: TopUpRecordStyle.heroTitleBottomSpacing),
          Text(
            easy.tr('top_up_record_page.subtitle'),
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
