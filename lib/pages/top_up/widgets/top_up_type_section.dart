import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/transaction_inquire_type.dart';
import '../style.dart';

/// 充值类型选择区。
///
/// 负责展示当前选中类型和触发底部弹层，不直接管理状态。
class TopUpTypeSection extends StatelessWidget {
  /// 当前是否为深色主题。
  final bool isDark;

  /// 当前选中的充值方式对象。
  final TransactionInquireTypeItem? selectedType;

  /// 当前要展示的充值方式文案。
  final String selectedTitleText;

  /// 点击整个选择区后的回调。
  final VoidCallback onTap;

  const TopUpTypeSection({
    super.key,
    required this.isDark,
    required this.selectedType,
    required this.selectedTitleText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _TopUpPanel(
      isDark: isDark,
      title: easy.tr('top_up_page.type_title'),
      hint: easy.tr('top_up_page.type_hint'),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          // 右上主光斑。
          Positioned(
            top: -10,
            right: -6,
            child: IgnorePointer(
              child: Container(
                width: Style.sectionDecorPrimarySize,
                height: Style.sectionDecorPrimarySize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Style.accentColor.withValues(
                    alpha: isDark
                        ? Style.sectionDecorDarkOpacity
                        : Style.sectionDecorLightOpacity,
                  ),
                ),
              ),
            ),
          ),
          // 左下辅助光斑。
          Positioned(
            bottom: -12,
            left: 14,
            child: IgnorePointer(
              child: Container(
                width: Style.sectionDecorSecondarySize,
                height: Style.sectionDecorSecondarySize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ColorConstants.successColor.withValues(
                    alpha: isDark
                        ? Style.sectionDecorDarkOpacity * 0.8
                        : Style.sectionDecorLightOpacity * 0.8,
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            // 整个选择区都可点击，避免只点小箭头才有反应。
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              height: Style.typeSelectorHeight,
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Style.typeSelectorRadius),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Style.accentColor.withValues(
                      alpha: selectedType == null
                          ? Style.typeSelectorGradientEndOpacity
                          : Style.typeSelectorGradientStartOpacity,
                    ),
                    Colors.white.withValues(
                      alpha: isDark
                          ? Style.typeSelectorGradientEndOpacity
                          : Style.typeSelectorHighlightOpacity,
                    ),
                  ],
                ),
              ),
              child: Container(
                padding: Style.typeSelectorPadding,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    Style.typeSelectorInnerRadius,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? const <Color>[Color(0xFF1A1F2D), Color(0xFF111420)]
                        : const <Color>[Color(0xFFFFFCF4), Color(0xFFF7F5EE)],
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      // 左侧圆形图标区负责建立“支付类型”的视觉识别。
                      width: Style.typeIconWrapSize,
                      height: Style.typeIconWrapSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selectedType != null
                            ? Style.accentColor.withValues(alpha: 0.18)
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.black.withValues(alpha: 0.04)),
                      ),
                      child: Center(
                        child: SvgIcon(
                          name: 'usdt',
                          width: Style.typeIconSize,
                          height: Style.typeIconSize,
                          color: selectedType != null
                              ? Style.accentColor
                              : ColorConstants.successColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            easy.tr('top_up_page.type_title'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark
                                  ? ColorConstants.whiteColor.withValues(
                                      alpha: 0.48,
                                    )
                                  : ColorConstants.hintColor,
                              fontSize: Style.typeSelectorCaptionSize,
                              fontWeight: FontConfig.adjustedWeight(FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: Style.typeSelectorTextSpacing),
                          Text(
                            selectedTitleText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark
                                  ? ColorConstants.whiteColor
                                  : ColorConstants.lightTextColor,
                              fontSize: Style.typeSelectorValueSize,
                              fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      // 右侧箭头区域明确提示“这里会展开下一级选择”。
                      width: Style.typeSelectorTrailingWidth,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: selectedType != null
                            ? Style.accentColor.withValues(
                                alpha: isDark ? 0.16 : 0.12,
                              )
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.035)),
                      ),
                      child: Center(
                        child: Transform.rotate(
                          angle: 1.5708,
                          child: SvgIcon(
                            name: 'right',
                            width: 14,
                            height: 14,
                            color: selectedType != null
                                ? Style.accentColor
                                : (isDark
                                      ? ColorConstants.whiteColor.withValues(
                                          alpha: 0.70,
                                        )
                                      : ColorConstants.hintColor),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopUpPanel extends StatelessWidget {
  /// 当前是否为深色主题。
  final bool isDark;

  /// 区块标题。
  final String title;

  /// 区块说明文案。
  final String hint;

  /// 区块实际内容。
  final Widget child;

  const _TopUpPanel({
    required this.isDark,
    required this.title,
    required this.hint,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: Style.cardPadding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171A27) : Colors.white,
        borderRadius: BorderRadius.circular(Style.cardRadius),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
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
          Text(
            title,
            style: TextStyle(
              color: isDark
                  ? ColorConstants.whiteColor
                  : ColorConstants.lightTextColor,
              fontSize: Style.sectionTitleSize,
              fontWeight: Style.sectionTitleWeight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            style: TextStyle(
              color: isDark
                  ? ColorConstants.whiteColor.withValues(alpha: 0.58)
                  : ColorConstants.hintColor,
              fontSize: Style.sectionHintSize,
              fontWeight: Style.sectionHintWeight,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
