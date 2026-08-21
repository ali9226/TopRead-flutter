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
}
