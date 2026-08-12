// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/models/ad_config.dart';
import 'package:app/services/masonry_ad_config_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(MasonryAdConfigService.reset_for_test);

  test('多个瀑布流并发获取配置时全局只请求一次', () async {
    int fetch_count = 0;
    final Completer<AdConfig?> completer = Completer<AdConfig?>();
    final AdConfig config = _build_config();
    MasonryAdConfigService.set_fetcher_for_test(() {
      fetch_count += 1;
      return completer.future;
    });

    final List<Future<AdConfig?>> requests = List<Future<AdConfig?>>.generate(
      6,
      (_) => MasonryAdConfigService.get_google_ad_config(),
    );

    expect(fetch_count, 1);
    completer.complete(config);

    final List<AdConfig?> results = await Future.wait(requests);
    expect(results, everyElement(same(config)));
    expect(fetch_count, 1);
  });

  test('非 Google 广告配置会被拦截并缓存空结果', () async {
    int fetch_count = 0;
    MasonryAdConfigService.set_fetcher_for_test(() async {
      fetch_count += 1;
      return _build_config(advertisers: 2);
    });

    expect(await MasonryAdConfigService.get_google_ad_config(), isNull);
    expect(await MasonryAdConfigService.get_google_ad_config(), isNull);
    expect(fetch_count, 1);
  });

  test('Google 广告单元 ID 为空时不会创建广告', () async {
    MasonryAdConfigService.set_fetcher_for_test(
      () async => _build_config(ads_id: '  '),
    );

    expect(await MasonryAdConfigService.get_google_ad_config(), isNull);
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
