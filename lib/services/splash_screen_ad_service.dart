// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:app/config/ad_type_config.dart';
import 'package:app/models/ad_config.dart';
import 'package:app/stores/ad_config_store.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:app/services/ad_impression_reporter.dart';
import 'package:app/util/ad_display_policy.dart';
import 'package:app/util/google_mobile_ads_util.dart';
import 'package:app/util/log_util.dart';

/// 开屏广告服务。
///
/// 只读取应用首帧前恢复的 `redis/get.ads_ids` 本地缓存，
/// 并在开屏期间加载和展示谷歌 App Open 广告。
class SplashScreenAdService extends GetxController {
  /// 日志前缀。
  static const String _log_prefix = '[SplashScreenAd]';

  /// iOS 开屏广告音频输出控制通道。
  static const MethodChannel _ios_audio_channel = MethodChannel(
    'com.topread.novel/splash_ad_audio',
  );

  /// 当前广告配置。
  final Rx<AdConfig?> _ad_config = Rx<AdConfig?>(null);

  /// 广告是否已加载完成。
  final RxBool _is_ad_loaded = false.obs;

  /// 广告是否正在加载中。
  final RxBool _is_loading = false.obs;

  /// 广告是否正在展示中。
  bool _is_showing = false;

  /// App Open 广告实例。
  AppOpenAd? _app_open_ad;

  /// 开屏界面是否已经淡出。
  bool _is_splash_completed = false;

  /// 广告配置。
  AdConfig? get ad_config => _ad_config.value;

  /// 广告是否已加载完成（响应式）。
  RxBool get is_ad_loaded_rx => _is_ad_loaded;

  /// 广告是否已加载完成。
  bool get is_ad_loaded => _is_ad_loaded.value;

  /// 广告是否正在加载中。
  bool get is_loading => _is_loading.value;

  /// App Open 广告实例。
  AppOpenAd? get app_open_ad => _is_ad_loaded.value ? _app_open_ad : null;

  /// 设置开屏界面是否已经淡出。
  void set_splash_completed(bool completed) {
    _is_splash_completed = completed;
  }

  @override
  void onInit() {
    super.onInit();
    _load_cached_ad_config();
  }

  @override
  void onClose() {
    _dispose_ad();
    super.onClose();
  }

  /// 从统一广告仓库读取本次启动可用的开屏广告配置。
  ///
  /// 首次安装或缓存中没有广告配置时直接跳过。本次网络刷新不会再触发开屏
  /// 广告，避免等待 `redis/get` 影响启动体验。
  void _load_cached_ad_config() {
    if (!AdDisplayPolicy.can_show_ads()) return;
    if (!Get.isRegistered<AdConfigStore>()) return;
    _ad_config.value = Get.find<AdConfigStore>().select_google_config(
      AdPlacement.splash_screen,
    );
    if (_ad_config.value == null) return;

    // TODO 广告配置在首帧前确定，但广告 SDK 初始化延后到首帧完成后执行。
    // 这样既不会让本次 redis/get 网络响应补开开屏广告，也不会阻塞首帧渲染。
    WidgetsBinding.instance.addPostFrameCallback((_) => _try_load_ad());
  }

  /// 尝试加载广告。
  ///
  /// 只有谷歌类型广告（advertisers == 1）且 ads_id 非空时才加载。
  /// 根据 project_config 中的 splash_screen_ads 概率决定是否加载。
  void _try_load_ad() {
    if (_ad_config.value == null) return;
    if (_ad_config.value!.advertisers != 1) return;
    if (_ad_config.value!.adsId.trim().isEmpty) return;

    // 获取开屏广告展示概率。
    final int probability = _get_splash_screen_ads_probability();
    if (probability <= 0) return;

    // 根据概率决定是否加载广告。
    if (probability < 100) {
      final int random = Random().nextInt(100);
      if (random >= probability) return;
    }

    _load_app_open_ad();
  }

  /// 获取开屏广告展示概率。
  int _get_splash_screen_ads_probability() {
    if (!Get.isRegistered<ProjectConfigStore>()) return 0;
    return Get.find<ProjectConfigStore>().current.splash_screen_ads;
  }

