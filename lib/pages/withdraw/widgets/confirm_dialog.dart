import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';
import 'package:app/util/clipboard/clipboard.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import '../style.dart';
import 'confirm_tips.dart';
import 'package:app/config/font_config.dart';

/// 提现确认弹窗。
///
/// 负责展示提现金额、网络和钱包地址摘要，并处理确认按钮的局部提交状态。
class WithdrawConfirmDialog extends StatefulWidget {
  /// 当前是否为深色主题。
  final bool isDark;

  /// 当前选中的提现网络文案。
  final String networkValue;

  /// 钱包地址区域标题。
  final String walletLabel;

  /// 用户当前填写的钱包地址。
  final String walletValue;

  /// 已格式化的提现金额文本。
  final String amountValue;

  /// 点击确认后的真正提现请求。
  final Future<String?> Function() onConfirm;

  /// 提现成功后的后续动作。
  final ValueChanged<String> onSuccess;

  const WithdrawConfirmDialog({
    super.key,
    required this.isDark,
    required this.networkValue,
    required this.walletLabel,
    required this.walletValue,
    required this.amountValue,
    required this.onConfirm,
    required this.onSuccess,
  });

  @override
  State<WithdrawConfirmDialog> createState() => _WithdrawConfirmDialogState();
}

class _WithdrawConfirmDialogState extends State<WithdrawConfirmDialog> {
  /// 确认按钮是否正处于提交中。
  ///
  /// 这个 loading 只影响弹窗内部按钮，不影响整个页面其他状态。
  bool isSubmitting = false;

