import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:app/util/device/app_environment.dart';
import 'package:app/util/log_util.dart';

/// iOS App Tracking Transparency 授权状态。
enum AppTrackingAuthorizationStatus {
  not_determined,
  restricted,
  denied,
  authorized,
  unknown,
}

/// iOS ATT 权限请求器。
///
/// 启动触发逻辑：
/// 1. 首次安装启动时不检查 ATT，避免与系统网络授权弹窗叠加。
/// 2. 第二次及以后启动时，只有当通知权限不需要弹窗，才检查并按需申请 ATT。
/// 3. ATT 已授权、已拒绝或受系统限制时不再弹窗。
///
/// 广告触发逻辑：
/// 1. 用户点击“观看广告解锁短篇小说”时再次检查 ATT，作为启动流程之外的兜底。
/// 2. 该检查必须在 Google Mobile Ads SDK 初始化和广告请求之前完成。
class AppTrackingTransparencyPermissionRequest {
  const AppTrackingTransparencyPermissionRequest._();

  /// Flutter 与 iOS Runner 共用的广告信息通道。
  static const MethodChannel _channel = MethodChannel(
    'com.topread.novel/advertising_info',
  );

  /// 当前正在执行的 ATT 检查，用于合并用户快速重复点击。
  static Future<void>? _active_request;

  /// iOS 第二次及以后启动，且通知权限无需弹窗时调用。
  ///
  /// 只有 [AppTrackingAuthorizationStatus.not_determined] 会触发系统弹窗；
  /// authorized、denied 和 restricted 均直接结束，不会再次弹窗。
  static Future<void> request_on_ios_app_start() => _request_exclusive();

  /// 在第一次激励视频广告加载前检查 ATT。
  ///
  /// 只有 [AppTrackingAuthorizationStatus.not_determined] 会触发系统弹窗。
  /// authorized、denied 和 restricted 均直接结束，不会再次弹窗。
  static Future<void> request_before_rewarded_ad() => _request_exclusive();

  /// 合并启动和广告入口的并发检查，保证同一时间只执行一次 ATT 流程。
  static Future<void> _request_exclusive() {
    if (!isIOSApp) {
      return Future<void>.value();
    }

    final Future<void>? active_request = _active_request;
    if (active_request != null) {
      return active_request;
    }

    final Future<void> request = _request_if_needed();
    _active_request = request;
    return request.whenComplete(() {
      if (identical(_active_request, request)) {
        _active_request = null;
      }
    });
  }

  /// 读取 iOS 系统 ATT 状态，并仅对尚未决定的用户发起请求。
  static Future<void> _request_if_needed() async {
    try {
      final AppTrackingAuthorizationStatus current_status =
          await _get_authorization_status();
      logUtil(msg: 'ATT: 当前授权状态 ${current_status.name}');

      if (current_status != AppTrackingAuthorizationStatus.not_determined) {
        return;
      }

      await _wait_until_app_resumed();
      final String? value = await _channel.invokeMethod<String>(
        'requestTrackingAuthorization',
      );
      final AppTrackingAuthorizationStatus requested_status = _parse_status(
        value,
      );
      logUtil(msg: 'ATT: 系统授权请求结束 ${requested_status.name}');
    } on MissingPluginException catch (error) {
      logUtil(msg: 'ATT: 原生通道未注册 $error', type: 'e');
    } on PlatformException catch (error) {
      logUtil(msg: 'ATT: 原生授权请求失败 $error', type: 'e');
    } catch (error) {
      logUtil(msg: 'ATT: 授权流程异常 $error', type: 'e');
    }
  }

  /// 通过 iOS Runner 读取当前 ATT 授权状态。
  static Future<AppTrackingAuthorizationStatus>
  _get_authorization_status() async {
    final String? value = await _channel.invokeMethod<String>(
      'getTrackingAuthorizationStatus',
    );
    return _parse_status(value);
  }

  /// 将 iOS 返回的状态名称转换为 Dart 枚举。
  static AppTrackingAuthorizationStatus _parse_status(String? value) {
    switch (value) {
      case 'notDetermined':
        return AppTrackingAuthorizationStatus.not_determined;
      case 'restricted':
        return AppTrackingAuthorizationStatus.restricted;
      case 'denied':
        return AppTrackingAuthorizationStatus.denied;
      case 'authorized':
        return AppTrackingAuthorizationStatus.authorized;
      default:
        return AppTrackingAuthorizationStatus.unknown;
    }
  }

  /// ATT 系统弹窗只能在 App 处于前台活动状态时请求。
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
