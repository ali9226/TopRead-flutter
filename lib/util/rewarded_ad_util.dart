import 'dart:async';

import 'package:app/util/log_util.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 谷歌激励视频广告的最终展示结果。
enum GoogleRewardedAdResult {
  /// 用户完整观看并获得了奖励。
  rewarded,

  /// 用户在获得奖励前关闭了广告。
  dismissed,

  /// 广告加载失败。
  load_failed,

  /// 广告已加载，但全屏展示失败。
  show_failed,

  /// 当前运行平台不支持谷歌移动广告。
  unsupported,

  /// 已经有一个激励广告流程在执行。
  busy,

  /// 广告加载完成前，发起展示的页面已经失效。
  cancelled,
}

/// 统一处理谷歌激励视频广告的初始化、加载、展示和释放。
///
/// 整个应用共享同一个实例，避免重复初始化 SDK，也防止多个页面
/// 同时发起全屏广告。
class GoogleRewardedAdUtil {
  GoogleRewardedAdUtil._();

  /// 应用内共享的激励广告工具实例。
  static final GoogleRewardedAdUtil instance = GoogleRewardedAdUtil._();

  /// Android Debug 设备 ID，确保开发期间只请求测试广告。
  static const String _android_debug_test_device_id =
      '97ECB298D9F6E72D1D8A2C524D4FED6C';

  /// 日志前缀。
  static const String _log_prefix = '[GoogleRewardedAd]';

  /// SDK 初始化任务，并发请求共享同一个 Future。
  Future<InitializationStatus>? _initialization;

  /// Android Debug 测试设备是否已经注册。
  bool _is_debug_test_device_configured = false;

  /// 当前是否已有广告在加载或展示。
  bool _is_running = false;

  /// 当前平台是否支持 Google Mobile Ads。
  bool get is_supported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// 加载并展示一次谷歌激励视频广告。
  ///
  /// [adUnitId] 广告单元 ID，由后端接口返回。
  /// [user_id] 是服务器端验证使用的用户标识。
  /// [custom_data] 是服务器端验证使用的本次广告业务标识。
  /// [can_show] 在广告加载完成后执行，用于防止页面销毁后继续弹出广告。
  Future<GoogleRewardedAdResult> show_rewarded_ad({
    required String adUnitId,
    String? user_id,
    String? custom_data,
    bool Function()? can_show,
  }) async {
    if (!is_supported) {
      _log('当前平台不支持激励视频广告', type: 'w');
      return GoogleRewardedAdResult.unsupported;
    }
    if (_is_running) {
      _log('已有激励视频广告流程在执行', type: 'w');
      return GoogleRewardedAdResult.busy;
    }

    _is_running = true;
    RewardedAd? rewarded_ad;
    try {
      rewarded_ad = await _load_rewarded_ad(adUnitId);
      if (rewarded_ad == null) {
        return GoogleRewardedAdResult.load_failed;
      }

      if (can_show != null && !can_show()) {
        await rewarded_ad.dispose();
        _log('页面已失效，取消展示并释放广告', type: 'w');
        return GoogleRewardedAdResult.cancelled;
      }

      return await _show_loaded_ad(
        rewarded_ad,
        user_id: user_id,
        custom_data: custom_data,
      );
    } catch (error, stack_trace) {
      if (rewarded_ad != null) {
        await rewarded_ad.dispose();
      }
      _log('激励视频广告流程异常: $error\n$stack_trace', type: 'e');
      return GoogleRewardedAdResult.show_failed;
    } finally {
      _is_running = false;
    }
  }

