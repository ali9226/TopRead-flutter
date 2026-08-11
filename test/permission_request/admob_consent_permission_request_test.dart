import 'package:app/permission_request/admob_consent_permission_request.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ConsentInformation original_consent_information;
  late _FakeConsentInformation fake_consent_information;

  setUpAll(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    original_consent_information = ConsentInformation.instance;
    fake_consent_information = _FakeConsentInformation();
    ConsentInformation.instance = fake_consent_information;
  });

  tearDownAll(() {
    ConsentInformation.instance = original_consent_information;
    debugDefaultTargetPlatformOverride = null;
  });

  test('每次进程只更新一次 UMP 状态并读取隐私选项入口要求', () async {
    await AdMobConsentPermissionRequest.update_on_app_start();
    await AdMobConsentPermissionRequest.update_on_app_start();

    final bool is_required =
        await AdMobConsentPermissionRequest.is_privacy_options_required();

    expect(fake_consent_information.update_request_count, 1);
    expect(is_required, isTrue);
  });
}

class _FakeConsentInformation implements ConsentInformation {
  int update_request_count = 0;

  @override
  Future<bool> canRequestAds() async => true;

  @override
  Future<ConsentStatus> getConsentStatus() async => ConsentStatus.obtained;

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
    successListener();
  }

  @override
  Future<void> reset() async {}
}
