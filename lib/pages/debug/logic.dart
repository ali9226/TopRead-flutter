import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app/util/log_util.dart';

/// 调试页面逻辑层。
class Logic {
  /// Firebase Messaging 实例。
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// 获取 FCM Token。
  ///
  /// 返回 FCM Token 字符串，获取失败返回 null。
  Future<String?> getFcmToken() async {
    try {
      final String? token = await _messaging.getToken();
      if (token != null) {
        logUtil(msg: 'Debug: FCM Token 获取成功: ${token.substring(0, 20)}...');
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