import 'dart:async';

import 'package:app/util/log_util.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 激励视频广告调试逻辑。
class RewardedAdLogic {
  static const String _logPrefix = '[Debug][RewardedAd]';
  static const String _androidAdUnitId =
      'ca-app-pub-5028475830567696/3364483751';
  static const String _androidDebugTestDeviceId =
      '97ECB298D9F6E72D1D8A2C524D4FED6C';
  static const String _iosTestAdUnitId =
      'ca-app-pub-3940256099942544/1712485313';

  Future<InitializationStatus>? _initialization;
  bool _isDebugTestDeviceConfigured = false;

  String get _adUnitId => defaultTargetPlatform == TargetPlatform.android
      ? _androidAdUnitId
      : _iosTestAdUnitId;

  /// 初始化 SDK 并加载当前平台的激励广告。
  Future<RewardedAd?> loadAd() async {
    try {
      await _configureDebugTestDevice();

      if (_initialization == null) {
        _log('Google 移动广告 SDK 开始初始化');
        _initialization = MobileAds.instance.initialize();
      } else {
        _log('Google 移动广告 SDK 已有初始化任务，直接复用');
      }

      final InitializationStatus status = await _initialization!;
      _log(
        'Google 移动广告 SDK 初始化完成，'
        '适配器: ${status.adapterStatuses.keys.join(', ')}',
      );

      final Completer<RewardedAd?> completer = Completer<RewardedAd?>();
      _log('开始加载激励广告，adUnitId=$_adUnitId');
      if (defaultTargetPlatform == TargetPlatform.android) {
        _log(
          '当前使用 TopRead Android 真实广告单元，'
          '请确认设备展示“测试广告”标签',
        );
      } else {
        _log(
          '尚未提供 TopRead iOS AdMob ID，当前继续使用 '
          'Google iOS 示例广告单元',
          type: 'w',
        );
      }

      await RewardedAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            final ResponseInfo? info = ad.responseInfo;
            _log(
              '广告加载成功，responseId=${info?.responseId}, '
              'adapter=${info?.mediationAdapterClassName}',
            );
            if (!completer.isCompleted) {
              completer.complete(ad);
            }
          },
          onAdFailedToLoad: (LoadAdError error) {
            _log(
              '广告加载失败，code=${error.code}, '
              'domain=${error.domain}, message=${error.message}, '
              'responseInfo=${error.responseInfo}',
              type: 'e',
            );
            if (!completer.isCompleted) {
              completer.complete(null);
            }
          },
        ),
      );

      return completer.future;
    } catch (e, stackTrace) {
      _initialization = null;
      _log('初始化或加载广告异常: $e\n$stackTrace', type: 'e');
      return null;
    }
  }

  /// 只在 Android Debug 包内注册日志中由 Google SDK 生成的测试设备 ID。
  Future<void> _configureDebugTestDevice() async {
    if (!kDebugMode ||
        defaultTargetPlatform != TargetPlatform.android ||
        _isDebugTestDeviceConfigured) {
      return;
    }

    _log('Android Debug 测试设备开始注册');
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        testDeviceIds: const <String>[_androidDebugTestDeviceId],
      ),
    );
    _isDebugTestDeviceConfigured = true;
    _log(
      'Android Debug 测试设备注册完成，'
      'testDeviceId=$_androidDebugTestDeviceId',
    );
  }

  void _log(String message, {String? type}) {
    logUtil(msg: '$_logPrefix $message', type: type);
  }
}
