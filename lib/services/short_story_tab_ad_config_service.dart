// ignore_for_file: non_constant_identifier_names

import 'package:flutter/foundation.dart';

import 'package:app/api/post_request.dart';
import 'package:app/models/ad_config.dart';
import 'package:app/util/ad_display_policy.dart';
import 'package:app/util/log_util.dart';

typedef ShortStoryTabAdConfigFetcher = Future<AdConfig?> Function();

/// 短篇小说列表的广告配置服务。
///
/// 每次加载更多数据时，按概率判断是否需要展示广告。
/// 如果需要，请求 `ads/short_story_tab_ads` 接口获取广告配置。
class ShortStoryTabAdConfigService {
  const ShortStoryTabAdConfigService._();

  static const String _log_prefix = '[ShortStoryTabAdConfig]';

  static ShortStoryTabAdConfigFetcher _fetcher = _fetch_from_backend;

  /// 返回当前广告槽位的 Google AdMob 配置。
  ///
  /// 只接受 `advertisers == 1` 且 `ads_id` 非空的配置。
  static Future<AdConfig?> get_google_ad_config() =>
      _load_and_validate_config();

  static Future<AdConfig?> _load_and_validate_config() async {
    if (!AdDisplayPolicy.can_show_ads()) {
      logUtil(msg: '$_log_prefix 当前平台广告开关未开启，跳过配置请求');
      return null;
    }
    try {
      final AdConfig? ad_config = await _fetcher();
      if (!AdDisplayPolicy.can_show_ads()) return null;
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
      path: 'ads/short_story_tab_ads',
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

  /// 替换配置请求器，仅供单元测试验证。
  @visibleForTesting
  static void set_fetcher_for_test(ShortStoryTabAdConfigFetcher fetcher) {
    _fetcher = fetcher;
  }

  /// 恢复默认请求器，仅供单元测试隔离用例。
  @visibleForTesting
  static void reset_for_test() {
    _fetcher = _fetch_from_backend;
  }
}
