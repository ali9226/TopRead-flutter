import 'package:easy_localization/easy_localization.dart';
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/withdraw_record.dart';
import 'package:app/pages/withdraw_record/style.dart';

/// 单条提现记录卡片。
///
/// 这个组件负责展示一条完整的提现记录摘要：
/// 1. 金额和状态。
/// 2. 流水号、创建时间、到账时间。
/// 3. 提现地址和复制操作。
///
/// 业务上的文案格式化和状态颜色由父级先算好，再传给这里纯展示。
class WithdrawRecordCard extends StatelessWidget {
  /// 当前是否为深色主题。
  final bool isDark;

  /// 当前这条提现记录的原始模型。
  ///
  /// 这里主要用到 `typeStr` 等少量原始字段做兜底展示。
  final WithdrawRecordItem item;

  /// 已格式化的提现金额文本。
  final String amountText;

  /// 已格式化的流水号文本。
  final String serialNumberText;

  /// 已格式化的创建时间文本。
  final String createTimeText;

  /// 已格式化的到账时间文本。
  final String payTimeText;

  /// 已格式化的提现地址文本。
  final String payQrCodeText;

  /// 当前是否需要展示到账时间这一行。
  final bool showPayTime;

  /// 已格式化的状态文案。
  final String statusText;

  /// 当前状态对应的高亮颜色。
  final Color statusColor;

  /// 点击复制流水号后的回调。
  final VoidCallback? onCopySerialNumber;

  /// 点击复制提现地址后的回调。
  final VoidCallback? onCopyPayQrCode;

  const WithdrawRecordCard({
    super.key,
    required this.isDark,
    required this.item,
    required this.amountText,
    required this.serialNumberText,
    required this.createTimeText,
    required this.payTimeText,
    required this.payQrCodeText,
    required this.showPayTime,
    required this.statusText,
    required this.statusColor,
    this.onCopySerialNumber,
    this.onCopyPayQrCode,
  });