  /// 加载 App Open 广告。
  Future<void> _load_app_open_ad() async {
    if (_is_loading.value) return;
    _is_loading.value = true;

    try {
      // 确保广告SDK已初始化。
      final bool is_initialized = await GoogleMobileAdsUtil.instance
          .ensure_initialized();
      if (!is_initialized) {
        _is_loading.value = false;
        return;
      }

      // 释放旧广告。
      _dispose_ad();

      // 在请求广告素材前将 SDK 设为静音。
      await _mute_ad_audio();

      // 加载 App Open 广告。
      await AppOpenAd.load(
        adUnitId: _ad_config.value!.adsId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (AppOpenAd ad) {
            _app_open_ad = ad;
            _is_ad_loaded.value = true;
            _is_loading.value = false;

            // 设置广告回调。
            _app_open_ad!.fullScreenContentCallback = FullScreenContentCallback(
              onAdImpression: (AppOpenAd ad) {
                final AdConfig? ad_config = _ad_config.value;
                if (ad_config == null) return;
                unawaited(
                  AdImpressionReporter.report(
                    ad_config: ad_config,
                    placement: AdPlacement.splash_screen,
                  ),
                );
              },
              onAdDismissedFullScreenContent: (AppOpenAd ad) {
                _dispose_ad();
              },
              onAdFailedToShowFullScreenContent: (AppOpenAd ad, AdError error) {
                logUtil(
                  msg: '$_log_prefix 广告展示失败: ${error.message}',
                  type: 'w',
                );
                _dispose_ad();
              },
            );
          },
          onAdFailedToLoad: (LoadAdError error) {
            logUtil(msg: '$_log_prefix 广告加载失败: ${error.message}', type: 'w');
            _is_ad_loaded.value = false;
            _is_loading.value = false;
          },
        ),
      );
    } catch (e) {
      logUtil(msg: '$_log_prefix 广告加载异常: $e', type: 'e');
      _is_loading.value = false;
    }
  }

  /// 展示 App Open 广告。
  ///
  /// 如果开屏界面已经淡出，则不展示广告。
  Future<void> show_ad() async {
    if (_is_splash_completed) return;
    final AppOpenAd? ad = _app_open_ad;
    if (ad == null || !_is_ad_loaded.value || _is_showing) return;

    _is_showing = true;
    try {
      // 必须等待静音设置生效后再展示，避免广告先于平台通道调用播放。
      await _mute_ad_audio();

      // iOS 26 起直接静音当前 App 的输出，覆盖不遵守 SDK 静音设置的素材。
      await _set_ios_audio_output_muted(true);

      // 等待期间广告可能已被释放或替换。
      if (!identical(_app_open_ad, ad) || !_is_ad_loaded.value) {
        _is_showing = false;
        return;
      }

      await ad.show();
    } catch (e) {
      logUtil(msg: '$_log_prefix 广告静音或展示异常: $e', type: 'e');
      _dispose_ad();
    }
  }

  /// 将谷歌广告 SDK 的声音关闭。
  Future<void> _mute_ad_audio() async {
    await MobileAds.instance.setAppMuted(true);
    await MobileAds.instance.setAppVolume(0.0);
  }

  /// 设置 iOS 当前 App 的音频输出静音状态。
  ///
  /// iOS 26 以下由原生层安全跳过，由 Google Mobile Ads SDK 处理静音。
  Future<void> _set_ios_audio_output_muted(bool muted) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;

    await _ios_audio_channel.invokeMethod<void>('setMuted', <String, bool>{
      'muted': muted,
    });
  }

  /// 释放广告资源。
  void _dispose_ad() {
    unawaited(_restore_ios_audio_output());
    _app_open_ad?.dispose();
    _app_open_ad = null;
    _is_ad_loaded.value = false;
    _is_showing = false;
  }

  /// 恢复开屏广告展示期间被静音的 iOS 应用音频输出。
  Future<void> _restore_ios_audio_output() async {
    try {
      await _set_ios_audio_output_muted(false);
    } catch (e) {
      logUtil(msg: '$_log_prefix iOS 音频输出恢复失败: $e', type: 'w');
    }
  }
}
