// ignore_for_file: non_constant_identifier_names

import 'package:flutter/foundation.dart';

import 'package:app/api/post_request.dart';
import 'package:app/models/ad_config.dart';
import 'package:app/util/log_util.dart';

typedef MasonryAdConfigFetcher = Future<AdConfig?> Function();

/// 今日推荐瀑布流的全局广告配置服务。
///
/// 同一次 App 进程内只会请求一次
/// `ads/masonry_layout_show_ads`。首页多个 Tab、搜索页等处同时创建
/// 瀑布流时共享这一个配置 Future，但不共享 NativeAd 实例。
class MasonryAdConfigService {
  const MasonryAdConfigService._();

  static const String _log_prefix = '[MasonryAdConfig]';

  /// 本次 App 进程的唯一配置请求。
  ///
  /// 失败结果也会保留，避免页面反复创建时循环请求不会变化的
  /// 广告配置。下一次冷启动会自然获得新的进程级缓存。
  static Future<AdConfig?>? _session_config_request;

  static MasonryAdConfigFetcher _fetcher = _fetch_from_backend;

  /// 返回本次启动的 Google AdMob 瀑布流配置。
  ///
  /// 只接受 `advertisers == 1` 且 `ads_id` 非空的配置；其他广告商
  /// 由后续对应的 SDK 实现，不会误传给 Google Mobile Ads。
  static Future<AdConfig?> get_google_ad_config() {
    return _session_config_request ??= _load_and_validate_config();
  }

  static Future<AdConfig?> _load_and_validate_config() async {
    try {
      final AdConfig? ad_config = await _fetcher();
      if (ad_config == null) {
        logUtil(msg: '$_log_prefix 接口未返回可用配置', type: 'w');
        return null;
      }

      logUtil(
        msg:
            '$_log_prefix 配置已加载: '
            'id=${ad_config.id}, '
            'advertisers=${ad_config.advertisers}, '
            'adsType=${ad_config.adsType}, '
            'uuid=${ad_config.uuid}',
      );

      if (ad_config.advertisers != 1 || ad_config.adsId.trim().isEmpty) {
        logUtil(
          msg:
              '$_log_prefix 非 Google 广告或 ads_id 为空，跳过: '
              'advertisers=${ad_config.advertisers}',
          type: 'w',
        );
        return null;
      }

      return ad_config;
    } catch (error, stack_trace) {
      logUtil(msg: '$_log_prefix 配置加载异常: $error\n$stack_trace', type: 'e');
      return null;
    }
  }

  static Future<AdConfig?> _fetch_from_backend() async {
    final result = await postRequest<AdConfig>(
      path: 'ads/masonry_layout_show_ads',
      showTips: false,
      fromJson: (Map<String, dynamic> json) => AdConfig.fromJson(json),
    );

    if (!result.status || result.content == null) {
      logUtil(
        msg:
            '$_log_prefix 接口请求失败: '
            'status=${result.status}, message=${result.message}',
        type: 'w',
      );
      return null;
    }
    return result.content;
  }

  /// 替换配置请求器，仅供单元测试验证全局单次请求。
  @visibleForTesting
  static void set_fetcher_for_test(MasonryAdConfigFetcher fetcher) {
    _fetcher = fetcher;
    _session_config_request = null;
  }

  /// 清理进程级缓存，仅供单元测试隔离用例。
  @visibleForTesting
  static void reset_for_test() {
    _fetcher = _fetch_from_backend;
    _session_config_request = null;
  }
}
