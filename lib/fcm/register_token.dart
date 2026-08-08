import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:app/api/post_request.dart';
import 'package:app/util/device/app_environment.dart';
import 'package:app/util/log_util.dart';
import 'package:app/util/storage_util/index.dart';

/// FCM Token 本地缓存 key。
const String _fcm_token_key = 'fcm_device_token';

/// 注册 FCM Token 到后端。
///
/// App 启动时调用，无论是否登录都会注册 Token。
/// 用于全量广播推送。
class FcmRegisterToken {
  /// 获取 FCM Token 并注册到后端。
  ///
  /// 每次启动都会注册，确保设备信息更新。
  static Future<void> execute() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final String? token = await messaging.getToken(
        vapidKey: isWebBrowser
            ? 'BNZQeUAHYOjr5AQeAbdRzwqCB4a-XQNifHD9B_Gxa9N-8NVADu3moHCF2j7u7uS8dtb0Bnp1-eMLqGQOguBwFgo'
            : null,
      );
      if (token == null) {
        logUtil(msg: 'FCM: 获取 Token 失败', type: 'e');
        return;
      }

      logUtil(msg: 'FCM Token: ${token.substring(0, 20)}...');

      // 每次启动都注册，更新设备信息。
      await _registerToServer(token);
    } catch (e) {
      logUtil(msg: 'FCM: 获取 Token 异常: $e', type: 'e');
    }
  }

  /// 获取设备信息。
  static Future<Map<String, String>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();
    String device_model = '';
    String device_name = '';
    String os_version = '';

    try {
      if (isWebBrowser) {
        final webInfo = await deviceInfo.webBrowserInfo;
        device_model = webInfo.browserName.name;
        device_name = webInfo.userAgent ?? '';
        os_version = webInfo.platform ?? '';
      } else if (currentEnvironment == AppEnvironment.ios) {
        final iosInfo = await deviceInfo.iosInfo;
        device_model = iosInfo.model ?? '';
        device_name = iosInfo.name ?? '';
        os_version = 'iOS ${iosInfo.systemVersion}';
      } else if (currentEnvironment == AppEnvironment.android) {
        final androidInfo = await deviceInfo.androidInfo;
        device_model = '${androidInfo.brand} ${androidInfo.model}';
        device_name = androidInfo.device ?? '';
        os_version = 'Android ${androidInfo.version.release}';
      }
    } catch (e) {
      logUtil(msg: 'FCM: 获取设备信息异常: $e', type: 'e');
    }

    // 获取当前用户选择的语种。
    final String language_code = await _getCurrentLanguageCode();

    return {
      'device_model': device_model,
      'device_name': device_name,
      'os_version': os_version,
      'app_version': packageInfo.version,
      'language_code': language_code,
    };
  }

  /// 获取当前用户选择的语种代码。
  ///
  /// 返回语种代码，如 'zh', 'en', 'ja' 等。
  static Future<String> _getCurrentLanguageCode() async {
    try {
      // 从本地存储获取当前语种。
      final String? language = await StorageUtil.getData('language');
      if (language != null && language.isNotEmpty) {
        // 提取语种代码（如 'zh-CN' -> 'zh'）。
        return language.split('-').first;
      }
    } catch (e) {
      logUtil(msg: 'FCM: 获取语种失败: $e', type: 'e');
    }
    // 默认返回英语。
    return 'en';
  }

  /// 将 FCM Token 注册到后端（不绑定用户）。
  static Future<void> _registerToServer(String token) async {
    try {
      final String platform = currentEnvironment.name;

      // 获取设备信息。
      final deviceInfo = await _getDeviceInfo();

      final result = await postRequest<Map<String, dynamic>>(
        path: 'fcm_token/register_token',
        parameter: {
          'token': token,
          'platform': platform,
          'device_model': deviceInfo['device_model'],
          'device_name': deviceInfo['device_name'],
          'os_version': deviceInfo['os_version'],
          'app_version': deviceInfo['app_version'],
          'language_code': deviceInfo['language_code'],
        },
        showTips: false,
        fromJson: (json) => json,
      );

      if (result.status) {
        // 注册成功，缓存 Token。
        await StorageUtil.saveData(_fcm_token_key, token);
        logUtil(msg: 'FCM: Token 注册成功（未绑定用户）');
      } else {
        logUtil(msg: 'FCM: Token 注册失败: ${result.message}', type: 'w');
      }
    } catch (e) {
      logUtil(msg: 'FCM: Token 注册异常: $e', type: 'e');
    }
  }
}
