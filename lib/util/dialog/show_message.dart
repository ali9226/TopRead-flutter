import 'dart:async';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/components/app_wrapper/utils/app_router.dart';
import 'package:app/config/color_config.dart';
import 'package:app/stores/bottom_navigation_info.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/config/font_config.dart';

/**
 * TODO 普通确认弹窗预热器。
 * 作用：
 * 1. 提前构建退出登录这类确认弹窗的卡片、按钮和装饰层。
 * 2. 把首开时最明显的布局、阴影和按钮主题解析成本提前到页面空闲时完成。
 * 3. 只预热一次，避免每次进个人页都重复做无意义的后台构建。
 */
class ShowMessageWarmUp {
  static bool _hasWarmedUp = false;

  static Future<void> warmUp({BuildContext? context}) async {
    if (_hasWarmedUp) return;

    final OverlayState? overlayState =
        Overlay.of(context ?? Get.context!, rootOverlay: true);
    if (overlayState == null) return;

    _hasWarmedUp = true;
    final DeviceInfo deviceInfo = Get.find<DeviceInfo>();

    late final OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (BuildContext overlayContext) {
        return IgnorePointer(
          child: Offstage(
            child: Material(
              color: Colors.transparent,
              child: Center(
                child: _MessageDialogCard(
                  isDark: deviceInfo.theme.value == ThemeMode.dark,
                  message: 'warm_up',
                  showHelperText: true,
                  iconData: Icons.info_outline_rounded,
                  leftButtonText: easy.tr('constant.cancel'),
                  rightButtonText: easy.tr('constant.ok'),
                  effectiveRightButtonText: easy.tr('constant.ok'),
                  isProcessing: false,
                  onLeftPressed: null,
                  onRightPressed: null,
                ),
              ),
            ),
          ),
        );
      },
    );

    overlayState.insert(overlayEntry);
    await Future<void>.delayed(const Duration(milliseconds: 32));
    overlayEntry.remove();
  }
}

/// TODO 异步弹窗函数，点击按钮或关闭弹窗都会完成 Future
Future<void> showMessage({
  required String message,
  String? leftButtonText,
  String? rightButtonText,
  bool allowMaskDismiss = true,
  bool showHelperText = true,
  IconData iconData = Icons.info_outline_rounded,
  Widget? iconWidget,
  String Function(int remainingSeconds)? rightButtonTextBuilder,
  int? rightButtonCountdownSeconds,
  Future<void> Function()? onLeftPressed,
  Future<void> Function()? onRightPressed,
  Color? rightButtonColor,
  Color? iconColor,
}) async {
  final DeviceInfo deviceInfo = Get.find();
  final BottomNavigationInfo bottomNavigationInfo = Get.find();
  final bool isDark = deviceInfo.theme.value == ThemeMode.dark;
  final NavigatorState? rootNavigator = AppRouter.navigatorState();
  if (rootNavigator == null) return;

  final BuildContext rootContext = rootNavigator.context;
  final Completer<void> completer = Completer<void>();
  Timer? countdownTimer;
  int countdownRemaining = rightButtonCountdownSeconds ?? 0;
  bool countdownInvalidated = false;

  bottomNavigationInfo.changeShowMessageState(true);

  final listener = bottomNavigationInfo.showMessageState.listen((bool value) {
    if (!value && rootNavigator.canPop()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (rootNavigator.mounted && rootNavigator.canPop()) {
          rootNavigator.pop();
        }
      });
    }
  });

  await showGeneralDialog<void>(
    context: rootContext,
    barrierDismissible: allowMaskDismiss,
    barrierLabel: 'dialog',
    barrierColor: Colors.black.withValues(alpha: isDark ? 0.54 : 0.34),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (context, animation, secondaryAnimation) {
      final double screenWidth = MediaQuery.of(context).size.width;
      final double dialogWidth = min(screenWidth * 0.86, 408.0);
      bool isProcessing = false;

      Future<void> closeDialog() async {
        countdownInvalidated = true;
        countdownTimer?.cancel();
        countdownTimer = null;
        if (rootNavigator.mounted && rootNavigator.canPop()) {
          rootNavigator.pop();
        }
      }

      return StatefulBuilder(
        builder: (context, setState) {
          if (rightButtonText != null &&
              rightButtonCountdownSeconds != null &&
              countdownTimer == null) {
            countdownTimer = Timer.periodic(const Duration(seconds: 1), (
              Timer timer,
            ) async {
              if (!rootNavigator.mounted || countdownInvalidated) {
                timer.cancel();
                countdownTimer = null;
                return;
              }

              if (countdownRemaining <= 1) {
                timer.cancel();
                countdownTimer = null;
                await closeDialog();
                if (!countdownInvalidated && onRightPressed != null) {
                  await onRightPressed();
                }
                if (!completer.isCompleted) {
                  completer.complete();
                }
                return;
              }

              countdownRemaining -= 1;
              if (context.mounted) {
                setState(() {});
              }
            });
          }

          final String? effectiveRightButtonText = rightButtonTextBuilder != null
              ? rightButtonTextBuilder(countdownRemaining)
              : rightButtonText;

          return SafeArea(
            child: Center(
              child:               _MessageDialogCard(
                isDark: isDark,
                width: dialogWidth,
                message: message,
                showHelperText: showHelperText,
                iconData: iconData,
                iconWidget: iconWidget,
                leftButtonText: leftButtonText,
                rightButtonText: rightButtonText,
                effectiveRightButtonText: effectiveRightButtonText,
                isProcessing: isProcessing,
                rightButtonColor: rightButtonColor,
                iconColor: iconColor,
                onLeftPressed: leftButtonText == null
                    ? null
                    : () async {
                        setState(() {
                          isProcessing = true;
                        });
                        try {
                          await closeDialog();
                          if (onLeftPressed != null) {
                            await onLeftPressed();
                          }
                        } finally {
                          if (!completer.isCompleted) {
                            completer.complete();
                          }
                        }
                      },
                onRightPressed: rightButtonText == null
                    ? null
                    : () async {
                        setState(() {
                          isProcessing = true;
                        });
                        try {
                          await closeDialog();
                          if (onRightPressed != null) {
                            await onRightPressed();
                          }
                        } finally {
                          if (!completer.isCompleted) {
                            completer.complete();
                          }
                        }
                      },
              ),
            ),
          );
        },
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final CurvedAnimation curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );

  countdownInvalidated = true;
  countdownTimer?.cancel();
  // TODO 与 pop_up_input 一致：先取消对 showMessageState 的监听，再置 false。
  // TODO 否则 listener 会在弹窗已 pop 后再 pop 一次，误关闭底层页面（例如游戏页）。
  await listener.cancel();
  bottomNavigationInfo.changeShowMessageState(false);
  if (!completer.isCompleted) {
    completer.complete();
  }
  await completer.future;
}

/// 在给定最大宽度与样式下，判断按钮标题是否会从第二行起折行。
bool _messageDialogButtonTextWraps({
  required String text,
  required double labelMaxWidth,
  required TextStyle style,
  required TextDirection textDirection,
}) {
  if (text.isEmpty || labelMaxWidth <= 8) return false;
  final TextPainter painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: textDirection,
  );
  painter.layout(maxWidth: labelMaxWidth);
  return painter.computeLineMetrics().length > 1;
}

