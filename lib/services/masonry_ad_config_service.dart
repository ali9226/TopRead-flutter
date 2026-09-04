// ignore_for_file: non_constant_identifier_names

import 'package:flutter/foundation.dart';

import 'package:app/config/ad_type_config.dart';
import 'package:app/models/ad_config.dart';
import 'package:app/services/cached_google_ad_config_service.dart';

typedef MasonryAdConfigFetcher = Future<AdConfig?> Function();

/// 推荐瀑布流的广告配置服务。
///
/// 每个新数据批次产生的广告槽位都从 `redis/get.ads_ids` 本地缓存中
/// 按平台和权重独立选择广告。页面恢复时由广告池复用已有 NativeAd。
class MasonryAdConfigService {
  const MasonryAdConfigService._();

  static const String _log_prefix = '[MasonryAdConfig]';

  static MasonryAdConfigFetcher? _fetcher_for_test;

  /// 返回当前广告槽位的 Google AdMob 瀑布流配置。
  ///
  /// 只接受 `advertisers == 1` 且 `ads_id` 非空的配置；其他广告商
  /// 由后续对应的 SDK 实现，不会误传给 Google Mobile Ads。
  static Future<AdConfig?> get_google_ad_config() =>
      CachedGoogleAdConfigService.load(
        placement: AdPlacement.masonry,
        log_prefix: _log_prefix,
        fetcher: _fetcher_for_test,
      );

  /// 替换配置读取器，仅供单元测试验证配置选择流程。
  @visibleForTesting
  static void set_fetcher_for_test(MasonryAdConfigFetcher fetcher) {
    _fetcher_for_test = fetcher;
  }

  /// 恢复默认请求器，仅供单元测试隔离用例。
  @visibleForTesting
  static void reset_for_test() {
    _fetcher_for_test = null;
  }
}
