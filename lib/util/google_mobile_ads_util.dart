import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:app/permission_request/admob_consent_permission_request.dart';
import 'package:app/util/ad_display_policy.dart';
import 'package:app/util/device/app_environment.dart';
import 'package:app/util/log_util.dart';

/// Google Mobile Ads 的全局初始化入口。
///
/// 激励广告、正文原生广告以及未来首页瀑布流广告都必须通过
/// [ensure_initialized] 启动 SDK。这里会先等待全局 UMP 门禁，并合并所有
/// 并发初始化请求。
class GoogleMobileAdsUtil {
  GoogleMobileAdsUtil._();

  static final GoogleMobileAdsUtil instance = GoogleMobileAdsUtil._();

  static const String _log_prefix = '[GoogleMobileAds]';

  /// Android Debug 设备 ID，确保开发期间不会将本机请求当作正式流量。
  static const String _android_debug_test_device_id =
      '97ECB298D9F6E72D1D8A2C524D4FED6C';

  Future<InitializationStatus>? _initialization;
  bool _is_debug_test_device_configured = false;

  bool get is_supported => isNativeMobileApp;

  /// 等待隐私许可并且仅初始化一次广告 SDK。
  ///
  /// 返回 false 时广告位必须保持隐藏，不得直接调用任何广告 load API。
  Future<bool> ensure_initialized() async {
    if (!is_supported || !AdDisplayPolicy.can_show_ads()) {
      _log('当前平台广告开关未开启，跳过 SDK 初始化', type: 'w');
      return false;
    }

    final bool can_request_ads =
        await AdMobConsentPermissionRequest.request_before_ad();
    if (!can_request_ads) {
      _log('UMP 未允许请求广告，跳过 SDK 初始化', type: 'w');
      return false;
    }
    if (!AdDisplayPolicy.can_show_ads()) {
      _log('UMP 完成后广告开关已关闭，跳过 SDK 初始化', type: 'w');
      return false;
    }

    try {
      await _configure_debug_test_device();
      _initialization ??= MobileAds.instance.initialize();
      final InitializationStatus status = await _initialization!;
      _log('SDK 初始化完成，适配器: ${status.adapterStatuses.keys.join(', ')}');
      return true;
    } catch (error, stack_trace) {
      _initialization = null;
      _log('SDK 初始化失败: $error\n$stack_trace', type: 'e');
      return false;
    }
  }

  Future<void> _configure_debug_test_device() async {
    if (!kDebugMode || !isAndroidApp || _is_debug_test_device_configured) {
      return;
    }

    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        testDeviceIds: const <String>[_android_debug_test_device_id],
      ),
    );
    _is_debug_test_device_configured = true;
    _log('Android Debug 测试设备注册完成');
  }

  void _log(String message, {String? type}) {
    logUtil(msg: '$_log_prefix $message', type: type);
  }
}
