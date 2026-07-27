import 'dart:async';

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app/stores/bottom_navigation_info.dart';
import 'package:app/util/dialog/show_message.dart';
import 'package:app/util/storage_util/index.dart';

class NotificationPermission {
  const NotificationPermission._();

  static const _dismissedKey = 'notification_permission_dismissed';

  static Future<void> checkAndRequest() async {
    final dismissed = await StorageUtil.getData(_dismissedKey);
    if (dismissed == 'true') return;

    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      return;
    }

    Timer? permissionCheckTimer;

    // 弹窗显示后，启动定时任务每秒检查通知权限。
    permissionCheckTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) async {
        final currentSettings =
            await FirebaseMessaging.instance.getNotificationSettings();
        if (currentSettings.authorizationStatus ==
                AuthorizationStatus.authorized ||
            currentSettings.authorizationStatus ==
                AuthorizationStatus.provisional) {
          timer.cancel();
          permissionCheckTimer = null;
          final bottomNavigationInfo = Get.find<BottomNavigationInfo>();
          bottomNavigationInfo.changeShowMessageState(false);
        }
      },
    );

    await showMessage(
      message: easy.tr('notification_permission.message'),
      leftButtonText: easy.tr('notification_permission.not_now'),
      rightButtonText: easy.tr('notification_permission.open_settings'),
      onLeftPressed: () async {
        await StorageUtil.saveData(_dismissedKey, 'true');
      },
      onRightPressed: () async {
        await openAppSettings();
      },
    );

    // 弹窗关闭后，确保定时任务被取消。
    permissionCheckTimer?.cancel();
    permissionCheckTimer = null;
  }
}
