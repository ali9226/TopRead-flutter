// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:app/components/splash_screen/style.dart';
import 'package:app/config/ad_type_config.dart';
import 'package:app/models/ad_config.dart';
import 'package:app/stores/ad_config_store.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:app/services/ad_impression_reporter.dart';
import 'package:app/util/ad_display_policy.dart';
import 'package:app/util/full_screen_ad_guard.dart';
import 'package:app/util/google_mobile_ads_util.dart';
import 'package:app/util/log_util.dart';
import 'package:app/util/percentage_probability.dart';
import 'package:app/util/rewarded_ad_util.dart';

/// 冷启动及从后台返回前台时的开屏广告服务。
///
/// 冷启动只使用首帧前恢复的配置；回到前台时重新读取内存中的最新配置。
/// 每次有效进入前台只进行一次概率判断，广告自身的生命周期变化不触发重播。
class SplashScreenAdService extends GetxController with WidgetsBindingObserver {
  /// 日志前缀。
  static const String _log_prefix = '[SplashScreenAd]';

  /// iOS 开屏广告音频输出控制通道。
  static const MethodChannel _ios_audio_channel = MethodChannel(
    'com.topread.novel/splash_ad_audio',
  );

  /// 当前这一次广告请求选中的配置。
  final Rx<AdConfig?> _ad_config = Rx<AdConfig?>(null);

  /// 广告加载完成、加载中及曝光状态，供冷启动开屏组件监听。
  final RxBool _is_ad_loaded = false.obs;
  final RxBool _is_loading = false.obs;
  final RxBool _is_ad_impression = false.obs;

  /// 是否正在准备展示，包含等待静音平台调用的阶段。
  bool _is_showing = false;

  /// 是否已向 SDK 发起全屏展示，之后的后台事件可能来自广告自身。
  bool _has_presented = false;

  /// 当前加载完成的广告实例。
  AppOpenAd? _app_open_ad;

  /// 冷启动开屏图片是否已经淡出。
  bool _is_splash_completed = false;

  /// 当前请求是否来自后台恢复，不受冷启动图片完成状态限制。
  bool _is_resume_request = false;

  /// 是否已经进入真正的后台，以及此次返回是否允许触发开屏。
  bool _is_backgrounded = false;
  bool _show_on_resume = false;

  /// 最近的生命周期状态；仅 resumed 状态允许调用全屏展示。
  AppLifecycleState? _lifecycle_state;

  /// 请求代次，取消后的 SDK 回调不能覆盖下一次请求。
  int _request_id = 0;

  /// 服务关闭后禁止首帧回调和异步加载继续执行。
  bool _is_disposed = false;

  /// 回前台的展示窗口，避免慢请求在用户继续阅读后突然弹出。
  Timer? _resume_timeout;

  /// 当前展示是否申请过 iOS 应用静音。
  bool _ios_audio_muted = false;

  /// 串行执行 iOS 静音与恢复，避免旧广告的恢复覆盖新广告的静音。
  Future<void> _ios_audio_operation = Future<void>.value();

  /// 当前广告配置。
  AdConfig? get ad_config => _ad_config.value;

  /// 广告加载状态及其响应式版本。
  RxBool get is_ad_loaded_rx => _is_ad_loaded;
  bool get is_ad_loaded => _is_ad_loaded.value;
  bool get is_loading => _is_loading.value;

  /// 仅暴露已加载完成的广告实例。
  AppOpenAd? get app_open_ad => _is_ad_loaded.value ? _app_open_ad : null;

  /// 广告曝光状态，用于通知冷启动开屏图片淡出。
  RxBool get is_ad_impression_rx => _is_ad_impression;

  /// 标记冷启动图片完成，并取消超过开屏窗口的未展示请求。
  void set_splash_completed(bool completed) {
    _is_splash_completed = completed;
    if (completed && !_is_resume_request && !_has_presented) {
      _cancel_request();
    }
  }

  @override
  void onInit() {
    super.onInit();
    _lifecycle_state = WidgetsBinding.instance.lifecycleState;
    WidgetsBinding.instance.addObserver(this);
    final AdConfig? config = _select_ad_config();
    _ad_config.value = config;
    if (config == null) return;

    // 首帧前确定冷启动配置，首帧后才初始化 SDK，不等待网络刷新。
    WidgetsBinding.instance.addPostFrameCallback((_) => _try_load_ad(config));
  }

