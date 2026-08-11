import 'package:app/permission_request/app_tracking_transparency_permission_request.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel(
    'com.topread.novel/advertising_info',
  );

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('ATT 已拒绝时只检查状态且不再请求系统弹窗', () async {
    final List<String> invoked_methods = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          invoked_methods.add(call.method);
          if (call.method == 'getTrackingAuthorizationStatus') {
            return 'denied';
          }
          return null;
        });

    await AppTrackingTransparencyPermissionRequest.request_before_rewarded_ad();

    expect(invoked_methods, <String>['getTrackingAuthorizationStatus']);
  });
}
