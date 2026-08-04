import 'package:flutter/services.dart';

/// 调试页面使用的原生广告标识通道。
///
/// 注意：AdMob 测试设备 ID 由 Google Mobile Ads SDK 另行管理，
/// 这里返回的是 Android GAID 或 iOS IDFA，不能作为 testDeviceId。
class AdvertisingInfoChannel {
  static const MethodChannel _channel = MethodChannel(
    'com.topread.novel/advertising_info',
  );

  /// 获取 Android GAID 或 iOS IDFA。
  ///
  /// iOS 权限未决定时，[requestTrackingAuthorization] 为 true 会请求
  /// App Tracking Transparency 授权。用户未授权时返回 null。
  static Future<String?> getAdvertisingId({
    bool requestTrackingAuthorization = true,
  }) async {
    final String? value = await _channel.invokeMethod<String>(
      'getAdvertisingId',
      <String, Object?>{
        'requestTrackingAuthorization': requestTrackingAuthorization,
      },
    );
    if (value == null || value.isEmpty) return null;
    return value;
  }

  /// 当前是否限制广告跟踪。
  ///
  /// iOS 14+ 仅有 ATT 状态为 authorized 时返回 false；
  /// denied、restricted 和 notDetermined 都返回 true。
  static Future<bool?> get isLimitAdTrackingEnabled {
    return _channel.invokeMethod<bool>('isLimitAdTrackingEnabled');
  }
}
