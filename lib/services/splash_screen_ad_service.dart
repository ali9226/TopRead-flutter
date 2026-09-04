// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:app/api/post_request.dart';
import 'package:app/models/ad_config.dart';
import 'package:app/util/ad_display_policy.dart';
import 'package:app/util/google_mobile_ads_util.dart';
import 'package:app/util/log_util.dart';
import 'package:app/util/storage_util/index.dart';

/// 开屏广告服务。
///
/// 负责请求 `ads/splash_screen_ads` 接口获取广告配置，
/// 缓存到本地，并在开屏期间加载和展示谷歌 App Open 广告。
class SplashScreenAdService extends GetxController {
  /// 日志前缀。
  static const String _log_prefix = '[SplashScreenAd]';

  /// 缓存键名。
  static const String _cache_key = 'splash_screen_ad_config';

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

  @override
  void onInit() {
    super.onInit();
    _fetch_ad_config();
  }

  @override
  void onClose() {
    _dispose_ad();
    super.onClose();
  }

  /// 请求广告配置。
  ///
  /// 优先从缓存读取，然后请求接口更新。
  Future<void> _fetch_ad_config() async {
    // 等待广告配置加载完成。
    final bool can_show_ads = await AdDisplayPolicy.wait_until_resolved();
    if (!can_show_ads) return;

    // 先从缓存读取。
    await _load_from_cache();

    // 然后请求接口更新。
    await _fetch_from_backend();
  }

  /// 从缓存加载广告配置。
  Future<void> _load_from_cache() async {
    try {
      final String? cached_json = await StorageUtil.getData(_cache_key);
      if (cached_json == null || cached_json.isEmpty) return;

      final Map<String, dynamic> json_map = Map<String, dynamic>.from(
        jsonDecode(cached_json) as Map,
      );
      _ad_config.value = AdConfig.fromJson(json_map);

      // 如果缓存中有配置，尝试加载广告。
      _try_load_ad();
    } catch (e) {
      logUtil(msg: '$_log_prefix 缓存加载失败: $e', type: 'w');
    }
  }

  /// 从接口请求广告配置。
  Future<void> _fetch_from_backend() async {
    try {
      final result = await postRequest<AdConfig>(
        path: 'ads/splash_screen_ads',
        showTips: false,
        fromJson: (Map<String, dynamic> json) => AdConfig.fromJson(json),
      );

      if (!result.status || result.content == null) return;

      _ad_config.value = result.content;

      // 缓存到本地。
      await _save_to_cache();

      // 尝试加载广告。
      _try_load_ad();
    } catch (e) {
      logUtil(msg: '$_log_prefix 接口请求异常: $e', type: 'e');
    }
  }

  /// 保存广告配置到缓存。
  Future<void> _save_to_cache() async {
    if (_ad_config.value == null) return;

    try {
      final String json_str = jsonEncode({
        'id': _ad_config.value!.id,
        'ads_id': _ad_config.value!.adsId,
        'show_number': _ad_config.value!.showNumber,
        'notification_number': _ad_config.value!.notificationNumber,
        'ads_type': _ad_config.value!.adsType,
        'advertisers': _ad_config.value!.advertisers,
        'weight': _ad_config.value!.weight,
        'ads_type_str': _ad_config.value!.adsTypeStr,
        'advertisers_str': _ad_config.value!.advertisersStr,
        'uuid': _ad_config.value!.uuid,
      });
      await StorageUtil.saveData(_cache_key, json_str);
    } catch (e) {
      logUtil(msg: '$_log_prefix 缓存保存失败: $e', type: 'w');
    }
  }

  /// 尝试加载广告。
  ///
  /// 只有谷歌类型广告（advertisers == 1）且 ads_id 非空时才加载。
  void _try_load_ad() {
    if (_ad_config.value == null) return;
    if (_ad_config.value!.advertisers != 1) return;
    if (_ad_config.value!.adsId.trim().isEmpty) return;

    _load_app_open_ad();
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
  Future<void> show_ad() async {
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
