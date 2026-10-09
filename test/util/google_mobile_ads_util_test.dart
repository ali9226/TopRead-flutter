// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/models/project_config.dart';
import 'package:app/permission_request/admob_consent_permission_request.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:app/util/google_mobile_ads_util.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mobile_ads/src/ad_instance_manager.dart' as ads_sdk;
import 'package:google_mobile_ads/src/ump/user_messaging_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('并发入口共享 SDK 初始化，隐私更新使等待中的旧许可失效', (tester) async {
    final ads_sdk.AdInstanceManager original_ad_manager =
        ads_sdk.instanceManager;
    final ConsentInformation original_consent = ConsentInformation.instance;
    final UserMessagingChannel original_ump = UserMessagingChannel.instance;
    final Completer<InitializationStatus> initialization_gate =
        Completer<InitializationStatus>();
    int initialization_count = 0;
    ads_sdk.instanceManager = ads_sdk.AdInstanceManager(
      'test.ad.sdk.initialize',
    );
    final MethodChannel channel = ads_sdk.instanceManager.channel;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          if (call.method == 'MobileAds#initialize') {
            initialization_count += 1;
            return initialization_gate.future;
          }
          return null;
        });
    Get.testMode = true;
    final ProjectConfigStore store = Get.put(ProjectConfigStore());
    store.save_config(_project_config(SwitchValue.on));
    ConsentInformation.instance = _FakeConsentInformation();
    UserMessagingChannel.instance = _FakeUserMessagingChannel();
    AdMobConsentPermissionRequest.reset_for_test();

    try {
      await tester.runAsync(
        AdMobConsentPermissionRequest.initialize_on_app_start,
      );
      final Future<bool> first_request = GoogleMobileAdsUtil.instance
          .ensure_initialized();
      final Future<bool> concurrent_request = GoogleMobileAdsUtil.instance
          .ensure_initialized();
      await _flush_tasks(tester);
      expect(initialization_count, 1);

      await tester.runAsync(
        AdMobConsentPermissionRequest.show_privacy_options_form,
      );
      final Future<bool> current_request = GoogleMobileAdsUtil.instance
          .ensure_initialized();
      await _flush_tasks(tester);
      expect(initialization_count, 1);

      initialization_gate.complete(
        InitializationStatus(<String, AdapterStatus>{}),
      );
      await _flush_tasks(tester);
      expect(await first_request, isFalse);
      expect(await concurrent_request, isFalse);
      expect(await current_request, isTrue);

      // SDK 可以保留已经完成的初始化，但关闭开关时不返回加载资格。
      store.save_config(_project_config(SwitchValue.off));
      expect(await GoogleMobileAdsUtil.instance.ensure_initialized(), isFalse);
      store.save_config(_project_config(SwitchValue.on));
      final Future<bool> cached_request = GoogleMobileAdsUtil.instance
          .ensure_initialized();
      await _flush_tasks(tester);
      expect(await cached_request, isTrue);
      expect(initialization_count, 1);
    } finally {
      if (!initialization_gate.isCompleted) {
        initialization_gate.complete(
          InitializationStatus(<String, AdapterStatus>{}),
        );
        await _flush_tasks(tester);
      }
      channel.setMethodCallHandler(null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      ads_sdk.instanceManager = original_ad_manager;
      ConsentInformation.instance = original_consent;
      UserMessagingChannel.instance = original_ump;
      AdMobConsentPermissionRequest.reset_for_test();
      Get.reset();
    }
  });
}

Future<void> _flush_tasks(WidgetTester tester) async {
  for (int round = 0; round < 3; round++) {
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

ProjectConfig _project_config(int ads_switch) =>
    ProjectConfig.from_json(<String, dynamic>{'ads_switch': ads_switch});

class _FakeConsentInformation implements ConsentInformation {
  @override
  Future<bool> canRequestAds() async => true;

  @override
  Future<ConsentStatus> getConsentStatus() async => ConsentStatus.obtained;

  @override
  Future<PrivacyOptionsRequirementStatus>
  getPrivacyOptionsRequirementStatus() async =>
      PrivacyOptionsRequirementStatus.notRequired;

  @override
  Future<bool> isConsentFormAvailable() async => false;

  @override
  void requestConsentInfoUpdate(
    ConsentRequestParameters params,
    OnConsentInfoUpdateSuccessListener successListener,
    OnConsentInfoUpdateFailureListener failureListener,
  ) => scheduleMicrotask(successListener);

  @override
  Future<void> reset() async {}
}

class _FakeUserMessagingChannel extends UserMessagingChannel {
  _FakeUserMessagingChannel()
    : super(const MethodChannel('test.sdk.initialize.ump'));

  @override
  Future<FormError?> loadAndShowConsentFormIfRequired() async => null;

  @override
  Future<FormError?> showPrivacyOptionsForm() async => null;
}