/// 弹窗底部按钮文案：单行时居中一行；需折行时最多三行居中。
class _MessageDialogButtonLabel extends StatelessWidget {
  final String text;
  final Color color;
  final FontWeight fontWeight;
  final bool multiline;

  const _MessageDialogButtonLabel({
    required this.text,
    required this.color,
    required this.fontWeight,
    required this.multiline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: multiline ? 3 : 1,
        softWrap: multiline,
        overflow: multiline ? TextOverflow.clip : TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          height: 1.28,
          fontWeight: fontWeight,
          color: color,
        ),
      ),
    );
  }
}

/**
 * TODO 普通确认弹窗主体卡片。
 * 作用：
 * 1. 把确认弹窗的视觉壳层和按钮布局抽成独立组件。
 * 2. 让真正显示弹窗和后台预热都复用同一套 Widget 树。
 * 3. 避免首开和正式显示走两套实现，降低维护成本和样式偏差风险。
 */
class _MessageDialogCard extends StatelessWidget {
  final bool isDark;
  final double? width;
  final String message;
  final bool showHelperText;
  final IconData iconData;
  final Widget? iconWidget;
  final String? leftButtonText;
  final String? rightButtonText;
  final String? effectiveRightButtonText;
  final bool isProcessing;
  final Future<void> Function()? onLeftPressed;
  final Future<void> Function()? onRightPressed;
  final Color? rightButtonColor;
  final Color? iconColor;

