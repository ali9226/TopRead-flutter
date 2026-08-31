// ignore_for_file: non_constant_identifier_names

import 'package:app/models/ad_config.dart';
import 'package:app/models/project_config.dart';
import 'package:app/services/masonry_ad_config_service.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
    Get.put<ProjectConfigStore>(
      ProjectConfigStore(),
    ).save_config(_build_project_config(ads_switch: SwitchValue.on));
  });

  tearDown(() {
    MasonryAdConfigService.reset_for_test();
    Get.reset();
  });

  test('每个广告槽位都独立获取配置', () async {
    int fetch_count = 0;
    final AdConfig config = _build_config();
    MasonryAdConfigService.set_fetcher_for_test(() async {
      fetch_count += 1;
      return config;
    });

    final List<Future<AdConfig?>> requests = List<Future<AdConfig?>>.generate(
      6,
      (_) => MasonryAdConfigService.get_google_ad_config(),
    );

    final List<AdConfig?> results = await Future.wait(requests);
    expect(results, everyElement(same(config)));
    expect(fetch_count, 6);
  });

  test('上一个槽位的无效配置不会污染下一个槽位', () async {
    int fetch_count = 0;
    MasonryAdConfigService.set_fetcher_for_test(() async {
      fetch_count += 1;
      return fetch_count == 1 ? _build_config(advertisers: 2) : _build_config();
    });

    expect(await MasonryAdConfigService.get_google_ad_config(), isNull);
    expect(await MasonryAdConfigService.get_google_ad_config(), isNotNull);
    expect(fetch_count, 2);
  });

  test('Google 广告单元 ID 为空时不会创建广告', () async {
    MasonryAdConfigService.set_fetcher_for_test(
      () async => _build_config(ads_id: '  '),
    );

    expect(await MasonryAdConfigService.get_google_ad_config(), isNull);
  });

  test('公共广告策略关闭时不请求后端配置', () async {
    int fetch_count = 0;
    Get.find<ProjectConfigStore>().save_config(
      _build_project_config(ads_switch: SwitchValue.off),
    );
    MasonryAdConfigService.set_fetcher_for_test(() async {
      fetch_count += 1;
      return _build_config();
    });

    expect(await MasonryAdConfigService.get_google_ad_config(), isNull);
    expect(fetch_count, 0);
  });
}

AdConfig _build_config({int advertisers = 1, String ads_id = 'native-unit'}) {
  return AdConfig(
    id: '98',
    adsId: ads_id,
    showNumber: 0,
    notificationNumber: 0,
    adsType: 4,
    advertisers: advertisers,
    weight: 1,
    adsTypeStr: '原生高级广告',
    advertisersStr: 'Google AdMob',
    uuid: 'masonry-config-uuid',
  );
}

ProjectConfig _build_project_config({required int ads_switch}) {
  return ProjectConfig(
    id: 1,
    ads_switch: ads_switch,
    authorized_login_switch: SwitchValue.on,
    comment_switch: SwitchValue.on,
    online_customer_service_switch: SwitchValue.on,
    rating_switch: SwitchValue.on,
    creator_switch: SwitchValue.on,
    share_switch: SwitchValue.on,
    contact_customer_service_switch: SwitchValue.on,
    famous_quote: '',
    app_review_status: 2,
    ads_read_show_interstitial_ads_probability: 100,
    ads_short_story_show_interstitial_ads_probability: 100,
    ads_read_video_ad_probability: 100,
    ads_short_story_video_ad_probability: 100,
    read_ads_unlock_an_hour: 100,
    read_ads_unlock_three_hour: 100,
    read_ads_unlock_six_hour: 100,
  );
}
