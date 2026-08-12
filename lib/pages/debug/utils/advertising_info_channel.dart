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
  /// iOS 未通过 UMP/ATT 授权时返回 null。调试页不会主动弹出 ATT，
  /// 避免跳过 AdMob IDFA 铺垫消息。
  static Future<String?> getAdvertisingId() async {
    final String? value = await _channel.invokeMethod<String>(
      'getAdvertisingId',
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
