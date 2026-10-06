import 'package:flutter/services.dart';

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

/// iOS ATT 权限状态读取器与请求器。
///
/// 正常流程：ATT 系统弹窗由 UMP 的 IDFA 铺垫消息触发。
/// 兜底流程：UMP 完成后若 ATT 状态仍为 notDetermined，则由本类直接请求。
class AppTrackingTransparencyPermissionRequest {
  const AppTrackingTransparencyPermissionRequest._();

  /// Flutter 与 iOS Runner 共用的广告信息通道。
  static const MethodChannel _channel = MethodChannel(
    'com.topread.novel/advertising_info',
  );

  /// 读取 iOS 系统 ATT 状态，不展示任何权限弹窗。
  static Future<AppTrackingAuthorizationStatus>
  get_authorization_status() async {
    if (!isIOSApp) return AppTrackingAuthorizationStatus.unknown;

    try {
      final String? value = await _channel.invokeMethod<String>(
        'getTrackingAuthorizationStatus',
      );
      final AppTrackingAuthorizationStatus status = _parse_status(value);
      logUtil(msg: 'ATT: 当前授权状态 ${status.name}');
      return status;
    } on MissingPluginException catch (error) {
      logUtil(msg: 'ATT: 原生通道未注册 $error', type: 'e');
    } on PlatformException catch (error) {
      logUtil(msg: 'ATT: 原生状态读取失败 $error', type: 'e');
    } catch (error) {
      logUtil(msg: 'ATT: 状态读取异常 $error', type: 'e');
    }
    return AppTrackingAuthorizationStatus.unknown;
  }

  /// 直接调用 iOS ATT 系统弹窗，返回授权后的状态。
  ///
  /// 仅在 UMP 未触发 ATT 时作为兜底调用；iOS 外平台直接返回 unknown。
  static Future<AppTrackingAuthorizationStatus>
  request_tracking_authorization() async {
    if (!isIOSApp) return AppTrackingAuthorizationStatus.unknown;

    try {
      final String? value = await _channel.invokeMethod<String>(
        'requestTrackingAuthorization',
      );
      final AppTrackingAuthorizationStatus status = _parse_status(value);
      logUtil(msg: 'ATT: 兜底请求授权后状态 ${status.name}');
      return status;
    } on MissingPluginException catch (error) {
      logUtil(msg: 'ATT: 原生通道未注册 $error', type: 'e');
    } on PlatformException catch (error) {
      logUtil(msg: 'ATT: 兜底请求授权失败 $error', type: 'e');
    } catch (error) {
      logUtil(msg: 'ATT: 兜底请求授权异常 $error', type: 'e');
    }
    return AppTrackingAuthorizationStatus.unknown;
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
}
