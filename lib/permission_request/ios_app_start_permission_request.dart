import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:app/permission_request/app_tracking_transparency_permission_request.dart';
import 'package:app/permission_request/notification_permission_request.dart';
import 'package:app/util/device/app_environment.dart';
import 'package:app/util/log_util.dart';
import 'package:app/util/storage_util/index.dart';

/// iOS App 启动阶段的系统权限协调器。
///
/// 触发顺序：
/// 1. [prepare_for_app_launch] 在 `GetStorage.init()` 之后、`runApp()` 之前调用，
///    只判断当前是否为首次安装启动，不展示任何系统弹窗。
/// 2. 首次安装启动时，由 iOS 自己处理首次网络访问可能产生的系统授权弹窗；
///    本协调器不会申请通知权限或 ATT。
/// 3. 第二次及以后启动时，由 [request_after_first_frame] 先检查通知权限。
/// 4. 如果通知权限尚未决定，本次只申请通知权限并结束，不继续申请 ATT。
/// 5. 如果通知权限已经决定，不会出现通知弹窗，此时再检查并按需申请 ATT。
///
/// 这样可以保证 App 启动阶段同一轮最多出现一个由 App 主动发起的系统权限弹窗。
class IosAppStartPermissionRequest {
  const IosAppStartPermissionRequest._();

  /// 记录当前安装是否已经完成过一次 App 启动。
  static const String _has_launched_storage_key = 'ios_app_has_launched_before';

  /// 当前进程是否已经完成首次启动状态准备。
  static bool _is_prepared = false;

  /// 当前进程是否属于安装后的第一次启动。
  static bool _is_first_launch_session = true;

  /// 当前正在执行的启动权限流程，防止根组件重复构建时并发申请。
  static Future<void>? _active_request;

  /// 在 `GetStorage.init()` 之后、`runApp()` 之前准备 iOS 启动状态。
  ///
  /// 此方法只读写本地首次启动标记，不检查、不申请任何系统权限。
  static Future<void> prepare_for_app_launch() async {
    if (!isIOSApp || _is_prepared) return;

    try {
      final String? has_launched = await StorageUtil.getData(
        _has_launched_storage_key,
      );
      _is_first_launch_session = has_launched != 'true';
      _is_prepared = true;

      if (_is_first_launch_session) {
        // 首次启动立即落库；本进程仍通过内存状态保持“首次启动”身份。
        await StorageUtil.saveData(_has_launched_storage_key, 'true');
      }
    } catch (error) {
      // 本地状态无法确认时按首次启动处理，优先避免出现多个系统弹窗。
      _is_first_launch_session = true;
      _is_prepared = true;
      logUtil(msg: 'iOS 首次启动状态准备失败: $error', type: 'e');
    }
  }

  /// 在根组件第一帧完成后调用，按既定顺序处理 iOS 启动权限。
  static Future<void> request_after_first_frame() {
    if (!isIOSApp) {
      return Future<void>.value();
    }

    final Future<void>? active_request = _active_request;
    if (active_request != null) {
      return active_request;
    }

    final Future<void> request = _request_after_first_frame_internal();
    _active_request = request;
    return request.whenComplete(() {
      if (identical(_active_request, request)) {
        _active_request = null;
      }
    });
  }

  /// 执行实际的 iOS 启动权限顺序。
  static Future<void> _request_after_first_frame_internal() async {
    if (!_is_prepared) {
      await prepare_for_app_launch();
    }

    if (_is_first_launch_session) {
      logUtil(msg: 'iOS 首次安装启动：跳过通知权限和 ATT 启动检查');
      return;
    }

    await _wait_until_app_resumed();
    final IosNotificationAppStartRequestResult notification_result =
        await NotificationPermissionRequest.request_on_ios_app_start();

    if (notification_result !=
        IosNotificationAppStartRequestResult.no_prompt_needed) {
      // 本次已展示通知弹窗或无法确认通知状态，都不继续申请 ATT。
      return;
    }

    await AppTrackingTransparencyPermissionRequest.request_on_ios_app_start();
  }

  /// 系统权限弹窗只能在 App 处于前台活动状态时发起。
  static Future<void> _wait_until_app_resumed() async {
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      return;
    }

    final Completer<void> completer = Completer<void>();
    late final AppLifecycleListener listener;
    listener = AppLifecycleListener(
      onResume: () {
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
    );
    try {
      await completer.future;
    } finally {
      listener.dispose();
    }
  }
}
