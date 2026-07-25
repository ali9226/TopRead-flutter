import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:permission_handler/permission_handler.dart';
import 'package:app/util/dialog/show_message.dart';
import 'package:app/util/storage_util/index.dart';

class NotificationPermission {
  const NotificationPermission._();

  static const _dismissedKey = 'notification_permission_dismissed';

  static Future<void> checkAndRequest() async {
    final dismissed = await StorageUtil.getData(_dismissedKey);
    if (dismissed == 'true') return;

    final status = await Permission.notification.status;
    if (status.isGranted || status.isLimited) return;

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
  }
}
