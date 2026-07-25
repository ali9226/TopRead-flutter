import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/top_up_record.dart';

import '../style.dart';

/// 单条充值记录卡片。
///
/// 输入数据和格式化后的展示文案都由外部传入，
/// 组件本身只负责把这些值按既定版式呈现出来。
class TopUpRecordCard extends StatelessWidget {
  final bool isDark;
  final TopUpRecordItem item;
  final String amountText;
  final String payableText;
  final String serialNumberText;
  final String createTimeText;
  final String payTimeText;
  final String payQrCodeText;
  final bool showPayQrCode;
  final bool showCountdown;
  final String countdownText;
  final String statusText;
  final Color statusColor;
  final VoidCallback? onCopySerialNumber;
  final VoidCallback? onCopyPayQrCode;
  final VoidCallback? onShowQrCode;

  const TopUpRecordCard({
    super.key,
    required this.isDark,
    required this.item,
    required this.amountText,
    required this.payableText,
    required this.serialNumberText,
    required this.createTimeText,
    required this.payTimeText,
    required this.payQrCodeText,
    required this.showPayQrCode,
    required this.showCountdown,
    required this.countdownText,
    required this.statusText,
    required this.statusColor,
    this.onCopySerialNumber,
    this.onCopyPayQrCode,
    this.onShowQrCode,
  });

