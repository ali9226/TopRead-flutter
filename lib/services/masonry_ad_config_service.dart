// ignore_for_file: non_constant_identifier_names

import 'package:flutter/foundation.dart';

import 'package:get/get.dart';

import 'package:app/config/ad_type_config.dart';
import 'package:app/models/ad_config.dart';
import 'package:app/stores/ad_config_store.dart';
import 'package:app/util/ad_display_policy.dart';
import 'package:app/util/log_util.dart';

typedef MasonryAdConfigFetcher = Future<AdConfig?> Function();

/// 推荐瀑布流的广告配置服务。
///
/// 每个新数据批次产生的广告槽位都从 `redis/get.ads_ids` 本地缓存中
/// 按平台和权重独立选择广告。页面恢复时由广告池复用已有 NativeAd。
class MasonryAdConfigService {
  const MasonryAdConfigService._();

  static const String _log_prefix = '[MasonryAdConfig]';

  static MasonryAdConfigFetcher _fetcher = _fetch_from_cache;

  /// 返回当前广告槽位的 Google AdMob 瀑布流配置。
  ///
  /// 只接受 `advertisers == 1` 且 `ads_id` 非空的配置；其他广告商
  /// 由后续对应的 SDK 实现，不会误传给 Google Mobile Ads。
  static Future<AdConfig?> get_google_ad_config() =>
      _load_and_validate_config();

  static Future<AdConfig?> _load_and_validate_config() async {
    if (!AdDisplayPolicy.can_show_ads()) {
      logUtil(msg: '$_log_prefix 当前平台广告开关未开启，跳过配置读取');
      return null;
    }
    try {
      final AdConfig? ad_config = await _fetcher();
      if (!AdDisplayPolicy.can_show_ads()) return null;
      if (ad_config == null) {
        logUtil(msg: '$_log_prefix 本地缓存没有可用配置', type: 'w');
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

  static Future<AdConfig?> _fetch_from_cache() async {
    if (!Get.isRegistered<AdConfigStore>()) return null;
    return Get.find<AdConfigStore>().select_google_config(AdPlacement.masonry);
  }

  /// 替换配置读取器，仅供单元测试验证配置选择流程。
  @visibleForTesting
  static void set_fetcher_for_test(MasonryAdConfigFetcher fetcher) {
    _fetcher = fetcher;
  }

  /// 恢复默认请求器，仅供单元测试隔离用例。
  @visibleForTesting
  static void reset_for_test() {
    _fetcher = _fetch_from_cache;
  }
}
