// ignore_for_file: non_constant_identifier_names

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
  final BottomNavigationInfo bottomNavigationInfo = Get.find<BottomNavigationInfo>();
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
    barrierColor: Colors.black.withValues(alpha: isDark ? 0.54 : 0.34),
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
          final Color textColor =
              isDark ? Colors.white : const Color(0xFF222222);
          final Color subColor = isDark
              ? Colors.white.withValues(alpha: 0.6)
              : const Color(0xFF9CA3AF);

          return SafeArea(
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: dialogWidth,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: isDark ? null : ColorConstants.whiteColor,
                    gradient: isDark
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF171926), Color(0xFF1C2230)],
                          )
                        : null,
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
                      // TODO 顶部装饰条。
                      Positioned(
                        top: 14,
                        left: 18,
                        child: Container(
                          width: 26,
                          height: 4,
                          decoration: BoxDecoration(
                            color: ColorConstants.themeColor,
                            borderRadius: BorderRadius.circular(999),
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
                                    const Color(0xFF8DB7FF)
                                        .withValues(alpha: 0.16),
                                    Colors.transparent,
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
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                await closeDialog();
                                if (onLeftPressed != null) {
                                  await onLeftPressed();
                                }
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.5)
                                      : const Color(0xFF9CA3AF),
                                ),
                              ),
                            ),
                          ),
                        ),
                      // TODO 主体内容。
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // TODO 图标 + 版本号对比行。
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                // TODO 升级图标容器。
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : ColorConstants.whiteColor,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white
                                              .withValues(alpha: 0.06)
                                          : const Color(0xFFE5E7EB),
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
                                const SizedBox(width: 14),
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
                                          fontWeight: FontConfig.adjustedWeight(
                                              FontWeight.w500),
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'v$currentVersion',
                                            style: TextStyle(
                                              fontSize: 13,
                                              height: 1.2,
                                              fontWeight:
                                                  FontConfig.adjustedWeight(
                                                      FontWeight.w400),
                                              color: isDark
                                                  ? Colors.white
                                                  : ColorConstants
                                                      .lightTextColor,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4),
                                            child: Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              size: 10,
                                              color: isDark
                                                  ? Colors.white
                                                  : ColorConstants
                                                      .lightTextColor,
                                            ),
                                          ),
                                          Text(
                                            'v$latestVersion',
                                            style: TextStyle(
                                              fontSize: 13,
                                              height: 1.2,
                                              fontWeight:
                                                  FontConfig.adjustedWeight(
                                                      FontWeight.w500),
                                              color:
                                                  ColorConstants.themeColor,
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
                              const SizedBox(height: 16),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  updateContent,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.6,
                                    fontWeight: FontConfig.adjustedWeight(
                                        FontWeight.w400),
                                    color: isDark
                                        ? Colors.white
                                        : ColorConstants.lightTextColor,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                            ],
                            // TODO 按钮区域。
                            const SizedBox(height: 22),
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
                                                  if (onLeftPressed !=
                                                      null) {
                                                    await onLeftPressed();
                                                  }
                                                } finally {
                                                  if (!completer
                                                      .isCompleted) {
                                                    completer.complete();
                                                  }
                                                }
                                              },
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: const Size(0, 48),
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 12),
                                          side: BorderSide(
                                            color: isDark
                                                ? Colors.white
                                                    .withValues(alpha: 0.08)
                                                : const Color(0xFFE0E6EF),
                                          ),
                                          backgroundColor: isDark
                                              ? Colors.white
                                                  .withValues(alpha: 0.03)
                                              : Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: Text(
                                          leftButtonText,
                                          style: TextStyle(
                                            fontSize: 14,
                                            height: 1.28,
                                            fontWeight:
                                                FontConfig.adjustedWeight(
                                                    FontWeight.w500),
                                            color: textColor,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (leftButtonText != null)
                                  const SizedBox(width: 12),
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
                                                if (onRightPressed !=
                                                    null) {
                                                  await onRightPressed();
                                                }
                                              } finally {
                                                if (!completer
                                                    .isCompleted) {
                                                  completer.complete();
                                                }
                                              }
                                            },
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size(0, 48),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 12),
                                        elevation: 0,
                                        backgroundColor:
                                            ColorConstants.themeColor,
                                        foregroundColor:
                                            ColorConstants.lightTextColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: isProcessing
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child:
                                                  CircularProgressIndicator(
                                                color: Color(0xFF222222),
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(
                                              rightButtonText,
                                              style: TextStyle(
                                                fontSize: 14,
                                                height: 1.28,
                                                fontWeight:
                                                    FontConfig.adjustedWeight(
                                                        FontWeight.w500),
                                                color: const Color(
                                                    0xFF222222),
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