  const _MessageDialogCard({
    required this.isDark,
    required this.message,
    required this.showHelperText,
    required this.iconData,
    required this.leftButtonText,
    required this.rightButtonText,
    required this.effectiveRightButtonText,
    required this.isProcessing,
    required this.onLeftPressed,
    required this.onRightPressed,
    this.rightButtonColor,
    this.iconColor,
    this.width,
    this.iconWidget,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = isDark ? Colors.white : const Color(0xFF222222);
    final Color subColor = isDark
        ? Colors.white.withValues(alpha: 0.74)
        : const Color(0xFF6B7280);

    final double screenW = MediaQuery.sizeOf(context).width;
    final double cardW = width ?? min(screenW * 0.86, 408.0);
    final double rowInnerW = cardW - 40;
    final bool twoButtons =
        leftButtonText != null && rightButtonText != null;
    final double slotW =
        twoButtons ? (rowInnerW - 12) / 2 : rowInnerW;
    const double kBtnHorizontalPadding = 10;
    final double labelMaxW =
        (slotW - 2 * kBtnHorizontalPadding - 8).clamp(32.0, 600.0);
    final TextDirection textDir = Directionality.of(context);
    final TextStyle leftLabelStyle = TextStyle(
      fontSize: 14,
      height: 1.28,
      fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
      color: textColor,
    );
    final TextStyle rightLabelStyle = TextStyle(
      fontSize: 14,
      height: 1.28,
      fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
      color: ColorConstants.lightTextColor,
    );
    final String rightMeasureText =
        effectiveRightButtonText ?? rightButtonText ?? '';
    final bool leftMultiline = leftButtonText != null &&
        _messageDialogButtonTextWraps(
          text: leftButtonText!,
          labelMaxWidth: labelMaxW,
          style: leftLabelStyle,
          textDirection: textDir,
        );
    final bool rightMultiline = rightButtonText != null &&
        !isProcessing &&
        _messageDialogButtonTextWraps(
          text: rightMeasureText,
          labelMaxWidth: labelMaxW,
          style: rightLabelStyle,
          textDirection: textDir,
        );
    final double leftButtonMinHeight =
        leftButtonText == null ? 48 : (leftMultiline ? 56 : 48);
    final double rightButtonMinHeight = rightButtonText == null
        ? 48
        : (isProcessing ? 48 : (rightMultiline ? 56 : 48));
    final double leftPadV = leftMultiline ? 10 : 12;
    final double rightPadV = rightMultiline ? 10 : 12;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isDark ? ColorConstants.nightHighlightColor : Colors.white,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF171926), Color(0xFF1C2230)]
                : const [Color(0xFFFFFCF6), Color(0xFFFFFFFF)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? const Color(0xFF8DB7FF).withValues(alpha: 0.14)
                : ColorConstants.themeColor.withValues(alpha: 0.18),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.26)
                  : const Color(0xFFD8E0EC).withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
            if (isDark)
              BoxShadow(
                color: const Color(0xFF8DB7FF).withValues(alpha: 0.10),
                blurRadius: 20,
                offset: const Offset(0, -2),
              ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 14,
              left: 18,
              child: Container(
                width: 26,
                height: 4,
                decoration: BoxDecoration(
                  color: iconColor ?? ColorConstants.themeColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            if (isDark)
              Positioned(
                top: -18,
                right: -12,
                child: IgnorePointer(
                  child: Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF8DB7FF).withValues(alpha: 0.16),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : (iconColor ?? ColorConstants.themeColor).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : (iconColor ?? ColorConstants.themeColor).withValues(alpha: 0.16),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: iconWidget ?? Icon(
                      iconData,
                      size: 24,
                      color: iconColor ?? (isDark ? Colors.white : const Color(0xFF6E5312)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (showHelperText) ...[
                    const SizedBox(height: 6),
                    Text(
                      easy.tr('constant.continue_after_confirm'),
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                        color: subColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (leftButtonText != null || rightButtonText != null) ...[
                    const SizedBox(height: 22),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (leftButtonText != null)
                          Expanded(
                            child: Opacity(
                              opacity: isProcessing ? 0.72 : 1,
                              child: OutlinedButton(
                                onPressed: isProcessing ? null : onLeftPressed,
                                style: OutlinedButton.styleFrom(
                                  minimumSize: Size(0, leftButtonMinHeight),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: kBtnHorizontalPadding,
                                    vertical: leftPadV,
                                  ),
                                  side: BorderSide(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : const Color(0xFFE0E6EF),
                                  ),
                                  backgroundColor: isDark
                                      ? Colors.white.withValues(alpha: 0.03)
                                      : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _MessageDialogButtonLabel(
                                  text: leftButtonText!,
                                  color: textColor,
                                  fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                                  multiline: leftMultiline,
                                ),
                              ),
                            ),
                          ),
                        if (leftButtonText != null && rightButtonText != null)
                          const SizedBox(width: 12),
                        if (rightButtonText != null)
                          Expanded(
                            child: Opacity(
                              opacity: isProcessing ? 0.72 : 1,
                              child: ElevatedButton(
                                onPressed: isProcessing ? null : onRightPressed,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size(0, rightButtonMinHeight),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: kBtnHorizontalPadding,
                                    vertical: rightPadV,
                                  ),
                                  elevation: 0,
                                  backgroundColor: rightButtonColor ?? ColorConstants.themeColor,
                                  foregroundColor:
                                      rightButtonColor != null
                                          ? Colors.white
                                          : ColorConstants.lightTextColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: isProcessing
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          color: rightButtonColor != null
                                              ? Colors.white
                                              : ColorConstants.lightTextColor,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : _MessageDialogButtonLabel(
                                        text: rightMeasureText,
                                        color: rightButtonColor != null
                                            ? Colors.white
                                            : ColorConstants.lightTextColor,
                                        fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                                        multiline: rightMultiline,
                                      ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