  @override
  Widget build(BuildContext context) {
    // 卡片主文字颜色。
    final titleColor = isDark
        ? ColorConstants.whiteColor
        : ColorConstants.lightTextColor;

    // 卡片辅助文字颜色。
    final hintColor = isDark
        ? ColorConstants.whiteColor.withValues(
            alpha: TopUpRecordStyle.hintDarkOpacity,
          )
        : ColorConstants.hintColor;

    // 提现类型为空时用占位值兜底，避免地址块标题出现空白。
    final typeLabelText = item.typeStr.trim().isEmpty ? '--' : item.typeStr;

    return Container(
      margin: const EdgeInsets.only(bottom: TopUpRecordStyle.cardBottomMargin),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TopUpRecordStyle.cardRadius),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(
                  alpha: TopUpRecordStyle.cardBorderDarkOpacity,
                )
              : Colors.black.withValues(
                  alpha: TopUpRecordStyle.cardBorderLightOpacity,
                ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark
                  ? TopUpRecordStyle.cardShadowDarkOpacity
                  : TopUpRecordStyle.cardShadowLightOpacity,
            ),
            blurRadius: TopUpRecordStyle.cardShadowBlur,
            offset: const Offset(0, TopUpRecordStyle.cardShadowOffsetY),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TopUpRecordStyle.cardRadius),
        child: Stack(
          children: [
            // 卡片底层渐变，统一深浅色下的质感。
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? TopUpRecordStyle.darkCardGradient
                        : TopUpRecordStyle.lightCardGradient,
                  ),
                ),
              ),
            ),
            // 右上主光斑。
            Positioned(
              top: TopUpRecordStyle.cardGlowOneTop,
              right: TopUpRecordStyle.cardGlowOneRight,
              child: IgnorePointer(
                child: Container(
                  width: TopUpRecordStyle.cardGlowOneSize,
                  height: TopUpRecordStyle.cardGlowOneSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ColorConstants.themeColor.withValues(
                      alpha: isDark
                          ? TopUpRecordStyle.cardGlowDarkOpacity
                          : TopUpRecordStyle.cardGlowLightOpacity,
                    ),
                  ),
                ),
              ),
            ),
            // 左下辅助光斑。
            Positioned(
              left: TopUpRecordStyle.cardGlowTwoLeft,
              bottom: TopUpRecordStyle.cardGlowTwoBottom,
              child: IgnorePointer(
                child: Container(
                  width: TopUpRecordStyle.cardGlowTwoSize,
                  height: TopUpRecordStyle.cardGlowTwoSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ColorConstants.successColor.withValues(
                      alpha: isDark
                          ? TopUpRecordStyle.cardGlowDarkOpacity
                          : TopUpRecordStyle.cardGlowLightOpacity,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: TopUpRecordStyle.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _AmountDisplay(
                          color: statusColor,
                          amountText: amountText,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        // 状态胶囊单独放在右上角，方便用户一眼定位当前记录结果。
                        padding: const EdgeInsets.symmetric(
                          horizontal: TopUpRecordStyle.statusChipHorizontal,
                          vertical: TopUpRecordStyle.statusChipVertical,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(
                            alpha: isDark
                                ? TopUpRecordStyle.statusChipDarkOpacity
                                : TopUpRecordStyle.statusChipLightOpacity,
                          ),
                          borderRadius: BorderRadius.circular(
                            TopUpRecordStyle.statusChipRadius,
                          ),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: TopUpRecordStyle.statusTextSize,
                            fontWeight: TopUpRecordStyle.statusTextWeight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TopUpRecordStyle.rowSpacing),
                  _InfoLine(
                    isDark: isDark,
                    label: context.tr('withdraw_record_page.serial_number'),
                    value: serialNumberText,
                    onTap: onCopySerialNumber,
                    trailing: _InlineCopyButton(
                      isDark: isDark,
                      onTap: onCopySerialNumber,
                    ),
                  ),
                  const SizedBox(height: TopUpRecordStyle.lineSpacing),
                  _InfoLine(
                    isDark: isDark,
                    label: context.tr('withdraw_record_page.create_time'),
                    value: createTimeText,
                  ),
                  if (showPayTime) ...[
                    const SizedBox(height: TopUpRecordStyle.lineSpacing),
                    _InfoLine(
                      isDark: isDark,
                      label: context.tr('withdraw_record_page.pay_time'),
                      value: payTimeText,
                    ),
                  ],
                  const SizedBox(height: TopUpRecordStyle.addressTopSpacing),
                  GestureDetector(
                    // 整个地址区都可点击复制，比只点小图标的可触区域更友好。
                    onTap: onCopyPayQrCode,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: double.infinity,
                      padding: TopUpRecordStyle.addressWrapPadding,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(
                                alpha: TopUpRecordStyle.addressWrapDarkOpacity,
                              )
                            : Colors.black.withValues(
                                alpha: TopUpRecordStyle.addressWrapLightOpacity,
                              ),
                        borderRadius: BorderRadius.circular(
                          TopUpRecordStyle.addressWrapRadius,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  // 上方小标题展示提现网络/类型，帮助用户区分地址语义。
                                  typeLabelText,
                                  style: TextStyle(
                                    color: hintColor,
                                    fontSize: TopUpRecordStyle.addressLabelSize,
                                    fontWeight:
                                        TopUpRecordStyle.addressLabelWeight,
                                  ),
                                ),
                                const SizedBox(
                                  height: TopUpRecordStyle
                                      .addressLabelBottomSpacing,
                                ),
                                Text(
                                  // 下方主体展示真实提现地址，是该卡片里最长的一段信息。
                                  payQrCodeText,
                                  style: TextStyle(
                                    color: titleColor,
                                    fontSize: TopUpRecordStyle.addressTextSize,
                                    height: TopUpRecordStyle.addressTextHeight,
                                    fontWeight:
                                        TopUpRecordStyle.addressTextWeight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            width: TopUpRecordStyle.addressActionGap,
                          ),
                          _AddressActionIcon(
                            isDark: isDark,
                            iconName: 'copy',
                            onTap: onCopyPayQrCode,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineCopyButton extends StatelessWidget {
  /// 当前是否为深色主题。
  final bool isDark;

  /// 点击复制按钮后的回调。
  final VoidCallback? onTap;

  const _InlineCopyButton({required this.isDark, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 这里保留一个独立复制按钮，是为了和可点击整行一起形成双重操作入口。
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: TopUpRecordStyle.addressIconWrapSize,
        height: TopUpRecordStyle.addressIconWrapSize,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              TopUpRecordStyle.addressIconWrapRadius,
            ),
            color: ColorConstants.themeColor.withValues(
              alpha: isDark
                  ? TopUpRecordStyle.addressIconWrapDarkOpacity
                  : TopUpRecordStyle.addressIconWrapLightOpacity,
            ),
          ),
          child: Center(
            child: SvgIcon(
              name: 'copy',
              width: TopUpRecordStyle.addressIconSize,
              height: TopUpRecordStyle.addressIconSize,
              color: ColorConstants.themeColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _AddressActionIcon extends StatelessWidget {
  /// 当前是否为深色主题。
  final bool isDark;

  /// 要展示的图标名称。
  final String iconName;

  /// 点击图标后的回调。
  final VoidCallback? onTap;

  const _AddressActionIcon({
    required this.isDark,
    required this.iconName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: TopUpRecordStyle.addressIconWrapSize,
        height: TopUpRecordStyle.addressIconWrapSize,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              TopUpRecordStyle.addressIconWrapRadius,
            ),
            color: ColorConstants.themeColor.withValues(
              alpha: isDark
                  ? TopUpRecordStyle.addressIconWrapDarkOpacity
                  : TopUpRecordStyle.addressIconWrapLightOpacity,
            ),
          ),
          child: Center(
            child: SvgIcon(
              name: iconName,
              width: TopUpRecordStyle.addressIconSize,
              height: TopUpRecordStyle.addressIconSize,
              color: ColorConstants.themeColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _AmountDisplay extends StatelessWidget {
  final Color color;
  final String amountText;

  const _AmountDisplay({required this.color, required this.amountText});

  @override
  Widget build(BuildContext context) {
    final dotIndex = amountText.indexOf('.');
    final integerPart = dotIndex >= 0
        ? amountText.substring(0, dotIndex)
        : amountText;
    final decimalPart = dotIndex >= 0 ? amountText.substring(dotIndex) : '';

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '\$',
            style: TextStyle(
              color: color,
              fontSize: 27,
              height: 1,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w700),
            ),
          ),
          TextSpan(
            text: integerPart,
            style: TextStyle(
              color: color,
              fontSize: 40,
              height: 1,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
            ),
          ),
          if (decimalPart.isNotEmpty)
            TextSpan(
              text: decimalPart,
              style: TextStyle(
                color: color.withValues(alpha: 0.9),
                fontSize: 24,
                height: 1,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final bool isDark;
  final String label;
  final String value;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _InfoLine({
    required this.isDark,
    required this.label,
    required this.value,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = isDark
        ? ColorConstants.whiteColor.withValues(
            alpha: TopUpRecordStyle.hintDarkOpacity,
          )
        : ColorConstants.hintColor;
    final valueColor = isDark
        ? ColorConstants.whiteColor
        : ColorConstants.lightTextColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: TopUpRecordStyle.lineLabelWidth,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: TextStyle(
                  color: labelColor,
                  fontSize: TopUpRecordStyle.lineLabelSize,
                  fontWeight: TopUpRecordStyle.lineLabelWeight,
                ),
              ),
            ),
          ),
          const SizedBox(width: TopUpRecordStyle.lineGap),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: TopUpRecordStyle.lineValueSize,
                  height: TopUpRecordStyle.lineValueHeight,
                  fontWeight: TopUpRecordStyle.lineValueWeight,
                ),
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: TopUpRecordStyle.addressActionGap),
            trailing!,
          ],
        ],
      ),
    );
  }
}
