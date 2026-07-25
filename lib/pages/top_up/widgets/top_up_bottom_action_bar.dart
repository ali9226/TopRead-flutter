import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';
import '../style.dart';

/// 充值页底部操作条。
///
/// 聚合“当前类型/金额摘要 + 提交按钮”，支持普通模式和浮动模式。
class TopUpBottomActionBar extends StatelessWidget {
  /// 当前是否为深色主题。
  final bool isDark;

  /// 是否以悬浮卡片形式显示。
  ///
  /// 竖屏时通常会悬浮在底部，横屏时则作为正文区普通卡片插入。
  final bool floating;

  /// 当前选中的充值方式文案。
  final String typeValue;

  /// 当前选中的金额文案。
  final String amountValue;

  /// 当前是否允许点击提交。
  final bool enabled;

  /// 当前是否处于提交 loading。
  final bool loading;

  /// 点击提交后的统一回调。
  final VoidCallback onSubmit;

  const TopUpBottomActionBar({
    super.key,
    required this.isDark,
    required this.floating,
    required this.typeValue,
    required this.amountValue,
    required this.enabled,
    required this.loading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: Style.bottomActionPadding,
      decoration: BoxDecoration(
        color: floating
            ? (isDark
                  ? const Color(0xFF171A27).withValues(alpha: 0.96)
                  : Colors.white.withValues(alpha: 0.96))
            : (isDark ? const Color(0xFF171A27) : Colors.white),
        borderRadius: BorderRadius.circular(Style.bottomActionRadius),
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
          Wrap(
            // 顶部摘要用 Wrap 而不是 Row，可以兼容某些语言下更长的文案。
            alignment: WrapAlignment.start,
            spacing: Style.bottomActionChipSpacing,
            runSpacing: Style.bottomActionChipSpacing,
            children: <Widget>[
              _TopUpBottomActionChip(
                isDark: isDark,
                label: easy.tr('top_up_page.summary_type'),
                value: typeValue,
              ),
              _TopUpBottomActionChip(
                isDark: isDark,
                label: easy.tr('top_up_page.summary_amount'),
                value: amountValue,
                valueColor: Style.accentColor,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _TopUpSubmitButton(
            enabled: enabled,
            loading: loading,
            onSubmit: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _TopUpBottomActionChip extends StatelessWidget {
  /// 当前是否为深色主题。
  final bool isDark;

  /// 左侧标签，例如“类型”“金额”。
  final String label;

  /// 右侧实际值。
  final String value;

  /// 可选的值高亮色。
  final Color? valueColor;

  const _TopUpBottomActionChip({
    required this.isDark,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: Style.bottomActionChipPadding,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(Style.bottomActionChipRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '$label: ',
            style: TextStyle(
              color: isDark
                  ? ColorConstants.whiteColor.withValues(alpha: 0.56)
                  : ColorConstants.hintColor,
              fontSize: Style.bottomActionChipLabelSize,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w700),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color:
                  valueColor ??
                  (isDark
                      ? ColorConstants.whiteColor
                      : ColorConstants.lightTextColor),
              fontSize: Style.bottomActionChipValueSize,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopUpSubmitButton extends StatelessWidget {
  /// 当前按钮是否可用。
  final bool enabled;

  /// 当前是否处于 loading。
  final bool loading;

  /// 点击按钮后的回调。
  final VoidCallback onSubmit;

  const _TopUpSubmitButton({
    required this.enabled,
    required this.loading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        // 只有“已具备提交条件且不在请求中”时才允许点击。
        onPressed: !enabled || loading ? null : onSubmit,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Style.accentColor,
          disabledBackgroundColor: Style.accentColor.withValues(alpha: 0.5),
          foregroundColor: ColorConstants.lightTextColor,
          minimumSize: const Size.fromHeight(Style.submitButtonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Style.submitButtonRadius),
          ),
        ),
        child: Text(
          easy.tr('top_up_page.submit'),
          style: TextStyle(
            fontSize: Style.submitButtonTextSize,
            fontWeight: Style.submitButtonTextWeight,
          ),
        ),
      ),
    );
  }
}
