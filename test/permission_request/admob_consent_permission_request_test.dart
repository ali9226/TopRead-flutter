import 'dart:async';

import 'package:app/permission_request/admob_consent_permission_request.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mobile_ads/src/ump/user_messaging_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel advertising_info_channel = MethodChannel(
    'com.topread.novel/advertising_info',
  );

  late ConsentInformation original_consent_information;
  late UserMessagingChannel original_user_messaging_channel;
  late _FakeConsentInformation fake_consent_information;
  late _FakeUserMessagingChannel fake_user_messaging_channel;

  setUpAll(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    original_consent_information = ConsentInformation.instance;
    original_user_messaging_channel = UserMessagingChannel.instance;
  });

  setUp(() {
    AdMobConsentPermissionRequest.reset_for_test();
    fake_consent_information = _FakeConsentInformation();
    fake_user_messaging_channel = _FakeUserMessagingChannel();
    ConsentInformation.instance = fake_consent_information;
    UserMessagingChannel.instance = fake_user_messaging_channel;
  });

  tearDown(() {
    AdMobConsentPermissionRequest.reset_for_test();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(advertising_info_channel, null);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDownAll(() {
    ConsentInformation.instance = original_consent_information;
    UserMessagingChannel.instance = original_user_messaging_channel;
    debugDefaultTargetPlatformOverride = null;
  });

  test('启动和多个广告位并发请求时只执行一次 UMP 流程', () async {
    // 模拟首页瀑布流广告在根组件首帧回调之前先进入 initState。
    final List<Future<bool>> ad_requests = <Future<bool>>[
      AdMobConsentPermissionRequest.request_before_ad(),
      AdMobConsentPermissionRequest.request_before_ad(),
      AdMobConsentPermissionRequest.request_before_ad(),
    ];
    await Future<void>.delayed(Duration.zero);
    expect(fake_user_messaging_channel.required_form_count, 0);

    final Future<bool> startup_request =
        AdMobConsentPermissionRequest.initialize_on_app_start();

    final List<bool> results = await Future.wait(<Future<bool>>[
      ...ad_requests,
      startup_request,
    ]);
    final bool later_ad =
        await AdMobConsentPermissionRequest.request_before_ad();

    expect(results, everyElement(isTrue));
    expect(later_ad, isTrue);
    expect(fake_consent_information.update_request_count, 1);
    expect(fake_consent_information.can_request_ads_count, 1);
    expect(fake_user_messaging_channel.required_form_count, 1);
  });

  test('UMP 状态为无需同意且没有实际弹窗时，允许启动流程继续检查通知权限', () async {
    fake_consent_information.consent_status = ConsentStatus.notRequired;

    final AdMobStartupPrivacyResult result =
        await AdMobConsentPermissionRequest.initialize_on_app_start_with_result();

    expect(result.can_request_ads, isTrue);
    expect(result.did_update_consent_information, isTrue);
    expect(result.did_present_privacy_prompt, isFalse);
    expect(result.can_continue_to_notification_permission, isTrue);
  });

  test('UMP 法规表单实际完成后，本次启动不再继续弹通知权限', () async {
    fake_consent_information
      ..consent_status = ConsentStatus.required
      ..consent_status_after_form = ConsentStatus.obtained;
    fake_user_messaging_channel.on_required_form_closed = () {
      fake_consent_information.consent_status =
          fake_consent_information.consent_status_after_form;
    };

    final AdMobStartupPrivacyResult result =
        await AdMobConsentPermissionRequest.initialize_on_app_start_with_result();

    expect(result.did_present_privacy_prompt, isTrue);
    expect(result.can_continue_to_notification_permission, isFalse);
  });

  test('UMP 表单加载失败且没有实际权限界面时，仍可继续检查通知权限', () async {
    fake_consent_information.consent_status = ConsentStatus.required;
    fake_user_messaging_channel.required_form_error = FormError(
      errorCode: 2,
      message: 'test form load failure',
    );

    final AdMobStartupPrivacyResult result =
        await AdMobConsentPermissionRequest.initialize_on_app_start_with_result();

    expect(result.did_present_privacy_prompt, isFalse);
    expect(result.can_continue_to_notification_permission, isTrue);
  });

  test('日本等非欧盟地区的 iOS 首次 ATT 完成后，本次启动不再弹通知权限', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    fake_consent_information.consent_status = ConsentStatus.notRequired;
    final List<String> att_statuses = <String>['notDetermined', 'denied'];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(advertising_info_channel, (MethodCall call) {
          if (call.method == 'getTrackingAuthorizationStatus') {
            return Future<String>.value(att_statuses.removeAt(0));
          }
          return Future<Object?>.value(null);
        });

    final AdMobStartupPrivacyResult result =
        await AdMobConsentPermissionRequest.initialize_on_app_start_with_result();

    expect(result.did_present_privacy_prompt, isTrue);
    expect(result.can_continue_to_notification_permission, isFalse);
  });

  test('UMP 返回未知状态但没有权限界面时，启动流程仍可继续检查通知权限', () async {
    fake_consent_information.consent_status = ConsentStatus.unknown;

    final AdMobStartupPrivacyResult result =
        await AdMobConsentPermissionRequest.initialize_on_app_start_with_result();

    expect(result.did_update_consent_information, isTrue);
    expect(result.did_present_privacy_prompt, isFalse);
    expect(result.can_continue_to_notification_permission, isTrue);
  });

  test('隐私选项入口复用启动 UMP 结果，不会重复展示必要表单', () async {
    await AdMobConsentPermissionRequest.initialize_on_app_start();

    final bool is_required =
        await AdMobConsentPermissionRequest.is_privacy_options_required();

    expect(is_required, isTrue);
    expect(fake_consent_information.update_request_count, 1);
    expect(fake_user_messaging_channel.required_form_count, 1);
  });

  test('UMP 刷新失败且无历史许可时，本次启动的所有广告位都保持关闭', () async {
    fake_consent_information
      ..should_fail_update = true
      ..can_request_ads = false;

    expect(
      await AdMobConsentPermissionRequest.initialize_on_app_start(),
      isFalse,
    );
    expect(await AdMobConsentPermissionRequest.request_before_ad(), isFalse);

    expect(fake_consent_information.update_request_count, 1);
    expect(fake_user_messaging_channel.required_form_count, 0);
    final AdMobStartupPrivacyResult result =
        await AdMobConsentPermissionRequest.initialize_on_app_start_with_result();
    expect(result.can_continue_to_notification_permission, isTrue);
  });

  test('用户修改隐私选项后更新全局许可并通知长期存活广告位', () async {
    await AdMobConsentPermissionRequest.initialize_on_app_start();
    int revision_notifications = 0;
    void on_revision() => revision_notifications += 1;
    AdMobConsentPermissionRequest.privacy_choice_revision.addListener(
      on_revision,
    );
    fake_consent_information.can_request_ads = false;

    final bool did_show =
        await AdMobConsentPermissionRequest.show_privacy_options_form();
    final bool can_request_ads =
        await AdMobConsentPermissionRequest.request_before_ad();

    AdMobConsentPermissionRequest.privacy_choice_revision.removeListener(
      on_revision,
    );
    expect(did_show, isTrue);
    expect(can_request_ads, isFalse);
    expect(revision_notifications, 1);
    expect(fake_user_messaging_channel.privacy_options_form_count, 1);
  });
}

