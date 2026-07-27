import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app/api/post_request.dart';
import 'package:app/util/log_util.dart';

/// 解绑 FCM Token 与用户关联。
///
/// 用户登出后调用，解除 Token 与用户的关联。
/// 用户退出后不会再收到推送给该用户的消息。
class FcmUnbindUser {
  /// 解绑当前设备的 FCM Token 与用户关联。
  static Future<void> execute() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final String? token = await messaging.getToken();
      if (token == null) {
        logUtil(msg: 'FCM: 解绑用户失败，无法获取 Token', type: 'e');
        return;
      }

      final result = await postRequest<Map<String, dynamic>>(
        path: 'fcm_token/unbind_user',
        parameter: {
          'token': token,
        },
        showTips: false,
        fromJson: (json) => json,
      );

      if (result.status) {
        logUtil(msg: 'FCM: Token 已解绑用户');
      } else {
        logUtil(msg: 'FCM: 解绑用户失败: ${result.message}', type: 'w');
      }
    } catch (e) {
      logUtil(msg: 'FCM: 解绑用户异常: $e', type: 'e');
    }
  }
}
