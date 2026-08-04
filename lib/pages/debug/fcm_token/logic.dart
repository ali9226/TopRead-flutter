import 'package:app/util/log_util.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// FCM Token 调试逻辑。
class FcmTokenLogic {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// 获取 FCM Token，失败返回 null。
  Future<String?> getToken() async {
    try {
      final String? token = await _messaging.getToken();
      if (token != null) {
        final int previewLength = token.length < 20 ? token.length : 20;
        logUtil(
          msg:
              'Debug: FCM Token 获取成功: '
              '${token.substring(0, previewLength)}...',
        );
      } else {
        logUtil(msg: 'Debug: FCM Token 获取失败', type: 'w');
      }
      return token;
    } catch (e) {
      logUtil(msg: 'Debug: 获取 FCM Token 异常: $e', type: 'e');
      return null;
    }
  }
}
