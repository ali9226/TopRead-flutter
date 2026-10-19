// ignore_for_file: non_constant_identifier_names

import 'package:app/components/home_header_bar/index.dart';
import 'package:app/components/home_top_search_entry/index.dart';
import 'package:app/models/language_info.dart';
import 'package:app/stores/home_store.dart';
import 'package:app/stores/language_store.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _LanguageFixture extends LanguageStore {
  _LanguageFixture() : super(asset_language_code_list: ['en', 'zh']);
  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  LanguageInfo? find_supported_language_by_code(String? code) => LanguageInfo(
    code: code ?? 'en',
    title: code == 'zh' ? '简体中文（测试超长语言名称）' : 'Português do Brasil — Extended',
  );
}

class _HomeFixture extends HomeBannerStore {
  @override
  // ignore: must_call_super
  void onInit() {}
}

class _Assets extends AssetLoader {
  const _Assets();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {
    'search': {'entry_hint': 'Search for your next favorite story'},
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (call) async => call.method == 'getAll' ? <String, Object>{} : true,
        );
    await EasyLocalization.ensureInitialized();
  });
  setUp(() {
    Get.testMode = true;
    Get.put<LanguageStore>(_LanguageFixture());
    Get.put<HomeBannerStore>(_HomeFixture());
  });
  tearDown(Get.reset);

  for (final language in ['zh', 'en']) {
    for (final dark in [false, true]) {
      testWidgets('首页头栏$language $dark 收起展开长文案与大字号保持可点', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 678);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        var search_taps = 0;
        var language_taps = 0;
        await tester.pumpWidget(
          EasyLocalization(
            supportedLocales: [Locale(language)],
            path: 'assets/i18n',
            assetLoader: const _Assets(),
            startLocale: Locale(language),
            saveLocale: false,
            child: Builder(
              builder: (context) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                theme: ThemeData(
                  brightness: dark ? Brightness.dark : Brightness.light,
                ),
                home: MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(2)),
                  child: Scaffold(
                    body: Align(
                      alignment: Alignment.topCenter,
                      child: HomeHeaderBar(
                        is_dark: dark,
                        on_search_tap: () => search_taps++,
                        on_language_tap: () => language_taps++,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (final width in [320.0, 466.0, 669.0]) {
          tester.view.physicalSize = Size(width, 951);
          await tester.pumpAndSettle();
          final language_entry = find
              .descendant(
                of: find.byType(HomeHeaderBar),
                matching: find.byType(GestureDetector),
              )
              .last;
          expect(
            tester.getSize(language_entry).height,
            greaterThanOrEqualTo(44),
          );
          expect(
            tester.getSize(find.byType(HomeTopSearchEntry)).width,
            greaterThan(100),
          );
          await tester.tap(language_entry);
          await tester.tap(find.byType(HomeTopSearchEntry));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        expect(search_taps, 3);
        expect(language_taps, 3);
      });
    }
  }
}
