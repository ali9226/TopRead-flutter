// ignore_for_file: non_constant_identifier_names

import 'package:app/common_style/submit_button/index.dart';
import 'package:app/components/auth_form_widgets/auth_submit_button.dart';
import 'package:app/stores/authorized_login_store.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    const MethodChannel preferencesChannel = MethodChannel(
      'plugins.flutter.io/shared_preferences',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(preferencesChannel, (
          MethodCall methodCall,
        ) async {
          if (methodCall.method == 'getAll') {
            return <String, Object>{};
          }
          return true;
        });
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    Get.testMode = true;
    Get.put(AuthorizedLoginStore());
  });

  tearDown(Get.reset);

  testWidgets('第三方授权期间提交按钮响应式禁用并展示加载状态', (WidgetTester tester) async {
    int tap_count = 0;
    final AuthorizedLoginStore store = Get.find<AuthorizedLoginStore>();

    await tester.pumpWidget(
      _build_test_app(
        AuthSubmitButton(
          isLoginMode: true,
          loading: false,
          onTap: () {
            tap_count++;
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(CommonSubmitButton));
    expect(tap_count, 1);

    expect(store.try_start_authentication('google'), isTrue);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(CommonSubmitButton));
    expect(tap_count, 1);

    store.finish_authentication('google');
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(find.byType(CommonSubmitButton));
    expect(tap_count, 2);
  });
}

Widget _build_test_app(Widget child) {
  return EasyLocalization(
    supportedLocales: const <Locale>[Locale('zh')],
    path: 'assets/i18n',
    assetLoader: const _AuthButtonTestAssetLoader(),
    startLocale: const Locale('zh'),
    fallbackLocale: const Locale('zh'),
    child: Builder(
      builder: (BuildContext context) {
        return MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: Scaffold(body: child),
        );
      },
    ),
  );
}

class _AuthButtonTestAssetLoader extends AssetLoader {
  const _AuthButtonTestAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    return <String, dynamic>{
      'UserInfo': <String, dynamic>{'login': '登录'},
      'login': <String, dynamic>{'register_now': '立即注册'},
    };
  }
}
