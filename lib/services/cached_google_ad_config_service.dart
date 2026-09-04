// ignore_for_file: non_constant_identifier_names

import 'package:get/get.dart';

import 'package:app/config/ad_type_config.dart';
import 'package:app/models/ad_config.dart';
import 'package:app/stores/ad_config_store.dart';
import 'package:app/util/ad_display_policy.dart';
import 'package:app/util/log_util.dart';

/// 测试时可替换的广告配置读取函数。
typedef CachedGoogleAdConfigFetcher = Future<AdConfig?> Function();

/// 非激励Google广告的统一缓存配置读取服务。
///
/// 负责广告开关校验、缓存读取、广告商校验和统一异常处理，具体广告位服务
/// 只需要提供业务场景及日志前缀，避免每个广告位重复实现相同流程。
class CachedGoogleAdConfigService {
  const CachedGoogleAdConfigService._();

  /// 读取并校验指定业务场景的Google AdMob广告配置。
  ///
  /// [placement] 用于从缓存中选择当前平台对应的固定广告类型。
  /// [log_prefix] 用于区分不同广告位产生的诊断日志。
  /// [fetcher] 仅供单元测试替换缓存读取行为。
  static Future<AdConfig?> load({
    required AdPlacement placement,
    required String log_prefix,
    CachedGoogleAdConfigFetcher? fetcher,
  }) async {
    if (!AdDisplayPolicy.can_show_ads()) {
      logUtil(msg: '$log_prefix 当前平台广告开关未开启，跳过配置读取');
      return null;
    }

    try {
      AdConfig? ad_config;
      if (fetcher != null) {
        ad_config = await fetcher();
      } else if (Get.isRegistered<AdConfigStore>()) {
        ad_config = Get.find<AdConfigStore>().select_google_config(placement);
      }
      if (!AdDisplayPolicy.can_show_ads()) return null;
      if (ad_config == null) {
        logUtil(msg: '$log_prefix 本地缓存没有可用配置', type: 'w');
        return null;
      }

      logUtil(
        msg:
            '$log_prefix 配置已加载: '
            'id=${ad_config.id}, '
            'advertisers=${ad_config.advertisers}, '
            'adsType=${ad_config.adsType}',
      );

      if (ad_config.advertisers != AdTypeConfig.google_advertiser ||
          ad_config.adsId.trim().isEmpty) {
        logUtil(
          msg:
              '$log_prefix 非Google广告或ads_id为空，跳过: '
              'advertisers=${ad_config.advertisers}',
          type: 'w',
        );
        return null;
      }

      return ad_config;
    } catch (error, stack_trace) {
      logUtil(msg: '$log_prefix 配置加载异常: $error\n$stack_trace', type: 'e');
      return null;
    }
  }
}
