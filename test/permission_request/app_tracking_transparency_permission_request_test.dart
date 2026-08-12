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

  test('ATT 状态读取器不会请求系统弹窗', () async {
    final List<String> invoked_methods = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          invoked_methods.add(call.method);
          if (call.method == 'getTrackingAuthorizationStatus') {
            return 'denied';
          }
          return null;
        });

    final AppTrackingAuthorizationStatus status =
        await AppTrackingTransparencyPermissionRequest.get_authorization_status();

    expect(invoked_methods, <String>['getTrackingAuthorizationStatus']);
    expect(status, AppTrackingAuthorizationStatus.denied);
  });
}
