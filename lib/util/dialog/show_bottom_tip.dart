import 'package:app/config/layout_config.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:app/config/color_config.dart';
import 'package:app/stores/device_info.dart';

Timer? _toastTimer;

/// 显示底部提示弹窗。
///
/// [message] 提示文案。
/// [duration] 展示时长，不传时默认 2 秒。
Future<void> showBottomTip(String message, {Duration? duration}) async {
  final DeviceInfo deviceInfo = Get.find<DeviceInfo>();
  final bool isDark = deviceInfo.dark.value;
  final Duration displayTime = duration ?? const Duration(seconds: 2);

  _toastTimer?.cancel();
  await SmartDialog.dismiss(tag: 'bottom_tip');

  SmartDialog.show(
    tag: 'bottom_tip',
    alignment: Alignment.bottomCenter,
    animationType: SmartAnimationType.scale,
    maskColor: ColorConstants.transparent,
    usePenetrate: true,
    builder: (context) {
      final double screenWidth = MediaQuery.of(context).size.width;

      return Container(
        constraints: BoxConstraints(maxWidth: screenWidth * 0.85),
        padding: const EdgeInsets.symmetric(
          vertical: LayoutConfig.space_10,
          horizontal: LayoutConfig.space_20,
        ),
        margin: const EdgeInsets.only(bottom: 150),
        decoration: BoxDecoration(
          color: isDark
              ? ColorConstants.util_dialog_show_bottom_tip_tone
              : ColorConstants.util_dialog_show_bottom_tip_tone_b3222222,
          borderRadius: BorderRadius.circular(LayoutConfig.radius_pill),
          boxShadow: const [
            BoxShadow(
              color: ColorConstants.shadow_soft_1f,
              blurRadius: 100,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message,
          style: const TextStyle(
            color: ColorConstants.whiteColor,
            fontSize: 15,
          ),
          textAlign: TextAlign.left,
        ),
      );
    },
  );

  _toastTimer = Timer(displayTime, () {
    SmartDialog.dismiss(tag: 'bottom_tip');
    _toastTimer = null;
  });
}
