// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:app/pages/interest_preference/widgets/top_bar/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    const MethodChannel preferences_channel = MethodChannel(
      'plugins.flutter.io/shared_preferences',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(preferences_channel, (
          MethodCall method_call,
        ) async {
          if (method_call.method == 'getAll') {
            return <String, Object>{};
          }
          return true;
        });
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('普通兴趣偏好顶部栏只展示保存按钮', (WidgetTester tester) async {
    await tester.pumpWidget(
      _build_test_app(
        TopBar(
          isDark: false,
          scrolled: false,
          statusBarHeight: 0,
          isLoading: false,
          canSave: true,
          onSave: () {},
          onBack: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('保存'), findsOneWidget);
    expect(find.text('跳过'), findsNothing);
  });

  testWidgets('注册兴趣偏好顶部栏在保存右侧展示可点击的跳过按钮', (WidgetTester tester) async {
    int skip_count = 0;

    await tester.pumpWidget(
      _build_test_app(
        TopBar(
          isDark: false,
          scrolled: false,
          statusBarHeight: 0,
          isLoading: false,
          canSave: true,
          onSave: () {},
          onBack: () {},
          onSkip: () {
            skip_count++;
          },
        ),
      ),
    );
    await tester.pump();

    final Finder save_button = find.text('保存');
    final Finder skip_button = find.text('跳过');
    expect(save_button, findsOneWidget);
    expect(skip_button, findsOneWidget);
    expect(
      tester.getCenter(skip_button).dx,
      greaterThan(tester.getCenter(save_button).dx),
    );

    await tester.tap(skip_button);
    expect(skip_count, 1);
  });
}

Widget _build_test_app(Widget child) {
  return EasyLocalization(
    supportedLocales: const <Locale>[Locale('zh')],
    path: 'assets/i18n',
    assetLoader: const _InterestPreferenceTestAssetLoader(),
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

class _InterestPreferenceTestAssetLoader extends AssetLoader {
  const _InterestPreferenceTestAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    return <String, dynamic>{
      'interest_preference': <String, dynamic>{'save': '保存', 'skip': '跳过'},
    };
  }
}
