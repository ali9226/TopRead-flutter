import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:app/config/color_config.dart';
import 'package:app/stores/device_info.dart';

Timer? _toastTimer;

/* TODO
 * 显示底部提示弹窗。
 *
 * [message] 提示文案。
 * [duration] 展示时长，不传时默认 2 秒。
 */
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
    maskColor: Colors.transparent,
    usePenetrate: true,
    builder: (context) {
      final double screenWidth = MediaQuery.of(context).size.width;

      return Container(
        constraints: BoxConstraints(maxWidth: screenWidth * 0.85),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        margin: const EdgeInsets.only(bottom: 150),
        decoration: BoxDecoration(
          color: isDark
              ? ColorConstants.lightTextColor.withValues(alpha: 0.9)
              : Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(500),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 100,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message,
          style: TextStyle(
            color: isDark ? ColorConstants.whiteColor : Colors.white,
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
