import 'package:get/get.dart';
import 'package:app/fcm/bind_user.dart';
import 'package:app/fcm/unbind_user.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/log_util.dart';

/// FCM 认证切换处理。
///
/// 负责处理用户登录/登出时的 FCM Token 绑定/解绑：
/// 1. 登录成功：绑定用户 ID 到当前设备的 FCM Token。
/// 2. 登出：解绑当前设备的 FCM Token 与用户关联。
class FcmAuth {
  /// 登录成功后绑定用户。
  ///
  /// 将当前设备的 FCM Token 与用户 ID 关联。
  /// 这样推送给指定用户时，可以通过 user_id 查找 Token。
  static Future<void> onLoginSuccess() async {
    final user_info = Get.find<UserInformation>();
    if (!user_info.isLoggedIn.value || user_info.userInfo.value == null) {
      logUtil(msg: 'FcmAuth: 用户未登录，跳过绑定');
      return;
    }

    final int user_id = user_info.userInfo.value!.id;
    logUtil(msg: 'FcmAuth: 登录成功，绑定用户 ID: $user_id');
    await FcmBindUser.execute(user_id);
  }

  /// 登出后解绑用户。
  ///
  /// 解除当前设备的 FCM Token 与用户的关联。
  /// 用户退出后不会再收到推送给该用户的消息。
  static Future<void> onLogout() async {
    logUtil(msg: 'FcmAuth: 登出，解绑用户');
    await FcmUnbindUser.execute();
  }
}