  /// 初始化 SDK 并加载当前平台的激励广告。
  Future<RewardedAd?> _load_rewarded_ad(String adUnitId) async {
    try {
      await _configure_debug_test_device();

      _initialization ??= MobileAds.instance.initialize();
      final InitializationStatus status = await _initialization!;
      _log('SDK 初始化完成，适配器: ${status.adapterStatuses.keys.join(', ')}');

      final Completer<RewardedAd?> completer = Completer<RewardedAd?>();
      _log('开始加载激励广告，adUnitId=$adUnitId');
      await RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            final ResponseInfo? response_info = ad.responseInfo;
            _log(
              '广告加载成功，responseId=${response_info?.responseId}, '
              'adapter=${response_info?.mediationAdapterClassName}',
            );
            if (!completer.isCompleted) {
              completer.complete(ad);
            }
          },
          onAdFailedToLoad: (LoadAdError error) {
            _log(
              '广告加载失败，code=${error.code}, domain=${error.domain}, '
              'message=${error.message}, responseInfo=${error.responseInfo}',
              type: 'e',
            );
            if (!completer.isCompleted) {
              completer.complete(null);
            }
          },
        ),
      );

      return completer.future;
    } catch (error, stack_trace) {
      _initialization = null;
      _log('SDK 初始化或广告加载异常: $error\n$stack_trace', type: 'e');
      return null;
    }
  }

  /// 展示已经加载的广告，并等待全屏页关闭后返回最终结果。
  Future<GoogleRewardedAdResult> _show_loaded_ad(
    RewardedAd rewarded_ad, {
    String? user_id,
    String? custom_data,
  }) async {
    final Completer<GoogleRewardedAdResult> result_completer =
        Completer<GoogleRewardedAdResult>();
    bool has_earned_reward = false;
    RewardItem? earned_reward;
    bool is_disposed = false;

    Future<void> dispose_ad() async {
      if (is_disposed) return;
      is_disposed = true;
      await rewarded_ad.dispose();
    }

    void complete_result(GoogleRewardedAdResult result) {
      if (!result_completer.isCompleted) {
        result_completer.complete(result);
      }
    }

    final bool has_server_side_options =
        (user_id?.trim().isNotEmpty ?? false) ||
        (custom_data?.trim().isNotEmpty ?? false);
    if (has_server_side_options) {
      await rewarded_ad.setServerSideOptions(
        ServerSideVerificationOptions(
          userId: user_id?.trim(),
          customData: custom_data?.trim(),
        ),
      );
      _log('SSV 参数设置完成，userId=$user_id, customData=$custom_data');
    }

    rewarded_ad.onPaidEvent =
        (
          Ad ad,
          double value_micros,
          PrecisionType precision,
          String currency_code,
        ) {
          _log(
            '收入事件，valueMicros=$value_micros, '
            'precision=${precision.name}, currencyCode=$currency_code',
          );
        };

    rewarded_ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (Ad ad) {
        _log('广告已进入全屏展示');
      },
      onAdImpression: (Ad ad) {
        _log('广告曝光已记录');
      },
      onAdClicked: (Ad ad) {
        _log('用户点击了广告');
      },
      onAdWillDismissFullScreenContent: (Ad ad) {
        _log('广告即将关闭');
      },
      onAdFailedToShowFullScreenContent: (Ad ad, AdError error) {
        _log(
          '广告展示失败，code=${error.code}, domain=${error.domain}, '
          'message=${error.message}',
          type: 'e',
        );
        unawaited(dispose_ad());
        complete_result(GoogleRewardedAdResult.show_failed);
      },
      onAdDismissedFullScreenContent: (Ad ad) {
        _log(
          '广告已关闭，奖励状态: ${has_earned_reward ? '已获得' : '未获得'}'
          '${earned_reward == null ? '' : '，数量=${earned_reward!.amount}, '
                    '类型=${earned_reward!.type}'}',
        );
        unawaited(dispose_ad());
        complete_result(
          has_earned_reward
              ? GoogleRewardedAdResult.rewarded
              : GoogleRewardedAdResult.dismissed,
        );
      },
    );

    try {
      await rewarded_ad.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          has_earned_reward = true;
          earned_reward = reward;
          _log('用户获得奖励，amount=${reward.amount}, type=${reward.type}');
        },
      );
      return await result_completer.future;
    } catch (error, stack_trace) {
      await dispose_ad();
      _log('调用广告展示异常: $error\n$stack_trace', type: 'e');
      complete_result(GoogleRewardedAdResult.show_failed);
      return result_completer.future;
    }
  }

  /// 只在 Android Debug 包内注册谷歌 SDK 生成的测试设备 ID。
  Future<void> _configure_debug_test_device() async {
    if (!kDebugMode ||
        defaultTargetPlatform != TargetPlatform.android ||
        _is_debug_test_device_configured) {
      return;
    }

    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        testDeviceIds: const <String>[_android_debug_test_device_id],
      ),
    );
    _is_debug_test_device_configured = true;
    _log(
      'Android Debug 测试设备注册完成，'
      'testDeviceId=$_android_debug_test_device_id',
    );
  }

  /// 输出广告流程日志。
  void _log(String message, {String? type}) {
    logUtil(msg: '$_log_prefix $message', type: type);
  }
}