  @override
  void onClose() {
    _is_disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _cancel_request();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_is_disposed) return;
    _lifecycle_state = state;
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      if (_is_backgrounded) return;
      _is_backgrounded = true;
      // 在后台事件发生时记录原因，不能等广告关闭后才判断是否由广告触发。
      _show_on_resume =
          !_has_presented && !GoogleRewardedAdUtil.instance.is_running;
      if (!_has_presented) _cancel_request();
      return;
    }
    if (state == AppLifecycleState.detached) {
      _is_backgrounded = false;
      _show_on_resume = false;
      _cancel_request();
      return;
    }
    if (state != AppLifecycleState.resumed) return;

    final bool should_request = _is_backgrounded && _show_on_resume;
    _is_backgrounded = false;
    _show_on_resume = false;
    if (should_request && _is_splash_completed) {
      _try_load_ad(_select_ad_config(), is_resume: true);
    } else if (_is_ad_loaded.value) {
      // 权限弹窗等只有 inactive 的恢复不重新抽取概率或加载广告。
      unawaited(show_ad());
    }
  }

  /// 按当前平台和广告开关，从统一仓库选择有效的广告 ID。
  AdConfig? _select_ad_config() {
    if (!AdDisplayPolicy.can_show_ads()) return null;
    if (!Get.isRegistered<AdConfigStore>()) return null;
    return Get.find<AdConfigStore>().select_google_config(
      AdPlacement.splash_screen,
    );
  }

  /// 使用 [config] 发起一次请求；[is_resume] 表示来自后台恢复。
  void _try_load_ad(AdConfig? config, {bool is_resume = false}) {
    if (_is_disposed || _is_backgrounded || _is_showing || is_loading) return;
    if (!is_resume && _is_splash_completed) return;
    if (GoogleRewardedAdUtil.instance.is_running) return;
    if (!AdDisplayPolicy.can_show_ads() || config == null) return;
    if (!PercentageProbability.is_hit(_get_splash_screen_ads_probability())) {
      return;
    }

    _cancel_request();
    _ad_config.value = config;
    _is_resume_request = is_resume;
    _is_ad_impression.value = false;
    _is_loading.value = true;
    final int request_id = _request_id;
    if (is_resume) {
      _resume_timeout = Timer(
        Duration(milliseconds: SplashScreenStyle.display_duration_ms),
        () {
          if (request_id == _request_id && !_has_presented) _cancel_request();
        },
      );
    }
    unawaited(_load_app_open_ad(request_id, config));
  }

  /// 当前后台配置中的开屏展示概率，缺少配置时禁用。
  int _get_splash_screen_ads_probability() {
    if (!Get.isRegistered<ProjectConfigStore>()) return 0;
    return Get.find<ProjectConfigStore>().current.splash_screen_ads;
  }

  /// 检查请求是否仍有效，不重复进行概率抽样。
  ///
  /// 每个异步边界重新检查开关、广告 ID 和全屏占用，防止旧配置继续展示。
  bool _can_continue_request(int request_id, AdConfig config) {
    if (_is_disposed || request_id != _request_id || _is_backgrounded) {
      return false;
    }
    if (!_is_resume_request && _is_splash_completed) return false;
    if (!AdDisplayPolicy.can_show_ads()) return false;
    if (_get_splash_screen_ads_probability() <= 0) return false;
    if (GoogleRewardedAdUtil.instance.is_running) return false;
    if (!Get.isRegistered<AdConfigStore>()) return false;
    return Get.find<AdConfigStore>().configs.any(
      (AdConfig current) =>
          current.id == config.id &&
          current.adsId == config.adsId &&
          current.adsType == config.adsType &&
          current.advertisers == AdTypeConfig.google_advertiser &&
          current.adsId.trim().isNotEmpty &&
          current.weight > 0,
    );
  }

  /// 检查 [request_id] 对应的请求，失效时只取消自身，保留后来的请求。
  bool _validate_request(int request_id, AdConfig config) {
    if (_can_continue_request(request_id, config)) return true;
    if (request_id == _request_id) _cancel_request();
    return false;
  }

  /// 加载广告，并将所有 SDK 回调限定到本次请求和配置。
  Future<void> _load_app_open_ad(int request_id, AdConfig config) async {
    try {
      final bool is_initialized = await GoogleMobileAdsUtil.instance
          .ensure_initialized();
      if (!_validate_request(request_id, config)) return;
      if (!is_initialized) {
        _cancel_request();
        return;
      }
      await _mute_ad_audio();
      if (!_validate_request(request_id, config)) return;

      await AppOpenAd.load(
        adUnitId: config.adsId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (AppOpenAd ad) {
            if (!_validate_request(request_id, config)) {
              unawaited(ad.dispose());
              return;
            }
            _app_open_ad = ad;
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdImpression: (AppOpenAd ad) {
                if (!identical(_app_open_ad, ad) || _is_ad_impression.value) {
                  return;
                }
                _is_ad_impression.value = true;
                unawaited(
                  AdImpressionReporter.report(
                    ad_config: config,
                    placement: AdPlacement.splash_screen,
                  ),
                );
              },
              onAdDismissedFullScreenContent: (AppOpenAd ad) {
                if (identical(_app_open_ad, ad)) _cancel_request();
              },
              onAdFailedToShowFullScreenContent: (AppOpenAd ad, AdError error) {
                logUtil(
                  msg: '$_log_prefix 广告展示失败: ${error.message}',
                  type: 'w',
                );
                if (identical(_app_open_ad, ad)) _cancel_request();
              },
            );
            _is_loading.value = false;
            _is_ad_loaded.value = true;
            // 冷启动由图片组件触发展示，后台恢复不依赖已销毁的图片组件。
            if (_is_resume_request) unawaited(show_ad());
          },
          onAdFailedToLoad: (LoadAdError error) {
            if (request_id != _request_id) return;
            logUtil(msg: '$_log_prefix 广告加载失败: ${error.message}', type: 'w');
            _cancel_request();
          },
        ),
      );
    } catch (error) {
      if (request_id != _request_id) return;
      logUtil(msg: '$_log_prefix 广告加载异常: $error', type: 'e');
      _cancel_request();
    }
  }

  /// 在前台展示有效广告，异步静音期间取消的请求不得继续弹出。
  Future<void> show_ad() async {
    final AppOpenAd? ad = _app_open_ad;
    final AdConfig? config = _ad_config.value;
    if (ad == null || config == null || !_is_ad_loaded.value || _is_showing) {
      return;
    }
    final int request_id = _request_id;
    if (!_validate_request(request_id, config)) return;
    if (_lifecycle_state != AppLifecycleState.resumed) return;
    if (!FullScreenAdGuard.try_acquire(this)) {
      _cancel_request();
      return;
    }

    _is_showing = true;
    try {
      await _mute_ad_audio();
      if (!_validate_request(request_id, config)) return;

      // 先记录静音所有权，切后台时即使平台调用未返回也能排队恢复。
      _ios_audio_muted = true;
      await _set_ios_audio_output_muted(true);
      if (!_validate_request(request_id, config)) return;
      if (_lifecycle_state != AppLifecycleState.resumed) {
        _cancel_request();
        return;
      }
      _resume_timeout?.cancel();
      _resume_timeout = null;
      _has_presented = true;
      await ad.show();
    } catch (error) {
      if (request_id != _request_id) return;
      logUtil(msg: '$_log_prefix 广告静音或展示异常: $error', type: 'e');
      _cancel_request();
    }
  }

  /// 将谷歌广告 SDK 的声音关闭。
  Future<void> _mute_ad_audio() async {
    await MobileAds.instance.setAppMuted(true);
    await MobileAds.instance.setAppVolume(0.0);
  }

  /// 串行设置 iOS 应用输出静音；iOS 26 以下由原生层安全跳过。
  Future<void> _set_ios_audio_output_muted(bool muted) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    final Future<void> operation = _ios_audio_operation.then(
      (_) => _ios_audio_channel.invokeMethod<void>('setMuted', <String, bool>{
        'muted': muted,
      }),
    );
    // 保留可继续执行的队列，单次失败仍由当前调用方处理。
    _ios_audio_operation = operation.catchError((Object _) {});
    await operation;
  }

  /// 作废当前请求并释放已加载广告，迟到回调只能释放其自身实例。
  void _cancel_request() {
    FullScreenAdGuard.release(this);
    _request_id++;
    _resume_timeout?.cancel();
    _resume_timeout = null;
    _is_loading.value = false;
    _is_resume_request = false;
    final AppOpenAd? ad = _app_open_ad;
    _app_open_ad = null;
    _is_ad_loaded.value = false;
    _is_showing = false;
    _has_presented = false;
    if (ad != null) unawaited(ad.dispose());
    if (_ios_audio_muted) {
      _ios_audio_muted = false;
      unawaited(_restore_ios_audio_output());
    }
  }

  /// 恢复本次开屏展示期间申请的 iOS 应用音频输出。
  Future<void> _restore_ios_audio_output() async {
    try {
      await _set_ios_audio_output_muted(false);
    } catch (error) {
      logUtil(msg: '$_log_prefix iOS 音频输出恢复失败: $error', type: 'w');
    }
  }
}
