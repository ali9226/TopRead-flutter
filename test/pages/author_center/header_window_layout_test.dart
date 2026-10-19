// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:app/components/window_content_layout/index.dart';
import 'package:app/pages/author_center/widgets/creator_header.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _Assets extends AssetLoader {
  const _Assets();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      Map<String, dynamic>.from(
        jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
            as Map,
      );
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

  for (final dark in <bool>[false, true]) {
    testWidgets('作者展开和收起导航与透明命中区域同步局部避让 $dark', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(951, 669);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final header_height = ValueNotifier<double>(500);
      addTearDown(header_height.dispose);
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en')],
          path: 'assets/i18n',
          assetLoader: const _Assets(),
          startLocale: const Locale('en'),
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
                data: const MediaQueryData(
                  size: Size(951, 669),
                  padding: EdgeInsets.only(right: 84, bottom: 34),
                  viewPadding: EdgeInsets.only(right: 84, bottom: 34),
                  displayFeatures: [
                    DisplayFeature(
                      bounds: Rect.fromLTWH(867, 0, 84, 124),
                      type: DisplayFeatureType.cutout,
                      state: DisplayFeatureState.unknown,
                    ),
                  ],
                ),
                child: WindowLayoutScope(
                  child: Scaffold(
                    body: DefaultTabController(
                      length: 4,
                      child: Builder(
                        builder: (context) => ValueListenableBuilder<double>(
                          valueListenable: header_height,
                          builder: (context, height, _) => Align(
                            alignment: Alignment.topCenter,
                            child: CreatorHeaderOverlay(
                              tab_controller: DefaultTabController.of(context),
                              current_height: height,
                              is_dark: dark,
                              is_cjk: false,
                              author_name: 'Ali',
                              works_count: 12,
                              favorites_count: '23',
                              comments_count: '34',
                              dashboard_loaded: true,
                              on_back: () {},
                              on_create_work: () {},
                              on_continue_writing: () {},
                              on_open_guide: () {},
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      for (final height in [500.0, 108.0, 500.0]) {
        header_height.value = height;
        await tester.pumpAndSettle();
        expect(
          tester
              .getSize(find.byKey(const ValueKey('creator_header_surface')))
              .width,
          951,
        );
        for (final tooltip in find.byType(Tooltip).evaluate()) {
          final rect = tester.getRect(find.byWidget(tooltip.widget));
          if (rect.top < 124) {
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(867));
          }
        }
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('Duo作者头部背景满窗，前景与命中代理共同避让 ${dark ? 'dark' : 'light'}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(466, 678);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const <Locale>[Locale('en')],
          path: 'assets/i18n',
          assetLoader: const _Assets(),
          startLocale: const Locale('en'),
          saveLocale: false,
          child: Builder(
            builder: (context) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              theme: ThemeData(
                brightness: dark ? Brightness.dark : Brightness.light,
              ),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  padding: const EdgeInsets.only(right: 84, bottom: 34),
                ),
                child: child!,
              ),
              home: WindowLayoutScope(
                child: Scaffold(
                  body: DefaultTabController(
                    length: 4,
                    child: Builder(
                      builder: (context) => Align(
                        alignment: Alignment.topCenter,
                        child: CreatorHeaderOverlay(
                          tab_controller: DefaultTabController.of(context),
                          current_height: 500,
                          is_dark: dark,
                          is_cjk: false,
                          author_name: 'Ali',
                          works_count: 12,
                          favorites_count: '23',
                          comments_count: '34',
                          dashboard_loaded: true,
                          on_back: () {},
                          on_create_work: () {},
                          on_continue_writing: () {},
                          on_open_guide: () {},
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final surface = find.byKey(const ValueKey('creator_header_surface'));
      expect(tester.getSize(surface).width, 466);
      final foreground = find.byType(WindowContentLayout);
      final safe_child = tester.widget<WindowContentLayout>(foreground).child;
      final content = find.byWidget(safe_child);
      expect(tester.getSize(content).width, 382);
      for (final tooltip in find.byType(Tooltip).evaluate()) {
        final rect = tester.getRect(find.byWidget(tooltip.widget));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(382));
      }
      expect(tester.takeException(), isNull);
      tester.view.physicalSize = const Size(1048, 748);
      await tester.pumpAndSettle();
      expect(tester.getSize(surface).width, 1048);
      final expanded_child = tester
          .widget<WindowContentLayout>(foreground)
          .child;
      expect(tester.getSize(find.byWidget(expanded_child)).width, 900);
      expect(tester.takeException(), isNull);
    });
  }
}
