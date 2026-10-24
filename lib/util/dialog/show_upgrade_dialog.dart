// ignore_for_file: non_constant_identifier_names

import 'package:app/config/layout_config.dart';
import 'dart:async';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/components/app_wrapper/utils/app_router.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/stores/bottom_navigation_info.dart';
import 'package:app/stores/device_info.dart';

/* TODO
 * 专用升级弹窗。
 *
 * 布局结构：
 * ┌──────────────────────────────┐
 * │  ── (顶部装饰条)              │
 * │                              │
 * │  [upgrade图标]  v1.0.0 → v2.0.0  │
 * │                              │
 * │  更新说明文案（左对齐）        │
 * │                              │
 * │  [ 取消 ]      [ 立即升级 ]   │  ← 可选升级时显示取消
 * │              [ 立即升级 ]     │  ← 强制升级时仅显示升级
 * └──────────────────────────────┘
 *
 * 参数 [currentVersion]：当前版本号。
 * 参数 [latestVersion]：最新版本号。
 * 参数 [updateContent]：更新说明文案。
 * 参数 [rightButtonText]：右侧按钮文案。
 * 参数 [leftButtonText]：左侧按钮文案（null 时不显示）。
 * 参数 [allowMaskDismiss]：是否允许点击遮罩关闭。
 * 参数 [onRightPressed]：点击右侧按钮的回调。
 * 参数 [onLeftPressed]：点击左侧按钮的回调。
 */