  @override
  Widget build(BuildContext context) {
    // 当前卡片使用的主文案色和辅助文案色。
    final titleColor = isDark
        ? ColorConstants.whiteColor
        : ColorConstants.lightTextColor;
    final hintColor = isDark
        ? ColorConstants.whiteColor.withValues(
            alpha: TopUpRecordStyle.hintDarkOpacity,
          )
        : ColorConstants.hintColor;
    final countdownColor = TopUpRecordStyle.countdownTextColor;

    return Container(
      // 外层卡片负责承载整条记录的全部信息。
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
                  // 标题区：左边显示充值类型，右边显示状态标签。
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.typeStr.isEmpty ? '--' : item.typeStr,
                          style: TextStyle(
                            color: titleColor,
                            fontSize: TopUpRecordStyle.cardTitleSize,
                            fontWeight: TopUpRecordStyle.cardTitleWeight,
                          ),
                        ),
                      ),
                      Container(
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
                  const SizedBox(height: TopUpRecordStyle.sectionSpacing),

                  // 金额信息区：原始金额和实际金额双列展示。
                  Row(
                    children: [
                      Expanded(
                        child: _InfoBlock(
                          isDark: isDark,
                          label: easy.tr('top_up_record_page.pay_payable'),
                          value: payableText,
                        ),
                      ),
                      const SizedBox(width: TopUpRecordStyle.rowSpacing),
                      Expanded(
                        child: _InfoBlock(
                          isDark: isDark,
                          label: easy.tr('top_up_record_page.amount_payable'),
                          value: amountText,
                          valueColor: statusColor,
                          backgroundColor: statusColor.withValues(
                            alpha: isDark ? 0.12 : 0.14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TopUpRecordStyle.rowSpacing),

                  // 纵向信息区：流水号、创建时间、到账时间等逐行展示。
                  _InfoLine(
                    isDark: isDark,
                    label: easy.tr('top_up_record_page.serial_number'),
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
                    label: easy.tr('top_up_record_page.create_time'),
                    value: createTimeText,
                  ),
                  if (item.payStatus == 2 && payTimeText != '--') ...[
                    const SizedBox(height: TopUpRecordStyle.lineSpacing),
                    _InfoLine(
                      isDark: isDark,
                      label: easy.tr('top_up_record_page.pay_time'),
                      value: payTimeText,
                    ),
                  ],
                  AnimatedSize(
                    duration: const Duration(
                      milliseconds: TopUpRecordStyle.expirableAreaAnimationMs,
                    ),
                    curve: Curves.easeInOutCubic,
                    alignment: Alignment.topCenter,
                    child: AnimatedSwitcher(
                      duration: const Duration(
                        milliseconds: TopUpRecordStyle.expirableAreaAnimationMs,
                      ),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SizeTransition(
                            sizeFactor: animation,
                            axisAlignment: -1,
                            child: child,
                          ),
                        );
                      },
                      child:
                          (item.payStatus == 1 && showCountdown) ||
                              showPayQrCode
                          ? Column(
                              key: ValueKey(
                                'expirable-${item.id}-${showCountdown ? 1 : 0}-${showPayQrCode ? 1 : 0}',
                              ),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (item.payStatus == 1 && showCountdown) ...[
                                  const SizedBox(
                                    height: TopUpRecordStyle.lineSpacing,
                                  ),
                                  _InfoLine(
                                    isDark: isDark,
                                    label: easy.tr(
                                      'top_up_record_page.countdown_label',
                                    ),
                                    value: countdownText,
                                    valueColor: countdownColor,
                                    trailing: Icon(
                                      Icons.schedule_rounded,
                                      size: TopUpRecordStyle
                                          .inlineCountdownIconSize,
                                      color:
                                          TopUpRecordStyle.countdownIconColor,
                                    ),
                                  ),
                                ],
                                if (showPayQrCode) ...[
                                  const SizedBox(
                                    height: TopUpRecordStyle.addressTopSpacing,
                                  ),
                                  GestureDetector(
                                    onTap: onCopyPayQrCode,
                                    behavior: HitTestBehavior.opaque,
                                    child: Container(
                                      width: double.infinity,
                                      padding:
                                          TopUpRecordStyle.addressWrapPadding,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withValues(
                                                alpha: TopUpRecordStyle
                                                    .addressWrapDarkOpacity,
                                              )
                                            : Colors.black.withValues(
                                                alpha: TopUpRecordStyle
                                                    .addressWrapLightOpacity,
                                              ),
                                        borderRadius: BorderRadius.circular(
                                          TopUpRecordStyle.addressWrapRadius,
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  easy.tr(
                                                    'top_up_record_page.pay_qr_code',
                                                  ),
                                                  style: TextStyle(
                                                    color: hintColor,
                                                    fontSize: TopUpRecordStyle
                                                        .addressLabelSize,
                                                    fontWeight: TopUpRecordStyle
                                                        .addressLabelWeight,
                                                  ),
                                                ),
                                                const SizedBox(
                                                  height: TopUpRecordStyle
                                                      .addressLabelBottomSpacing,
                                                ),
                                                Text(
                                                  payQrCodeText,
                                                  style: TextStyle(
                                                    color: titleColor,
                                                    fontSize: TopUpRecordStyle
                                                        .addressTextSize,
                                                    height: TopUpRecordStyle
                                                        .addressTextHeight,
                                                    fontWeight: TopUpRecordStyle
                                                        .addressTextWeight,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(
                                            width: TopUpRecordStyle
                                                .addressActionGap,
                                          ),
                                          _AddressActionIcon(
                                            isDark: isDark,
                                            iconName: 'copy',
                                            onTap: onCopyPayQrCode,
                                          ),
                                          const SizedBox(
                                            width: TopUpRecordStyle
                                                .addressActionGap,
                                          ),
                                          _AddressActionIcon(
                                            isDark: isDark,
                                            iconName: 'qr_code',
                                            onTap: onShowQrCode,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            )
                          : const SizedBox.shrink(),
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
  final bool isDark;
  final VoidCallback? onTap;

  const _InlineCopyButton({required this.isDark, this.onTap});

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
  final bool isDark;
  final String iconName;
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

class _InfoBlock extends StatelessWidget {
  final bool isDark;
  final String label;
  final String value;
  final Color? valueColor;
  final Color? backgroundColor;

  const _InfoBlock({
    required this.isDark,
    required this.label,
    required this.value,
    this.valueColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // 小信息块用于突出金额相关字段，权重比普通文本行更高。
    return Container(
      padding: TopUpRecordStyle.infoBlockPadding,
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            (isDark
                ? Colors.white.withValues(
                    alpha: TopUpRecordStyle.infoBlockDarkOpacity,
                  )
                : TopUpRecordStyle.infoBlockLightColor),
        borderRadius: BorderRadius.circular(TopUpRecordStyle.infoBlockRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark
                  ? ColorConstants.whiteColor.withValues(
                      alpha: TopUpRecordStyle.hintDarkOpacity,
                    )
                  : ColorConstants.hintColor,
              fontSize: TopUpRecordStyle.infoLabelSize,
              fontWeight: TopUpRecordStyle.infoLabelWeight,
            ),
          ),
          const SizedBox(height: TopUpRecordStyle.infoLabelBottomSpacing),
          Text(
            value,
            style: TextStyle(
              color:
                  valueColor ??
                  (isDark
                      ? ColorConstants.whiteColor
                      : ColorConstants.lightTextColor),
              fontSize: TopUpRecordStyle.infoValueSize,
              fontWeight: TopUpRecordStyle.infoValueWeight,
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
  final Color? valueColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _InfoLine({
    required this.isDark,
    required this.label,
    required this.value,
    this.valueColor,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    // 普通信息行统一使用“左标签 + 右内容”的双列排版，
    // 这样长文本也能稳定换行，不会影响标签列对齐。
    return GestureDetector(
      onTap: onTap,
      behavior: onTap == null
          ? HitTestBehavior.deferToChild
          : HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: trailing == null
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: TopUpRecordStyle.lineLabelWidth,
            child: Text(
              label,
              style: TextStyle(
                color: isDark
                    ? ColorConstants.whiteColor.withValues(
                        alpha: TopUpRecordStyle.hintDarkOpacity,
                      )
                    : ColorConstants.hintColor,
                fontSize: TopUpRecordStyle.lineLabelSize,
                fontWeight: TopUpRecordStyle.lineLabelWeight,
              ),
            ),
          ),
          const SizedBox(width: TopUpRecordStyle.lineGap),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color:
                    valueColor ??
                    (isDark
                        ? ColorConstants.whiteColor
                        : ColorConstants.lightTextColor),
                fontSize: TopUpRecordStyle.lineValueSize,
                height: TopUpRecordStyle.lineValueHeight,
                fontWeight: TopUpRecordStyle.lineValueWeight,
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 6), trailing!],
        ],
      ),
    );
  }
}
