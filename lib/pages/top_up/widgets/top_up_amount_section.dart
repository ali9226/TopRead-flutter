import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';
import '../style.dart';

/// 充值金额选择区。
///
/// 只负责渲染金额网格和选中状态，金额格式化和点击后的业务处理由父层传入。
class TopUpAmountSection extends StatelessWidget {
  /// 当前是否为深色主题。
  final bool isDark;

  /// 可供选择的充值金额列表。
  final List<double> amountList;

  /// 当前已选中的充值金额。
  final double? selectedAmount;

  /// 金额格式化函数。
  final String Function(double amount) amountTextBuilder;

  /// 点击金额项后的回调。
  final ValueChanged<double> onTapAmount;

  const TopUpAmountSection({
    super.key,
    required this.isDark,
    required this.amountList,
    required this.selectedAmount,
    required this.amountTextBuilder,
    required this.onTapAmount,
  });

  @override
  Widget build(BuildContext context) {
    // Web 端不需要移动端那种轻微上移补偿，所以这里单独区分。
    final double amountGridTranslateY = kIsWeb ? 0 : Style.amountGridTranslateY;

    // 同理，Web 端顶部留白直接固定为更自然的视觉距离。
    final double amountGridTopSpacing = kIsWeb ? 20 : 0;

    /// Web 端为金额网格与卡片底边留出间距；移动端沿用 `amountSectionPadding` 底边 0。
    final EdgeInsets amountSectionPadding = kIsWeb
        ? EdgeInsets.fromLTRB(
            Style.amountSectionPadding.left,
            Style.amountSectionPadding.top,
            Style.amountSectionPadding.right,
            Style.amountSectionWebBottomPadding,
          )
        : Style.amountSectionPadding;

    return Container(
      padding: amountSectionPadding,
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
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          // 右上主光斑。
          Positioned(
            top: -18,
            right: -10,
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
          // 左侧辅助光斑。
          Positioned(
            top: 24,
            left: -8,
            child: IgnorePointer(
              child: Container(
                width: Style.sectionDecorSecondarySize,
                height: Style.sectionDecorSecondarySize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ColorConstants.successColor.withValues(
                    alpha: isDark
                        ? Style.sectionDecorDarkOpacity * 0.75
                        : Style.sectionDecorLightOpacity * 0.75,
                  ),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                easy.tr('top_up_page.amount_title'),
                style: TextStyle(
                  color: isDark
                      ? ColorConstants.whiteColor
                      : ColorConstants.lightTextColor,
                  fontSize: Style.sectionTitleSize,
                  fontWeight: Style.sectionTitleWeight,
                ),
              ),
              const SizedBox(height: Style.amountSectionTitleSpacing),
              Text(
                easy.tr('top_up_page.amount_hint'),
                style: TextStyle(
                  color: isDark
                      ? ColorConstants.whiteColor.withValues(alpha: 0.58)
                      : ColorConstants.hintColor,
                  fontSize: Style.sectionHintSize,
                  fontWeight: Style.sectionHintWeight,
                ),
              ),
              const SizedBox(height: Style.amountSectionHintSpacing),
              SizedBox(height: amountGridTopSpacing),
              Transform.translate(
                offset: Offset(0, amountGridTranslateY),
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    // 横屏时单个卡片最小宽度和间距都可以更紧凑一些，
                    // 让同一行尽量塞下更多金额项。
                    final bool isLandscape =
                        MediaQuery.of(context).orientation ==
                        Orientation.landscape;
                    final double gridSpacing = isLandscape
                        ? Style.amountGridLandscapeSpacing
                        : Style.amountGridSpacing;
                    final double tileMinWidth = isLandscape
                        ? Style.amountTileLandscapeMinWidth
                        : Style.amountTileMinWidth;
                    final double availableWidth = constraints.maxWidth;
                    final int rawCount =
                        ((availableWidth + gridSpacing) /
                                (tileMinWidth + gridSpacing))
                            .floor();
                    final int crossAxisCount = rawCount < (isLandscape ? 4 : 3)
                        ? (isLandscape ? 4 : 3)
                        : rawCount;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: amountList.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: gridSpacing,
                        crossAxisSpacing: gridSpacing,
                        childAspectRatio: isLandscape ? 2.05 : 1.72,
                      ),
                      itemBuilder: (BuildContext context, int index) {
                        final double amount = amountList[index];

                        // 当前金额卡片是否就是用户已经选中的那一项。
                        final bool selected = selectedAmount == amount;

                        return GestureDetector(
                          onTap: () => onTapAmount(amount),
                          child: AnimatedContainer(
                            duration: const Duration(
                              milliseconds: Style.amountTileAnimationMs,
                            ),
                            curve: Curves.easeOutCubic,
                            height: isLandscape
                                ? Style.amountTileLandscapeHeight
                                : Style.amountTileHeight,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                isLandscape
                                    ? Style.amountTileLandscapeRadius
                                    : Style.amountTileRadius,
                              ),
                              color: selected
                                  ? Style.accentColor.withValues(
                                      alpha: isDark ? 0.18 : 0.12,
                                    )
                                  : (isDark
                                        ? const Color(0xFF121521)
                                        : const Color(0xFFF8F8F4)),
                              border: Border.all(
                                color: selected
                                    ? Style.accentColor
                                    : (isDark
                                          ? Colors.white.withValues(alpha: 0.06)
                                          : Colors.black.withValues(
                                              alpha: 0.05,
                                            )),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(
                                milliseconds: Style.amountTileAnimationMs,
                              ),
                              curve: Curves.easeOutCubic,
                              style: TextStyle(
                                color: selected
                                    ? Style.accentColor
                                    : (isDark
                                          ? ColorConstants.whiteColor
                                          : ColorConstants.lightTextColor),
                                fontSize: isLandscape
                                    ? Style.amountTileLandscapeTextSize
                                    : Style.amountTileTextSize,
                                fontWeight: Style.amountTileTextWeight,
                              ),
                              child: Text(amountTextBuilder(amount)),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
