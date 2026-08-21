// ignore_for_file: non_constant_identifier_names

import 'package:app/models/project_config.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:app/util/ad_display_policy.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.reset();
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    Get.put<ProjectConfigStore>(ProjectConfigStore());
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    Get.reset();
  });

  test('配置未解析时禁止请求广告但不提前免广告', () {
    expect(AdDisplayPolicy.is_config_resolved(), isFalse);
    expect(AdDisplayPolicy.can_show_ads(), isFalse);
    expect(AdDisplayPolicy.should_bypass_ads(), isFalse);
  });

  test('iOS 端遇到仅 Android 开启时直接免广告', () {
    Get.find<ProjectConfigStore>().save_config(
      _build_project_config(ads_switch: SwitchValue.android_only),
    );

    expect(AdDisplayPolicy.is_config_resolved(), isTrue);
    expect(AdDisplayPolicy.can_show_ads(), isFalse);
    expect(AdDisplayPolicy.should_bypass_ads(), isTrue);
  });

  test('iOS 端遇到仅 iOS 开启时允许广告', () {
    Get.find<ProjectConfigStore>().save_config(
      _build_project_config(ads_switch: SwitchValue.ios_only),
    );

    expect(AdDisplayPolicy.can_show_ads(), isTrue);
    expect(AdDisplayPolicy.should_bypass_ads(), isFalse);
  });

  test('启动阶段等待到配置后返回当前平台广告状态', () async {
    final Future<bool> result = AdDisplayPolicy.wait_until_resolved(
      timeout: const Duration(seconds: 1),
    );

    Get.find<ProjectConfigStore>().save_config(
      _build_project_config(ads_switch: SwitchValue.ios_only),
    );

    expect(await result, isTrue);
  });
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
  );
}