  Future<void> _handleConfirm() async {
    // 提交中不允许重复点击确认。
    if (isSubmitting) return;

    // 点击确认后先收起键盘，避免系统焦点残留。
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      // 打开局部 loading，锁住弹窗按钮。
      isSubmitting = true;
    });

    // 调用外部真正的提现请求。
    final String? successMessage = await widget.onConfirm();
    if (!mounted) return;

    // 返回空说明提现失败或被拦截，这时只关闭 loading，不关弹窗。
    if (successMessage == null) {
      setState(() {
        isSubmitting = false;
      });
      return;
    }

    // 成功后先关闭确认弹窗，再把成功消息交给外层继续处理。
    Navigator.of(context).pop();
    widget.onSuccess(successMessage);
  }

  @override
  Widget build(BuildContext context) {
    // 弹窗基础背景色。
    final Color dialogBackground = widget.isDark
        ? const Color(0xFF171A27)
        : Colors.white;

    // 标题颜色。
    final Color titleColor = widget.isDark
        ? ColorConstants.whiteColor
        : ColorConstants.lightTextColor;

    // 标签颜色。
    final Color labelColor = widget.isDark
        ? ColorConstants.whiteColor.withValues(alpha: 0.58)
        : ColorConstants.hintColor;

    // 主要数值颜色。
    final Color valueColor = widget.isDark
        ? const Color(0xFFFFE8A3)
        : ColorConstants.lightTextColor;

    return Dialog(
      backgroundColor: dialogBackground,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(WithdrawStyle.confirmDialogRadius),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 620),
        child: Stack(
          children: <Widget>[
            // 顶部主光斑，给弹窗头部一点视觉焦点。
            Positioned(
              top: -20,
              right: -8,
              child: IgnorePointer(
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ColorConstants.themeColor.withValues(
                      alpha: widget.isDark ? 0.10 : 0.10,
                    ),
                  ),
                ),
              ),
            ),
            // 左下辅助光斑，平衡顶部装饰的重心。
            Positioned(
              left: -16,
              bottom: 58,
              child: IgnorePointer(
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ColorConstants.successColor.withValues(
                      alpha: widget.isDark ? 0.08 : 0.08,
                    ),
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              padding: WithdrawStyle.confirmDialogPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      easy.tr('withdraw_page.confirm_title'),
                      style: TextStyle(
                        color: titleColor,
                        fontSize: WithdrawStyle.confirmDialogTitleSize,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _WithdrawConfirmDetailCard(
                    isDark: widget.isDark,
                    labelColor: labelColor,
                    valueColor: valueColor,
                    networkValue: widget.networkValue,
                    walletLabel: widget.walletLabel,
                    walletValue: widget.walletValue,
                    amountValue: widget.amountValue,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _WithdrawDialogButton(
                          isDark: widget.isDark,
                          text: easy.tr('constant.cancel'),
                          filled: false,
                          loading: false,
                          onTap: () {
                            // 取消按钮只负责关闭弹窗，不应触发任何提现请求。
                            if (isSubmitting) return;
                            FocusScope.of(context).unfocus();
                            FocusManager.instance.primaryFocus?.unfocus();
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _WithdrawDialogButton(
                          isDark: widget.isDark,
                          text: easy.tr('game.action.confirm'),
                          filled: true,
                          loading: isSubmitting,
                          onTap: _handleConfirm,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ConfirmTips(isDark: widget.isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WithdrawConfirmDetailCard extends StatelessWidget {
  /// 当前是否为深色主题。
  final bool isDark;

  /// 标签颜色。
  final Color labelColor;

  /// 数值颜色。
  final Color valueColor;

  /// 提现网络文案。
  final String networkValue;

  /// 钱包地址标题。
  final String walletLabel;

  /// 钱包地址值。
  final String walletValue;

  /// 提现金额值。
  final String amountValue;

  const _WithdrawConfirmDetailCard({
    required this.isDark,
    required this.labelColor,
    required this.valueColor,
    required this.networkValue,
    required this.walletLabel,
    required this.walletValue,
    required this.amountValue,
  });

  @override
  Widget build(BuildContext context) {
    // 钱包地址展示框的淡色背景。
    final Color fieldBackground = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);

    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Column(
        children: <Widget>[
          SizedBox(
            width: double.infinity,
            height: 124,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Stack(
                children: <Widget>[
                  Positioned(
                    top: -18,
                    right: -6,
                    child: IgnorePointer(
                      child: Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ColorConstants.themeColor.withValues(
                            alpha: isDark ? 0.10 : 0.08,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    bottom: -12,
                    child: IgnorePointer(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ColorConstants.successColor.withValues(
                            alpha: isDark ? 0.08 : 0.06,
                          ),
                        ),
                      ),
                    ),
                  ),
                  LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                          // 金额位数会随着用户输入变化，这里根据可用宽度动态缩放字体，
                          // 避免大金额在小屏设备上直接溢出。
                          final double fontScale = _amountFontScaleByWidth(
                            context: context,
                            value: amountValue,
                            maxWidth: constraints.maxWidth,
                          );
                          return Align(
                            alignment: Alignment.center,
                            child: _WithdrawAmountHighlight(
                              value: amountValue,
                              valueColor: ColorConstants.themeColor,
                              scale: fontScale,
                            ),
                          );
                        },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              networkValue.isEmpty ? walletLabel : networkValue,
              style: TextStyle(
                color: labelColor,
                fontSize: 12,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            decoration: BoxDecoration(
              color: fieldBackground,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      walletValue.isEmpty ? '--' : walletValue,
                      style: TextStyle(
                        color: isDark
                            ? ColorConstants.whiteColor.withValues(alpha: 0.74)
                            : valueColor,
                        fontSize: WithdrawStyle.confirmDialogWalletValueSize,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () async {
                    // 只有有真实地址时才执行复制，避免复制占位值。
                    if (walletValue.isEmpty) return;
                    final bool status = await copyToClipboard(walletValue);
                    if (!context.mounted || !status) return;
                    showBottomTip(easy.tr('top_up_qr_code_page.copy_success'));
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: ColorConstants.themeColor.withValues(
                        alpha: isDark ? 0.14 : 0.12,
                      ),
                      border: Border.all(color: ColorConstants.themeColor),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.copy_rounded,
                        size: 18,
                        color: ColorConstants.themeColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WithdrawAmountHighlight extends StatelessWidget {
  /// 已格式化的提现金额文案。
  final String value;

  /// 金额高亮颜色。
  final Color valueColor;

  /// 当前字体缩放比例。
  final double scale;

  const _WithdrawAmountHighlight({
    required this.value,
    required this.valueColor,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    // 如果金额文本自带 `$`，需要把货币符号和数字拆开分别控制字号。
    final bool hasDollar = value.startsWith('\$');
    final String amountText = hasDollar ? value.substring(1) : value;
    final List<String> parts = amountText.split('.');
    final String integerPart = parts.first;
    final String decimalPart = parts.length > 1
        ? '.${parts.sublist(1).join('.')}'
        : '';

    return RichText(
      text: TextSpan(
        children: <InlineSpan>[
          if (hasDollar)
            WidgetSpan(
              alignment: PlaceholderAlignment.bottom,
              baseline: TextBaseline.alphabetic,
              child: Padding(
                padding: const EdgeInsets.only(right: 2, bottom: 2),
                child: Text(
                  '\$',
                  style: TextStyle(
                    color: valueColor,
                    fontSize:
                        WithdrawStyle.confirmDialogPrimaryAmountSize *
                        0.50 *
                        scale,
                    fontWeight: FontConfig.adjustedWeight(FontWeight.w900),
                    height: 1,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),
          TextSpan(
            text: integerPart,
            style: TextStyle(
              color: valueColor,
              fontSize: WithdrawStyle.confirmDialogPrimaryAmountSize * scale,
              fontWeight: FontConfig.adjustedWeight(FontWeight.w900),
              height: 1.08,
              letterSpacing: -0.9,
              fontFeatures: const <FontFeature>[
                FontFeature.tabularFigures(),
                FontFeature.proportionalFigures(),
              ],
              shadows: <Shadow>[
                Shadow(
                  color: valueColor.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          if (decimalPart.isNotEmpty)
            TextSpan(
              text: decimalPart,
              style: TextStyle(
                color: valueColor.withValues(alpha: 0.92),
                fontSize:
                    WithdrawStyle.confirmDialogPrimaryAmountDecimalSize * scale,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                height: 1.08,
                letterSpacing: -0.5,
                fontFeatures: const <FontFeature>[
                  FontFeature.tabularFigures(),
                  FontFeature.proportionalFigures(),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

double _amountFontScaleByWidth({
  required BuildContext context,
  required String value,
  required double maxWidth,
}) {
  // 这段逻辑的目标不是做精确排版引擎，而是在不同位数金额下快速找出一个
  // “不溢出容器、又尽量大”的缩放比例，让确认金额始终保有足够的强调感。
  final bool hasDollar = value.startsWith('\$');
  final String amountText = hasDollar ? value.substring(1) : value;
  final List<String> parts = amountText.split('.');
  final String integerPart = parts.first;
  final String decimalPart = parts.length > 1
      ? '.${parts.sublist(1).join('.')}'
      : '';
  const double minScale = 0.42;
  const double maxScale = 1.0;

  double measure(double scale) {
    var width = 0.0;

    if (hasDollar) {
      final TextPainter dollarPainter = TextPainter(
        text: TextSpan(
          text: '\$',
          style: TextStyle(
            fontSize:
                WithdrawStyle.confirmDialogPrimaryAmountSize * 0.50 * scale,
            fontWeight: FontConfig.adjustedWeight(FontWeight.w900),
            letterSpacing: -0.3,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
        textDirection: Directionality.of(context),
        maxLines: 1,
      )..layout();
      width += dollarPainter.width + 2;
    }

    final TextPainter integerPainter = TextPainter(
      text: TextSpan(
        text: integerPart,
        style: TextStyle(
          fontSize: WithdrawStyle.confirmDialogPrimaryAmountSize * scale,
          fontWeight: FontConfig.adjustedWeight(FontWeight.w900),
          letterSpacing: -0.9,
          fontFeatures: const <FontFeature>[
            FontFeature.tabularFigures(),
            FontFeature.proportionalFigures(),
          ],
        ),
      ),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();
    width += integerPainter.width;

    if (decimalPart.isNotEmpty) {
      final TextPainter decimalPainter = TextPainter(
        text: TextSpan(
          text: decimalPart,
          style: TextStyle(
            fontSize:
                WithdrawStyle.confirmDialogPrimaryAmountDecimalSize * scale,
            fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
            letterSpacing: -0.5,
            fontFeatures: const <FontFeature>[
              FontFeature.tabularFigures(),
              FontFeature.proportionalFigures(),
            ],
          ),
        ),
        textDirection: Directionality.of(context),
        maxLines: 1,
      )..layout();
      width += decimalPainter.width;
    }

    return width;
  }

  final double targetWidth = maxWidth - 8;
  if (measure(maxScale) <= targetWidth) return maxScale;

  var low = minScale;
  var high = maxScale;
  for (var i = 0; i < 12; i++) {
    final double mid = (low + high) / 2;
    if (measure(mid) <= targetWidth) {
      low = mid;
    } else {
      high = mid;
    }
  }
  return low.clamp(minScale, maxScale);
}

class _WithdrawDialogButton extends StatelessWidget {
  final bool isDark;
  final String text;
  final bool filled;
  final bool loading;
  final VoidCallback onTap;

  const _WithdrawDialogButton({
    required this.isDark,
    required this.text,
    required this.filled,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = filled
        ? ColorConstants.themeColor
        : (isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04));
    final Color textColor = filled
        ? Colors.black
        : (isDark ? ColorConstants.whiteColor : ColorConstants.lightTextColor);
    final Color borderColor = filled
        ? ColorConstants.themeColor
        : (isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.08));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(
          WithdrawStyle.confirmDialogButtonRadius,
        ),
        onTap: loading ? null : onTap,
        child: Ink(
          height: WithdrawStyle.confirmDialogButtonHeight,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(
              WithdrawStyle.confirmDialogButtonRadius,
            ),
            border: Border.all(color: borderColor),
          ),
          child: Center(
            child: loading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: textColor,
                    ),
                  )
                : Text(
                    text,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
