import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/components/load_more_footer/index.dart';

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

  testWidgets('加载更多底部组件统一展示加载动画、三点文案和可点击状态', (WidgetTester tester) async {
    int load_more_count = 0;

    await tester.pumpWidget(
      _build_test_app(
        LoadMoreFooter(
          is_dark: false,
          is_loading: true,
          has_more: true,
          on_load_more: () {
            load_more_count++;
          },
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('加载中...'), findsOneWidget);
    expect(find.text('加载更多'), findsNothing);

    await tester.pumpWidget(
      _build_test_app(
        LoadMoreFooter(
          is_dark: false,
          is_loading: false,
          has_more: true,
          on_load_more: () {
            load_more_count++;
          },
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('加载更多'));

    expect(load_more_count, 1);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pumpWidget(
      _build_test_app(
        const LoadMoreFooter(is_dark: true, is_loading: false, has_more: false),
      ),
    );
    await tester.pump();

    expect(find.text('没有更多了'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}

Widget _build_test_app(Widget child) {
  return EasyLocalization(
    supportedLocales: const <Locale>[Locale('zh')],
    path: 'assets/i18n',
    assetLoader: const _LoadMoreFooterTestAssetLoader(),
    startLocale: const Locale('zh'),
    fallbackLocale: const Locale('zh'),
    child: Builder(
      builder: (BuildContext context) {
        return MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: Scaffold(body: Center(child: child)),
        );
      },
    ),
  );
}

class _LoadMoreFooterTestAssetLoader extends AssetLoader {
  const _LoadMoreFooterTestAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    return <String, dynamic>{
      'bookshelf': <String, dynamic>{
        'load_more': <String, dynamic>{
          'button': '加载更多',
          'loading': '加载中...',
          'no_more': '没有更多了',
        },
      },
    };
  }
}
