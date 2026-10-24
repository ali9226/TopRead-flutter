import 'package:app/config/layout_config.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import '../style.dart';
import 'package:app/config/font_config.dart';

/// 充值页顶部 Hero 卡片。
///
/// 专门负责展示页面标题、副标题和记录入口，
/// 让 index.dart 只保留页面结构装配和交互调度。
class TopUpHeroCard extends StatelessWidget {
  /// 当前是否为深色主题。
  final bool isDark;

  /// 点击“充值记录”后的回调。
  final VoidCallback onTapRecords;

  const TopUpHeroCard({
    super.key,
    required this.isDark,
    required this.onTapRecords,
  });

  @override
  Widget build(BuildContext context) {
    // Hero 主标题颜色。
    final Color textColor = isDark
        ? ColorConstants.whiteColor
        : ColorConstants.lightTextColor;

    // Hero 副标题颜色。
    final Color secondaryColor = isDark
        ? ColorConstants.whiteColor.withValues(alpha: 0.68)
        : ColorConstants.hintColor;

    // 右上记录入口按钮的背景色。
    final Color chipBackground = isDark
        ? ColorConstants.components_authorized_login_index_tone
        : ColorConstants.pages_short_story_read_index_tone_6bffffff;

    return Container(
      padding: Style.heroPadding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Style.heroRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const <Color>[ColorConstants.night_hero_card_top_warm, ColorConstants.night_hero_gradient_deep]
              : const <Color>[ColorConstants.gold_gradient_start, ColorConstants.gold_gradient_end],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: ColorConstants.shadowColor.withValues(alpha: isDark
                  ? Style.cardShadowDarkOpacity
                  : Style.cardShadowLightOpacity),
            blurRadius: Style.cardShadowBlur,
            offset: const Offset(0, Style.cardShadowOffsetY),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  easy.tr('top_up_page.title'),
                  style: TextStyle(
                    color: textColor,
                    fontSize: Style.heroTitleSize,
                    fontWeight: Style.heroTitleWeight,
                  ),
                ),
              ),
              const SizedBox(width: LayoutConfig.space_12),
              GestureDetector(
                // 记录入口放在 Hero 里，是为了把“查看历史充值”这个次级高频动作提到首屏。
                onTap: onTapRecords,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LayoutConfig.space_12,
                    vertical: LayoutConfig.space_8,
                  ),
                  decoration: BoxDecoration(
                    color: chipBackground,
                    borderRadius: BorderRadius.circular(
                      LayoutConfig.radius_pill,
                    ),
                    border: Border.all(
                      color: isDark
                          ? ColorConstants.components_authorized_login_index_tone
                          : ColorConstants.pages_top_up_widgets_top_up_hero_card_tone_57ffffff,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SvgIcon(
                        name: 'bill',
                        width: 14,
                        height: 14,
                        color: isDark ? ColorConstants.themeColor : textColor,
                      ),
                      const SizedBox(width: LayoutConfig.space_6),
                      Text(
                        easy.tr('top_up_qr_code_page.records'),
                        style: TextStyle(
                          color: textColor,
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
          const SizedBox(height: LayoutConfig.space_8),
          Text(
            easy.tr('top_up_page.subtitle'),
            style: TextStyle(
              color: secondaryColor,
              fontSize: Style.heroSubtitleSize,
              fontWeight: Style.heroSubtitleWeight,
            ),
          ),
        ],
      ),
    );
  }
}
