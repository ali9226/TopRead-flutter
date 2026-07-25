import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

import '../style.dart';

/// 账单页空状态卡片。
///
/// 当接口没有返回任何账单，或者用户当前还没有产生流水记录时，
/// 页面会用这个组件替代列表内容，给出明确的无数据反馈和重试入口。
class BillEmptyState extends StatelessWidget {
  /// 当前主题是否为深色模式。
  final bool isDark;

  /// 空状态中央圆形数字里的展示文本。
  ///
  /// 当前账单页传的是 `0`，但保留成入参后，
  /// 后续如果要展示其它统计值也不需要改组件结构。
  final String emptyNumberText;

  /// 点击“重新加载”按钮时的回调。
  final VoidCallback onReload;

  const BillEmptyState({
    super.key,
    required this.isDark,
    required this.emptyNumberText,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      /// 给整个空状态卡片一组更宽松的内边距，
      /// 让它和普通账单卡片在气质上区分开来。
      padding: Style.emptyCardPadding,
      decoration: BoxDecoration(
        /// 深浅色模式分别使用不同卡片底色。
        color: isDark ? const Color(0xFF171926) : Colors.white,

        /// 空状态卡片圆角。
        borderRadius: BorderRadius.circular(Style.emptyCardRadius),
        border: Border.all(
          /// 轻量描边让白色卡片在浅色背景里也有边界。
          color: isDark
              ? Colors.white.withValues(alpha: Style.emptyCardBorderDarkOpacity)
              : Colors.black.withValues(
                  alpha: Style.emptyCardBorderLightOpacity,
                ),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            /// 用柔和阴影把空状态卡片从背景上托起来。
            color: Colors.black.withValues(
              alpha: isDark
                  ? Style.emptyCardShadowDarkOpacity
                  : Style.emptyCardShadowLightOpacity,
            ),
            blurRadius: Style.emptyCardShadowBlur,
            offset: const Offset(0, Style.emptyCardShadowOffsetY),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Container(
            /// 中央圆形视觉锚点。
            /// 空状态本身缺少真实数据，这里用一个显眼的数字圆块先吸引视线。
            width: Style.emptyCircleSize,
            height: Style.emptyCircleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColorConstants.themeColor.withValues(
                alpha: isDark
                    ? Style.emptyCircleDarkOpacity
                    : Style.emptyCircleLightOpacity,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              /// 目前这里展示 0，强调当前账单数量为空。
              emptyNumberText,
              style: TextStyle(
                fontSize: Style.emptyNumberSize,
                fontWeight: Style.emptyNumberWeight,
                color: isDark
                    ? ColorConstants.themeColor
                    : ColorConstants.lightTextColor,
              ),
            ),
          ),
          const SizedBox(height: Style.emptyCircleBottomSpacing),
          Text(
            /// 空状态主文案，明确告诉用户当前没有账单数据。
            easy.tr('bill.empty'),
            style: TextStyle(
              fontSize: Style.emptyTitleSize,
              fontWeight: Style.emptyTitleWeight,
              color: isDark
                  ? ColorConstants.whiteColor
                  : ColorConstants.lightTextColor,
            ),
          ),
          const SizedBox(height: Style.emptyActionTopSpacing),
          _BillActionButton(
            /// 底部重试按钮文案。
            label: easy.tr('bill.reload'),

            /// 点击后让父页面重新发起一次刷新请求。
            onTap: onReload,
            isDark: isDark,

            /// 空状态按钮使用实心主题色，提升操作召回。
            filled: true,

            /// 当前空状态按钮不展示独立 loading，
            /// 真正的加载反馈由父页面整体 loading 状态负责。
            loading: false,
          ),
        ],
      ),
    );
  }
}

/// 空状态内部复用按钮。
///
/// 虽然当前只在空状态卡片里使用，
/// 但把按钮样式独立出来后，后续若要在同页其它提示卡片复用会更容易。
class _BillActionButton extends StatelessWidget {
  /// 按钮显示文本。
  final String label;

  /// 点击按钮后的回调。
  final VoidCallback onTap;

  /// 当前主题是否为深色模式。
  final bool isDark;

  /// 是否使用实心风格。
  ///
  /// 为 true 时走主题色填充；
  /// 为 false 时走描边风格。
  final bool filled;

  /// 按钮是否处于加载中。
  final bool loading;

  const _BillActionButton({
    required this.label,
    required this.onTap,
    required this.isDark,
    required this.filled,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    /// 实心和描边按钮使用不同背景色。
    final Color background = filled
        ? ColorConstants.themeColor
        : (isDark ? const Color(0xFF171926) : Colors.white);

    /// 实心按钮默认配深色文字；
    /// 描边按钮则跟随当前主题走普通文字色。
    final Color textColor = filled
        ? ColorConstants.lightTextColor
        : (isDark ? ColorConstants.whiteColor : ColorConstants.lightTextColor);

    return SizedBox(
      /// 按钮宽度撑满卡片。
      width: double.infinity,
      child: ElevatedButton(
        /// loading 时禁用按钮，避免连续点击。
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: background,
          foregroundColor: textColor,

          /// 禁用态通过降低透明度呈现，不额外改动结构和尺寸。
          disabledBackgroundColor: background.withValues(
            alpha: Style.actionButtonDisabledBackgroundOpacity,
          ),
          disabledForegroundColor: textColor.withValues(
            alpha: Style.actionButtonDisabledForegroundOpacity,
          ),

          /// 统一按钮高度。
          minimumSize: const Size.fromHeight(Style.actionButtonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Style.actionButtonRadius),
            side: BorderSide(
              /// 实心按钮不再需要描边；
              /// 描边按钮则保留一层轻边界。
              color: filled
                  ? Colors.transparent
                  : (isDark
                        ? Colors.white.withValues(
                            alpha: Style.actionButtonBorderDarkOpacity,
                          )
                        : Colors.black.withValues(
                            alpha: Style.actionButtonBorderLightOpacity,
                          )),
            ),
          ),
        ),
        child: Text(
          /// 按钮文案。
          label,
          style: TextStyle(
            fontSize: Style.actionButtonTextSize,
            fontWeight: Style.actionButtonTextWeight,
          ),
        ),
      ),
    );
  }
}
