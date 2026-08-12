import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:app/permission_request/admob_consent_permission_request.dart';
import 'package:app/util/device/app_environment.dart';
import 'package:app/util/log_util.dart';

/// 系统通知权限请求器。
///
/// App 启动时，只有 UMP 状态已成功刷新且本次没有实际展示法规、IDFA 或 ATT
/// 界面，才继续检查通知权限。业务触发点也始终等待 UMP/ATT 流程结束。
/// 已授权、已拒绝或受系统限制时不再申请。
///
/// 两个平台都只使用系统权限弹窗，不展示 App 自绘引导弹窗。
class NotificationPermissionRequest {
  const NotificationPermissionRequest._();

  /// 当前正在执行的权限请求，用于合并多个同时到达的业务触发。
  static Future<void>? _active_request;

  /// UMP/ATT 本次未展示权限 UI 时，由启动协调器调用。
  static Future<void> request_on_app_start_if_needed() =>
      _request_on_mobile_if_needed();

  /// 用户手动登录或注册成功后调用。
  static Future<void> request_after_login() => _request_on_mobile_if_needed();

  /// 用户成功将小说加入收藏后调用；取消收藏不调用。
  static Future<void> request_after_novel_favorite() =>
      _request_on_mobile_if_needed();

  /// 用户成功发表评论或回复后调用。
  static Future<void> request_after_comment_published() =>
      _request_on_mobile_if_needed();

  /// 用户成功提交成为创作者的申请后调用。
  static Future<void> request_after_creator_application() =>
      _request_on_mobile_if_needed();

  /// 合并并发触发，保证同一时间只执行一次系统权限检查。
  static Future<void> _run_exclusive(Future<void> Function() operation) {
    final Future<void>? active_request = _active_request;
    if (active_request != null) {
      return active_request;
    }

    final Future<void> request = operation();
    _active_request = request;
    return request.whenComplete(() {
      if (identical(_active_request, request)) {
        _active_request = null;
      }
    });
  }

  /// Android 业务触发后检查通知权限并在必要时发起系统请求。
  static Future<void> _request_on_android_if_needed_internal() async {
    try {
      final PermissionStatus current_status =
          await Permission.notification.status;

      if (current_status.isGranted ||
          current_status.isPermanentlyDenied ||
          current_status.isRestricted ||
          current_status.isLimited ||
          current_status.isProvisional) {
        logUtil(msg: 'Android 通知权限无需申请: ${current_status.name}');
        return;
      }

      final PermissionStatus requested_status = await Permission.notification
          .request();
      logUtil(msg: 'Android 通知权限申请结束: ${requested_status.name}');
    } catch (error) {
      // 权限检查失败不阻塞 FCM 初始化和 Token 注册。
      logUtil(msg: 'Android 通知权限请求失败: $error', type: 'e');
    }
  }

  /// 移动端业务触发点入口，按平台调用相应的系统权限 API。
  static Future<void> _request_on_mobile_if_needed() {
    if (!isNativeMobileApp) {
      return Future<void>.value();
    }
    return _run_exclusive(_request_on_mobile_if_needed_internal);
  }

  static Future<void> _request_on_mobile_if_needed_internal() async {
    // 所有通知入口都排在 UMP 法规消息、IDFA 铺垫消息和 ATT 之后。
    await AdMobConsentPermissionRequest.request_before_ad();
    if (isAndroidApp) {
      await _request_on_android_if_needed_internal();
    } else {
      await _request_on_ios_if_needed_internal();
    }
  }

  /// 根据 iOS 系统状态判断是否可以展示系统弹窗。
  ///
  /// iOS 会持久保存通知授权结果：`notDetermined` 才允许请求；用户选择后会变为
  /// `authorized`、`provisional` 或 `denied`，因此无需额外维护容易失真的本地标记。
  static Future<void> _request_on_ios_if_needed_internal() async {
    try {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;
      final NotificationSettings current_settings = await messaging
          .getNotificationSettings();
      final AuthorizationStatus current_status =
          current_settings.authorizationStatus;

      if (current_status == AuthorizationStatus.authorized ||
          current_status == AuthorizationStatus.provisional) {
        return;
      }

      // iOS 能准确区分“尚未询问”和“已拒绝”。已拒绝时不再请求。
      if (current_status != AuthorizationStatus.notDetermined) {
        return;
      }

      final NotificationSettings requested_settings = await messaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );
      logUtil(msg: '通知权限申请结束: ${requested_settings.authorizationStatus.name}');
    } catch (error) {
      // 权限检查失败不影响当前登录、收藏、评论或创作者申请流程。
      logUtil(msg: 'iOS 通知权限请求失败: $error', type: 'e');
    }
  }
}
