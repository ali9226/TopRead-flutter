import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:app/util/device/app_environment.dart';
import 'package:app/util/log_util.dart';

/// iOS 启动阶段检查通知权限后的处理结果。
enum IosNotificationAppStartRequestResult {
  /// 通知权限已经由用户决定，不会出现通知系统弹窗。
  no_prompt_needed,

  /// 通知权限尚未决定，本次已经发起通知系统弹窗。
  prompt_requested,

  /// 系统状态读取失败；为避免叠加其他权限弹窗，本次启动停止后续权限请求。
  status_check_failed,
}

/// 系统通知权限请求器。
///
/// Android 触发逻辑：
/// 1. App 打开后，由 [request_on_android_app_start] 立即检查通知权限。
/// 2. 已授权、已受系统限制或已永久拒绝时不申请。
/// 3. 仅在当前仍可申请但尚未授权时，展示 Android 系统通知权限弹窗。
///
/// iOS 触发逻辑：
/// 1. 首次安装启动时只处理系统网络授权，不在启动阶段申请通知权限。
/// 2. 第二次及以后启动时检查通知状态；尚未决定时申请一次并结束本轮权限流程。
/// 3. 用户手动登录、成功收藏小说、成功发表评论或成功提交创作者申请后也会检查。
/// 4. 已授权、已拒绝或受系统限制时不再申请。
///
/// 两个平台都只使用系统权限弹窗，不展示 App 自绘引导弹窗。
class NotificationPermissionRequest {
  const NotificationPermissionRequest._();

  /// 当前正在执行的权限请求，用于合并多个同时到达的业务触发。
  static Future<void>? _active_request;

  /// Android App 打开后调用。
  ///
  /// 已有权限或已永久拒绝时直接结束；其他未授权状态申请一次系统权限。
  static Future<void> request_on_android_app_start() {
    if (!isAndroidApp) {
      return Future<void>.value();
    }
    return _run_exclusive(_request_on_android_app_start_internal);
  }

  /// iOS 第二次及以后启动时调用。
  ///
  /// 返回 [IosNotificationAppStartRequestResult.prompt_requested] 时，启动权限协调器
  /// 必须结束本轮流程，不能紧接着申请 ATT，避免连续展示两个系统权限弹窗。
  static Future<IosNotificationAppStartRequestResult>
  request_on_ios_app_start() async {
    if (!isIOSApp) {
      return IosNotificationAppStartRequestResult.no_prompt_needed;
    }

    try {
      final NotificationSettings current_settings = await FirebaseMessaging
          .instance
          .getNotificationSettings();
      if (current_settings.authorizationStatus !=
          AuthorizationStatus.notDetermined) {
        return IosNotificationAppStartRequestResult.no_prompt_needed;
      }

      await _run_exclusive(_request_on_ios_if_needed_internal);
      return IosNotificationAppStartRequestResult.prompt_requested;
    } catch (error) {
      // 无法确认通知状态时不继续申请 ATT，避免两个未知权限流程发生竞争。
      logUtil(msg: 'iOS 启动阶段读取通知权限失败: $error', type: 'e');
      return IosNotificationAppStartRequestResult.status_check_failed;
    }
  }

  /// iOS 用户手动登录或注册成功后调用；Android 不执行。
  static Future<void> request_after_login() => _request_on_ios_if_needed();

  /// iOS 用户成功将小说加入收藏后调用；取消收藏和 Android 不调用。
  static Future<void> request_after_novel_favorite() =>
      _request_on_ios_if_needed();

  /// iOS 用户成功发表评论或回复后调用；Android 不执行。
  static Future<void> request_after_comment_published() =>
      _request_on_ios_if_needed();

  /// iOS 用户成功提交成为创作者的申请后调用；Android 不执行。
  static Future<void> request_after_creator_application() =>
      _request_on_ios_if_needed();

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

  /// Android App 启动时检查通知权限并在必要时发起系统请求。
  static Future<void> _request_on_android_app_start_internal() async {
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

  /// iOS 业务触发点入口，Android 和其他平台不执行。
  static Future<void> _request_on_ios_if_needed() {
    if (!isIOSApp) {
      return Future<void>.value();
    }
    return _run_exclusive(_request_on_ios_if_needed_internal);
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
