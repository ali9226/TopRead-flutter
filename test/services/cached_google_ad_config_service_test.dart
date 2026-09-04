// ignore_for_file: non_constant_identifier_names

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:app/config/ad_type_config.dart';
import 'package:app/models/ad_config.dart';
import 'package:app/models/project_config.dart';
import 'package:app/services/cached_google_ad_config_service.dart';
import 'package:app/stores/project_config_store.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put(ProjectConfigStore()).save_config(const ProjectConfig.empty());
  });

  tearDown(Get.reset);

  test('广告开关开启时返回测试读取器提供的Google配置', () async {
    final AdConfig? result = await CachedGoogleAdConfigService.load(
      placement: AdPlacement.masonry,
      log_prefix: '[CachedAdConfigTest]',
      fetcher: () async => _config(advertisers: 1, ads_id: 'google-unit'),
    );

    expect(result?.adsId, 'google-unit');
  });

  test('统一拒绝非Google广告和空广告单元ID', () async {
    final AdConfig? other_advertiser = await CachedGoogleAdConfigService.load(
      placement: AdPlacement.masonry,
      log_prefix: '[CachedAdConfigTest]',
      fetcher: () async => _config(advertisers: 2, ads_id: 'other-unit'),
    );
    final AdConfig? empty_ad_id = await CachedGoogleAdConfigService.load(
      placement: AdPlacement.masonry,
      log_prefix: '[CachedAdConfigTest]',
      fetcher: () async => _config(advertisers: 1, ads_id: ''),
    );

    expect(other_advertiser, isNull);
    expect(empty_ad_id, isNull);
  });
}

/// 创建缓存广告配置测试数据。
AdConfig _config({required int advertisers, required String ads_id}) {
  return AdConfig(
    id: '1',
    adsId: ads_id,
    showNumber: 0,
    notificationNumber: 0,
    adsType: 7,
    advertisers: advertisers,
    weight: 100,
    adsTypeStr: '',
    advertisersStr: '',
    uuid: '',
  );
}
