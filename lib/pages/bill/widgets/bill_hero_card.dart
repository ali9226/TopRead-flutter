import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

import '../style.dart';

/// 账单页顶部 Hero 卡片。
///
/// 这个区域的主要职责不是展示具体业务数据，
/// 而是先给页面建立“这是一张资金流水页”的语义锚点和视觉开场。
class BillHeroCard extends StatelessWidget {
  /// 当前主题是否为深色模式。
  final bool isDark;

  const BillHeroCard({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    /// Hero 主标题颜色。
    final Color textColor = isDark
        ? ColorConstants.whiteColor
        : ColorConstants.lightTextColor;

    /// Hero 副标题颜色。
    /// 需要比主标题更弱，避免两行信息竞争视觉焦点。
    final Color secondaryColor = isDark
        ? ColorConstants.whiteColor.withValues(
            alpha: Style.heroSubtitleDarkOpacity,
          )
        : ColorConstants.hintColor;

    return Container(
      /// Hero 卡片内边距比普通卡片更大，让开场区域更舒展。
      padding: Style.heroPadding,
      decoration: BoxDecoration(
        /// 大圆角让它和列表卡片形成层级差异。
        borderRadius: BorderRadius.circular(Style.heroRadius),
        gradient: LinearGradient(
          /// 使用从左上到右下的渐变，给顶部区域更多体积感。
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const <Color>[Color(0xFF262B3F), Color(0xFF181B29)]
              : const <Color>[Color(0xFFFFF2B2), Color(0xFFF1D875)],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            /// 柔和阴影把 Hero 区从页面背景中提出来。
            color: Colors.black.withValues(
              alpha: isDark
                  ? Style.heroShadowDarkOpacity
                  : Style.heroShadowLightOpacity,
            ),
            blurRadius: Style.heroShadowBlur,
            offset: const Offset(0, Style.heroShadowOffsetY),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            /// 页面主标题。
            easy.tr('bill.title'),
            style: TextStyle(
              color: textColor,
              fontSize: Style.heroTitleSize,
              fontWeight: Style.heroTitleWeight,
              letterSpacing: Style.heroTitleLetterSpacing,
            ),
          ),
          const SizedBox(height: Style.heroTitleBottomSpacing),
          Text(
            /// 副标题用“类型 / 时间 / 金额”串起当前页面最核心的三类信息维度，
            /// 提前告诉用户下面的账单卡片重点会展示什么。
            '${easy.tr('bill.type')} · ${easy.tr('bill.time')} · ${easy.tr('bill.amount')}',
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
