import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app/api/post_request.dart';
import 'package:app/util/log_util.dart';

/// 绑定用户 ID 到 FCM Token。
///
/// 用户登录后调用，将 Token 与用户关联。
/// 这样推送给指定用户时，可以通过 user_id 查找 Token。
class FcmBindUser {
  /// 绑定用户 ID 到当前设备的 FCM Token。
  ///
  /// [user_id] 用户 ID。
  static Future<void> execute(int user_id) async {
    try {
      final messaging = FirebaseMessaging.instance;
      final String? token = await messaging.getToken();
      if (token == null) {
        logUtil(msg: 'FCM: 绑定用户失败，无法获取 Token', type: 'e');
        return;
      }

      final result = await postRequest<Map<String, dynamic>>(
        path: 'fcm_token/bind_user',
        parameter: {
          'token': token,
          'user_id': user_id,
        },
        showTips: false,
        fromJson: (json) => json,
      );

      if (result.status) {
        logUtil(msg: 'FCM: Token 已绑定用户: $user_id');
      } else {
        logUtil(msg: 'FCM: 绑定用户失败: ${result.message}', type: 'w');
      }
    } catch (e) {
      logUtil(msg: 'FCM: 绑定用户异常: $e', type: 'e');
    }
  }
}
