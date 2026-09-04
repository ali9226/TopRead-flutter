// ignore_for_file: non_constant_identifier_names

import 'package:get/get.dart';

import 'package:app/config/ad_type_config.dart';
import 'package:app/models/ad_config.dart';
import 'package:app/util/device/app_environment.dart';
import 'package:app/util/select_weighted_ad_config.dart';

/// 广告配置仓库。
///
/// 保存 `redis/get.ads_ids` 返回的完整广告单元列表。广告位只读取该仓库，
/// 不再为了获取广告 ID 单独请求后端接口。
class AdConfigStore extends GetxController {
  /// 当前内存中的广告配置列表。
  final RxList<AdConfig> _configs = <AdConfig>[].obs;

  /// 是否已经从本地缓存或网络响应解析过广告列表。
  final RxBool is_config_loaded = false.obs;

  /// 只读广告配置快照。
  List<AdConfig> get configs => List<AdConfig>.unmodifiable(_configs);

  /// 用最新 `redis/get` 响应完整覆盖广告配置。
  void save_configs(List<AdConfig> configs) {
    _configs.assignAll(configs);
    is_config_loaded.value = true;
  }

  /// 按业务场景、平台、广告商与权重选择一个 Google AdMob 配置。
  ///
  /// [environment] 仅用于测试或显式查询其他平台；默认使用当前运行平台。
  /// [random_value] 仅用于测试固定权重随机结果，取值范围为 0（含）到 1（不含）。
  /// 无对应类型、无有效广告或权重全部小于等于 0 时返回 null。
  AdConfig? select_google_config(
    AdPlacement placement, {
    AppEnvironment? environment,
    double? random_value,
  }) {
    final int? ads_type = AdTypeConfig.resolve_type(
      placement,
      environment: environment,
    );
    if (ads_type == null) return null;

    final List<AdConfig> candidates = _configs
        .where(
          (AdConfig config) =>
              config.adsType == ads_type &&
              config.advertisers == AdTypeConfig.google_advertiser &&
              config.adsId.trim().isNotEmpty &&
              config.weight > 0,
        )
        .toList(growable: false);
    if (candidates.isEmpty) return null;

    return select_weighted_ad_config(candidates, random_value: random_value);
  }
}
