// ignore_for_file: non_constant_identifier_names

import 'package:flutter_test/flutter_test.dart';

import 'package:app/config/ad_type_config.dart';
import 'package:app/models/ad_config.dart';
import 'package:app/stores/ad_config_store.dart';
import 'package:app/util/device/app_environment.dart';

void main() {
  group('AdConfigStore', () {
    test('按平台和广告场景选择固定 ads_type', () {
      final AdConfigStore store = AdConfigStore();
      store.save_configs(<AdConfig>[
        _config(id: 'android', ads_type: 19, ads_id: 'android-unit'),
        _config(id: 'ios', ads_type: 20, ads_id: 'ios-unit'),
      ]);

      expect(
        store
            .select_google_config(
              AdPlacement.splash_screen,
              environment: AppEnvironment.android,
            )
            ?.adsId,
        'android-unit',
      );
      expect(
        store
            .select_google_config(
              AdPlacement.splash_screen,
              environment: AppEnvironment.ios,
            )
            ?.adsId,
        'ios-unit',
      );
      expect(
        store.select_google_config(
          AdPlacement.splash_screen,
          environment: AppEnvironment.desktopBrowser,
        ),
        isNull,
      );
    });

    test('排除非 Google、空 ID 和非正权重配置', () {
      final AdConfigStore store = AdConfigStore();
      store.save_configs(<AdConfig>[
        _config(
          id: 'other-advertiser',
          ads_type: 7,
          ads_id: 'other-unit',
          advertisers: 2,
        ),
        _config(id: 'empty-id', ads_type: 7, ads_id: ''),
        _config(id: 'zero-weight', ads_type: 7, ads_id: 'zero', weight: 0),
      ]);

      expect(
        store.select_google_config(
          AdPlacement.masonry,
          environment: AppEnvironment.android,
        ),
        isNull,
      );
    });

    test('按 weight 区间选择同类型广告', () {
      final AdConfigStore store = AdConfigStore();
      store.save_configs(<AdConfig>[
        _config(id: 'light', ads_type: 17, ads_id: 'light-unit', weight: 20),
        _config(id: 'heavy', ads_type: 17, ads_id: 'heavy-unit', weight: 80),
      ]);

      expect(
        store
            .select_google_config(
              AdPlacement.short_story_tab,
              environment: AppEnvironment.android,
              random_value: 0.19,
            )
            ?.id,
        'light',
      );
      expect(
        store
            .select_google_config(
              AdPlacement.short_story_tab,
              environment: AppEnvironment.android,
              random_value: 0.20,
            )
            ?.id,
        'heavy',
      );
    });

    test('网络新列表完整覆盖旧缓存列表', () {
      final AdConfigStore store = AdConfigStore();
      store.save_configs(<AdConfig>[
        _config(id: 'old', ads_type: 19, ads_id: 'old-unit'),
      ]);
      store.save_configs(<AdConfig>[
        _config(id: 'new', ads_type: 19, ads_id: 'new-unit'),
      ]);

      expect(store.configs.map((AdConfig config) => config.id), <String>[
        'new',
      ]);
      expect(store.is_config_loaded.value, isTrue);
    });
  });
}

AdConfig _config({
  required String id,
  required int ads_type,
  required String ads_id,
  int advertisers = 1,
  int weight = 100,
}) {
  return AdConfig(
    id: id,
    adsId: ads_id,
    showNumber: 0,
    notificationNumber: 0,
    adsType: ads_type,
    advertisers: advertisers,
    weight: weight,
    adsTypeStr: '',
    advertisersStr: '',
    uuid: '',
  );
}