class _FakeConsentInformation implements ConsentInformation {
  int update_request_count = 0;
  int can_request_ads_count = 0;
  bool should_fail_update = false;
  bool can_request_ads = true;
  ConsentStatus consent_status = ConsentStatus.obtained;
  ConsentStatus consent_status_after_form = ConsentStatus.obtained;

  @override
  Future<bool> canRequestAds() async {
    can_request_ads_count += 1;
    return can_request_ads;
  }

  @override
  Future<ConsentStatus> getConsentStatus() async => consent_status;

  @override
  Future<PrivacyOptionsRequirementStatus>
  getPrivacyOptionsRequirementStatus() async {
    return PrivacyOptionsRequirementStatus.required;
  }

  @override
  Future<bool> isConsentFormAvailable() async => true;

  @override
  void requestConsentInfoUpdate(
    ConsentRequestParameters params,
    OnConsentInfoUpdateSuccessListener successListener,
    OnConsentInfoUpdateFailureListener failureListener,
  ) {
    update_request_count += 1;
    scheduleMicrotask(() {
      if (should_fail_update) {
        failureListener(FormError(errorCode: 1, message: 'test failure'));
      } else {
        successListener();
      }
    });
  }

  @override
  Future<void> reset() async {}
}

class _FakeUserMessagingChannel extends UserMessagingChannel {
  _FakeUserMessagingChannel()
    : super(const MethodChannel('test.google_mobile_ads.ump'));

  int required_form_count = 0;
  int privacy_options_form_count = 0;
  void Function()? on_required_form_closed;
  FormError? required_form_error;

  @override
  Future<FormError?> loadAndShowConsentFormIfRequired() async {
    required_form_count += 1;
    await Future<void>.delayed(Duration.zero);
    on_required_form_closed?.call();
    return required_form_error;
  }

  @override
  Future<FormError?> showPrivacyOptionsForm() async {
    privacy_options_form_count += 1;
    return null;
  }
}