Future<void> showUpgradeDialog({
  required String currentVersion,
  required String latestVersion,
  required String updateContent,
  required String rightButtonText,
  String? leftButtonText,
  bool allowMaskDismiss = true,
  Future<void> Function()? onRightPressed,
  Future<void> Function()? onLeftPressed,
}) async {
  final DeviceInfo deviceInfo = Get.find<DeviceInfo>();
  final BottomNavigationInfo bottomNavigationInfo =
      Get.find<BottomNavigationInfo>();
  final bool isDark = deviceInfo.theme.value == ThemeMode.dark;
  final NavigatorState? rootNavigator = AppRouter.navigatorState();
  if (rootNavigator == null) return;

  final BuildContext rootContext = rootNavigator.context;
  final Completer<void> completer = Completer<void>();

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
    barrierLabel: 'upgrade_dialog',
    barrierColor: ColorConstants.shadowColor.withValues(alpha: isDark ? 0.54 : 0.34),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (context, animation, secondaryAnimation) {
      final double screenWidth = MediaQuery.of(context).size.width;
      final double dialogWidth = min(screenWidth * 0.86, 408.0);
      bool isProcessing = false;

      Future<void> closeDialog() async {
        if (rootNavigator.mounted && rootNavigator.canPop()) {
          rootNavigator.pop();
        }
      }

      return StatefulBuilder(
        builder: (context, setState) {
          final Color textColor = isDark
              ? ColorConstants.whiteColor
              : ColorConstants.lightTextColor;

          return SafeArea(
            child: Center(
              child: Material(
                color: ColorConstants.transparent,
                child: Container(
                  width: dialogWidth,
                  margin: const EdgeInsets.symmetric(
                    horizontal: LayoutConfig.space_20,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? null : ColorConstants.whiteColor,
                    gradient: isDark
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [ColorConstants.nightHighlightColor, ColorConstants.pages_bill_widgets_bill_record_card_tone],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(LayoutConfig.radius_24),
                    border: Border.all(
                      color: isDark
                          ? ColorConstants.util_dialog_show_upgrade_dialog_tone
                          : ColorConstants.util_dialog_show_upgrade_dialog_tone_2ef8d02d,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? ColorConstants.shadowColor.withValues(alpha: 0.2588)
                            : ColorConstants.util_dialog_show_upgrade_dialog_tone_2ed8e0ec,
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                      if (isDark)
                        BoxShadow(
                          color: ColorConstants.util_dialog_show_upgrade_dialog_tone_1a8db7ff,
                          blurRadius: 20,
                          offset: const Offset(0, -2),
                        ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // TODO 顶部装饰条。
                      Positioned(
                        top: 14,
                        left: 18,
                        child: Container(
                          width: 26,
                          height: 4,
                          decoration: BoxDecoration(
                            color: ColorConstants.themeColor,
                            borderRadius: BorderRadius.circular(
                              LayoutConfig.radius_pill,
                            ),
                          ),
                        ),
                      ),
                      // TODO 夜间模式右上角光晕。
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
                                    ColorConstants.util_dialog_show_upgrade_dialog_tone_298db7ff,
                                    ColorConstants.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      // TODO 非强制升级时，右上角显示关闭按钮。
                      if (leftButtonText != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Material(
                            color: ColorConstants.transparent,
                            child: InkWell(
                              onTap: () async {
                                await closeDialog();
                                if (onLeftPressed != null) {
                                  await onLeftPressed();
                                }
                              },
                              borderRadius: BorderRadius.circular(
                                LayoutConfig.radius_20,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(
                                  LayoutConfig.space_8,
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                  color: isDark
                                      ? ColorConstants.util_dialog_show_upgrade_dialog_tone_80ffffff
                                      : ColorConstants.util_dialog_show_upgrade_dialog_tone_ff9ca3af,
                                ),
                              ),
                            ),
                          ),
                        ),
                      // TODO 主体内容。
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          LayoutConfig.space_20,
                          LayoutConfig.space_24,
                          LayoutConfig.space_20,
                          LayoutConfig.space_20,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // TODO 图标 + 版本号对比行。
                            const SizedBox(height: LayoutConfig.space_10),
                            Row(
                              children: [
                                // TODO 升级图标容器。
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? ColorConstants.util_dialog_show_upgrade_dialog_tone_dffffff
                                        : ColorConstants.whiteColor,
                                    borderRadius: BorderRadius.circular(
                                      LayoutConfig.radius_18,
                                    ),
                                    border: Border.all(
                                      color: isDark
                                          ? ColorConstants.util_dialog_show_upgrade_dialog_tone_fffffff
                                          : ColorConstants.util_dialog_show_upgrade_dialog_tone_ffe5e7eb,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: SvgIcon(
                                    name: isDark ? 'upgrade' : 'logo',
                                    width: 28,
                                    height: 28,
                                    color: isDark
                                        ? ColorConstants.themeColor
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: LayoutConfig.space_14),
                                // TODO 版本号对比。
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        easy.tr('app_update.upgrade_title'),
                                        style: TextStyle(
                                          fontSize: 16,
                                          height: 1.3,
                                          fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: LayoutConfig.space_6,
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'v$currentVersion',
                                            style: TextStyle(
                                              fontSize: 13,
                                              height: 1.2,
                                              fontWeight:
                                                  FontConfig.adjustedWeight(FontWeight.w400),
                                              color: isDark
                                                  ? ColorConstants.whiteColor
                                                  : ColorConstants.lightTextColor,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: LayoutConfig.space_4,
                                            ),
                                            child: Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              size: 10,
                                              color: isDark
                                                  ? ColorConstants.whiteColor
                                                  : ColorConstants.lightTextColor,
                                            ),
                                          ),
                                          Text(
                                            'v$latestVersion',
                                            style: TextStyle(
                                              fontSize: 13,
                                              height: 1.2,
                                              fontWeight:
                                                  FontConfig.adjustedWeight(FontWeight.w500),
                                              color: ColorConstants.themeColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // TODO 更新说明文案（左对齐）。
                            if (updateContent.isNotEmpty) ...[
                              const SizedBox(height: LayoutConfig.space_16),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  updateContent,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.6,
                                    fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
                                    color: isDark
                                        ? ColorConstants.whiteColor
                                        : ColorConstants.lightTextColor,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                            ],
                            // TODO 按钮区域。
                            const SizedBox(height: LayoutConfig.space_22),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (leftButtonText != null)
                                  Expanded(
                                    child: Opacity(
                                      opacity: isProcessing ? 0.72 : 1,
                                      child: OutlinedButton(
                                        onPressed: isProcessing
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
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: const Size(0, 48),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: LayoutConfig.space_10,
                                            vertical: LayoutConfig.space_12,
                                          ),
                                          side: BorderSide(
                                            color: isDark
                                                ? ColorConstants.util_dialog_show_upgrade_dialog_tone_14ffffff
                                                : ColorConstants.util_dialog_show_upgrade_dialog_tone_ffe0e6ef,
                                          ),
                                          backgroundColor: isDark
                                              ? ColorConstants.util_dialog_show_upgrade_dialog_tone_8ffffff
                                              : ColorConstants.whiteColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              LayoutConfig.radius_16,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          leftButtonText,
                                          style: TextStyle(
                                            fontSize: 14,
                                            height: 1.28,
                                            fontWeight:
                                                FontConfig.adjustedWeight(FontWeight.w500),
                                            color: textColor,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (leftButtonText != null)
                                  const SizedBox(width: LayoutConfig.space_12),
                                Expanded(
                                  child: Opacity(
                                    opacity: isProcessing ? 0.72 : 1,
                                    child: ElevatedButton(
                                      onPressed: isProcessing
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
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size(0, 48),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: LayoutConfig.space_10,
                                          vertical: LayoutConfig.space_12,
                                        ),
                                        elevation: 0,
                                        backgroundColor:
                                            ColorConstants.themeColor,
                                        foregroundColor:
                                            ColorConstants.lightTextColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            LayoutConfig.radius_16,
                                          ),
                                        ),
                                      ),
                                      child: isProcessing
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                color: ColorConstants.lightTextColor,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(
                                              rightButtonText,
                                              style: TextStyle(
                                                fontSize: 14,
                                                height: 1.28,
                                                fontWeight:
                                                    FontConfig.adjustedWeight(FontWeight.w500),
                                                color: ColorConstants.lightTextColor,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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

  await listener.cancel();
  bottomNavigationInfo.changeShowMessageState(false);
  if (!completer.isCompleted) {
    completer.complete();
  }
  await completer.future;
}
