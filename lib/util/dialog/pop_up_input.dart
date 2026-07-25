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
 * TODO 输入弹窗预热器。
 * 作用：
 * 1. 在用户真正点击“修改昵称 / 修改密码”之前，先把弹窗卡片和输入框构建一遍。
 * 2. 把首次打开时最重的布局、阴影、输入框主题解析等成本提前吃掉。
 * 3. 预热过程放在不可见 Overlay 里，不影响当前页面交互，也不会真的弹出给用户看。
 *
 * 好处：
 * - 首次打开输入弹窗时不会再遇到明显首帧卡顿。
 * - 预热逻辑集中在工具层，后续其他页面也能复用。
 */
class PopUpInputWarmUp {
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
                child: _PopUpInputDialog(
                  deviceInfo: deviceInfo,
                  message: 'warm_up',
                  leftButtonText: easy.tr('constant.cancel'),
                  rightButtonText: easy.tr('constant.ok'),
                  hintText: easy.tr('constant.hintText'),
                  autoFocus: false,
                  onLeftPressed: () async {},
                  onRightPressed: (_) async => true,
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

Future<void> popUpInput({
  BuildContext? context,
  required String message,
  String? leftButtonText,
  String? rightButtonText,
  String? hintText,
  bool allowMaskDismiss = false,
  void Function()? onLeftPressed,
  Future<dynamic> Function(String inputText)? onRightPressed,
}) async {
  final deviceInfo = Get.find<DeviceInfo>();
  final bottomNavigationInfo = Get.find<BottomNavigationInfo>();
  final rootNavigator = AppRouter.navigatorState();
  final dialogHostContext =
      context ?? rootNavigator?.context ?? Get.context ?? Get.overlayContext!;
  final navigator = Navigator.of(dialogHostContext, rootNavigator: true);

  bool dialogOpen = true;

  Future<void> closeDialog({VoidCallback? afterClose}) async {
    if (!dialogOpen) return;
    dialogOpen = false;
    FocusManager.instance.primaryFocus?.unfocus();
    if (navigator.mounted && navigator.canPop()) {
      navigator.pop();
    }
    afterClose?.call();
  }

  bottomNavigationInfo.changeShowMessageState(true);

  final listener = bottomNavigationInfo.showMessageState.listen((value) {
    if (value || !dialogOpen) return;
    closeDialog();
  });

  await showGeneralDialog<void>(
    context: dialogHostContext,
    barrierLabel: 'popUpInput',
    barrierDismissible: allowMaskDismiss,
    barrierColor: Colors.black.withValues(alpha: 0.34),
    transitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _PopUpInputDialog(
        deviceInfo: deviceInfo,
        message: message,
        leftButtonText: leftButtonText,
        rightButtonText: rightButtonText,
        hintText: hintText,
        autoFocus: true,
        onLeftPressed: () async {
          await closeDialog(afterClose: onLeftPressed);
        },
        onRightPressed: (inputText) async {
          dynamic result = true;
          if (onRightPressed != null) {
            result = await onRightPressed(inputText);
          }
          if (result != false) {
            await closeDialog();
          }
          return result != false;
        },
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
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

  dialogOpen = false;
  await listener.cancel();
  await Future<void>.delayed(Duration.zero);
  if (bottomNavigationInfo.showMessageState.value) {
    bottomNavigationInfo.changeShowMessageState(false);
  }
}

class _PopUpInputDialog extends StatefulWidget {
  final DeviceInfo deviceInfo;
  final String message;
  final String? leftButtonText;
  final String? rightButtonText;
  final String? hintText;
  final bool autoFocus;
  final Future<void> Function() onLeftPressed;
  final Future<bool> Function(String inputText) onRightPressed;

  const _PopUpInputDialog({
    required this.deviceInfo,
    required this.message,
    required this.leftButtonText,
    required this.rightButtonText,
    required this.hintText,
    required this.autoFocus,
    required this.onLeftPressed,
    required this.onRightPressed,
  });

  @override
  State<_PopUpInputDialog> createState() => _PopUpInputDialogState();
}

class _PopUpInputDialogState extends State<_PopUpInputDialog> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _focusTimer;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoFocus) {
      _focusTimer = Timer(const Duration(milliseconds: 120), () {
        if (!mounted || !_focusNode.canRequestFocus || _focusNode.hasFocus) {
          return;
        }
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _focusTimer?.cancel();
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.deviceInfo.theme.value == ThemeMode.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = min(screenWidth * 0.88, 400.0);

    return Material(
      color: Colors.transparent,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: dialogWidth),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: BoxDecoration(
                color: isDark
                    ? ColorConstants.nightHighlightColor
                    : const Color(0xFFFFFCF7),
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
                      : const Color(0xFFF0E3B2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.14),
                    blurRadius: 30,
                    offset: const Offset(0, 16),
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
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 26,
                      height: 4,
                      decoration: BoxDecoration(
                        color: ColorConstants.themeColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        widget.message,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                          color: isDark
                              ? Colors.white
                              : ColorConstants.lightTextColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        focusNode: _focusNode,
                        controller: _textController,
                        cursorColor: ColorConstants.themeColor,
                        enabled: !_isProcessing,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          hintText:
                              (widget.hintText == null ||
                                  widget.hintText!.isEmpty)
                              ? easy.tr('constant.hintText')
                              : widget.hintText,
                          hintStyle: TextStyle(
                            fontSize: 15,
                            color: ColorConstants.hintColor,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : const Color(0xFFFFFDF8),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : const Color(0xFFE7E5DE),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : const Color(0xFFE7E5DE),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: ColorConstants.themeColor,
                              width: 1.4,
                            ),
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark
                              ? Colors.white
                              : ColorConstants.lightTextColor,
                        ),
                        minLines: 1,
                        maxLines: 1,
                      ),
                      if (widget.leftButtonText != null ||
                          widget.rightButtonText != null) ...[
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            if (widget.leftButtonText != null)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isProcessing
                                      ? null
                                      : widget.onLeftPressed,
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48),
                                    side: BorderSide(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : const Color(0xFFE2E8F0),
                                    ),
                                    backgroundColor: isDark
                                        ? Colors.white.withValues(alpha: 0.03)
                                        : Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    widget.leftButtonText!,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: isDark
                                          ? Colors.white
                                          : ColorConstants.lightTextColor,
                                    ),
                                  ),
                                ),
                              ),
                            if (widget.leftButtonText != null &&
                                widget.rightButtonText != null)
                              const SizedBox(width: 12),
                            if (widget.rightButtonText != null)
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isProcessing
                                      ? null
                                      : () async {
                                          FocusManager.instance.primaryFocus
                                              ?.unfocus();
                                          setState(() {
                                            _isProcessing = true;
                                          });
                                          final shouldDismiss = await widget
                                              .onRightPressed(
                                                _textController.text,
                                              );
                                          if (!mounted || shouldDismiss) {
                                            return;
                                          }
                                          setState(() {
                                            _isProcessing = false;
                                          });
                                        },
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48),
                                    elevation: 0,
                                    backgroundColor: ColorConstants.themeColor,
                                    foregroundColor:
                                        ColorConstants.lightTextColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _isProcessing
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  ColorConstants.lightTextColor,
                                                ),
                                          ),
                                        )
                                      : Text(
                                          widget.rightButtonText!,
                                          style: const TextStyle(
                                            fontSize: 15,
                                          ),
                                        ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
