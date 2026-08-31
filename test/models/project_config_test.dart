import 'package:app/models/project_config.dart';
import 'package:app/util/device/app_environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProjectConfig.is_enabled_for_environment', () {
    const List<AppEnvironment> all_environments = <AppEnvironment>[
      AppEnvironment.android,
      AppEnvironment.ios,
      AppEnvironment.desktopBrowser,
      AppEnvironment.androidBrowser,
      AppEnvironment.iosBrowser,
    ];

    test('关闭值在所有环境均关闭', () {
      for (final AppEnvironment environment in all_environments) {
        expect(
          ProjectConfig.is_enabled_for_environment(
            SwitchValue.off,
            environment,
          ),
          isFalse,
        );
      }
    });

    test('开启值在所有环境均开启', () {
      for (final AppEnvironment environment in all_environments) {
        expect(
          ProjectConfig.is_enabled_for_environment(SwitchValue.on, environment),
          isTrue,
        );
      }
    });

    test('仅安卓值只在 Android 原生应用开启', () {
      expect(
        ProjectConfig.is_enabled_for_environment(
          SwitchValue.android_only,
          AppEnvironment.android,
        ),
        isTrue,
      );
      expect(
        ProjectConfig.is_enabled_for_environment(
          SwitchValue.android_only,
          AppEnvironment.ios,
        ),
        isFalse,
      );
      expect(
        ProjectConfig.is_enabled_for_environment(
          SwitchValue.android_only,
          AppEnvironment.androidBrowser,
        ),
        isFalse,
      );
    });

    test('仅 iOS 值只在 iOS 原生应用开启', () {
      expect(
        ProjectConfig.is_enabled_for_environment(
          SwitchValue.ios_only,
          AppEnvironment.android,
        ),
        isFalse,
      );
      expect(
        ProjectConfig.is_enabled_for_environment(
          SwitchValue.ios_only,
          AppEnvironment.ios,
        ),
        isTrue,
      );
      expect(
        ProjectConfig.is_enabled_for_environment(
          SwitchValue.ios_only,
          AppEnvironment.iosBrowser,
        ),
        isFalse,
      );
    });

    test('仅网页值在所有浏览器环境开启且原生应用关闭', () {
      expect(
        ProjectConfig.is_enabled_for_environment(
          SwitchValue.web_only,
          AppEnvironment.android,
        ),
        isFalse,
      );
      expect(
        ProjectConfig.is_enabled_for_environment(
          SwitchValue.web_only,
          AppEnvironment.ios,
        ),
        isFalse,
      );
      expect(
        ProjectConfig.is_enabled_for_environment(
          SwitchValue.web_only,
          AppEnvironment.desktopBrowser,
        ),
        isTrue,
      );
      expect(
        ProjectConfig.is_enabled_for_environment(
          SwitchValue.web_only,
          AppEnvironment.androidBrowser,
        ),
        isTrue,
      );
      expect(
        ProjectConfig.is_enabled_for_environment(
          SwitchValue.web_only,
          AppEnvironment.iosBrowser,
        ),
        isTrue,
      );
    });
  });

  group('ProjectConfig 广告概率解析', () {
    test('字符串和数字概率均可解析', () {
      final ProjectConfig config = ProjectConfig.from_json(<String, dynamic>{
        'ads_short_story_show_interstitial_ads_probability': '35',
        'ads_short_story_video_ad_probability': 60.8,
        'read_ads_unlock_an_hour': '75',
        'read_ads_unlock_three_hour': 50.5,
        'read_ads_unlock_six_hour': '90',
      });

      expect(config.ads_short_story_show_interstitial_ads_probability, 35);
      expect(config.ads_short_story_video_ad_probability, 60);
      expect(config.read_ads_unlock_an_hour, 75);
      expect(config.read_ads_unlock_three_hour, 50);
      expect(config.read_ads_unlock_six_hour, 90);
    });

    test('越界概率会限制在 0～100', () {
      final ProjectConfig config = ProjectConfig.from_json(<String, dynamic>{
        'ads_read_show_interstitial_ads_probability': -20,
        'ads_short_story_show_interstitial_ads_probability': 120,
        'ads_read_video_ad_probability': -1,
        'ads_short_story_video_ad_probability': 101,
        'read_ads_unlock_an_hour': -5,
        'read_ads_unlock_three_hour': 150,
        'read_ads_unlock_six_hour': -10,
      });

      expect(config.ads_read_show_interstitial_ads_probability, 0);
      expect(config.ads_short_story_show_interstitial_ads_probability, 100);
      expect(config.ads_read_video_ad_probability, 0);
      expect(config.ads_short_story_video_ad_probability, 100);
      expect(config.read_ads_unlock_an_hour, 0);
      expect(config.read_ads_unlock_three_hour, 100);
      expect(config.read_ads_unlock_six_hour, 0);
    });
  });
}
