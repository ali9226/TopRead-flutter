// ignore_for_file: non_constant_identifier_names

import 'package:flutter/foundation.dart';

import 'package:app/config/ad_type_config.dart';
import 'package:app/models/ad_config.dart';
import 'package:app/services/cached_google_ad_config_service.dart';

typedef ShortStoryTabAdConfigFetcher = Future<AdConfig?> Function();

/// 短篇小说列表的广告配置服务。
///
/// 每次加载更多数据时，按概率判断是否需要展示广告。
/// 如果需要，从 `redis/get.ads_ids` 本地缓存中按平台和权重选择配置。
class ShortStoryTabAdConfigService {
  const ShortStoryTabAdConfigService._();

  static const String _log_prefix = '[ShortStoryTabAdConfig]';

  static ShortStoryTabAdConfigFetcher? _fetcher_for_test;

  /// 返回当前广告槽位的 Google AdMob 配置。
  ///
  /// 只接受 `advertisers == 1` 且 `ads_id` 非空的配置。
  static Future<AdConfig?> get_google_ad_config() =>
      CachedGoogleAdConfigService.load(
        placement: AdPlacement.short_story_tab,
        log_prefix: _log_prefix,
        fetcher: _fetcher_for_test,
      );

  /// 替换配置请求器，仅供单元测试验证。
  @visibleForTesting
  static void set_fetcher_for_test(ShortStoryTabAdConfigFetcher fetcher) {
    _fetcher_for_test = fetcher;
  }

  /// 恢复默认请求器，仅供单元测试隔离用例。
  @visibleForTesting
  static void reset_for_test() {
    _fetcher_for_test = null;
  }
}
