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
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.42);

    return Container(
      padding: Style.heroPadding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Style.heroRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const <Color>[Color(0xFF263046), Color(0xFF181C29)]
              : const <Color>[Color(0xFFFFF2B2), Color(0xFFF1D875)],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark
                  ? Style.cardShadowDarkOpacity
                  : Style.cardShadowLightOpacity,
            ),
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
              const SizedBox(width: 12),
              GestureDetector(
                // 记录入口放在 Hero 里，是为了把“查看历史充值”这个次级高频动作提到首屏。
                onTap: onTapRecords,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: chipBackground,
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
                        color: isDark ? ColorConstants.themeColor : textColor,
                      ),
                      const SizedBox(width: 6),
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
          const SizedBox(height: 8),
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
