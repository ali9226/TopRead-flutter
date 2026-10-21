// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/comics/detail/widgets/reading_action_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _Translations extends AssetLoader {
  const _Translations();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {
    'comics': {
      'collected': 'Saved',
      'add_to_library': 'Add to library',
      'continue_reading_action': 'Continue reading',
      'start_reading': 'Start reading',
      'unavailable': 'Not available',
      'chapter_position': 'Chapter {index}',
    },
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

  Future<void> mount(
    WidgetTester tester,
    ComicReadingActionBar bar, {
    bool dark = false,
    double scale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        startLocale: const Locale('en'),
        fallbackLocale: const Locale('en'),
        path: 'unused',
        saveLocale: false,
        assetLoader: const _Translations(),
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            theme: ThemeData(
              brightness: dark ? Brightness.dark : Brightness.light,
            ),
            home: Scaffold(
              body: MediaQuery(
                data: MediaQueryData(
                  size: const Size(320, 640),
                  textScaler: TextScaler.linear(scale),
                ),
                child: Align(alignment: Alignment.bottomCenter, child: bar),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final dark in [false, true]) {
    testWidgets('320px 2x ${dark ? 'dark' : 'light'}可操作且展示真实章节', (
      tester,
    ) async {
      var collected = 0;
      var read = 0;
      await mount(
        tester,
        ComicReadingActionBar(
          collected: false,
          continuing: true,
          chapter_number: 12,
          on_collect: () => collected++,
          on_read: () => read++,
        ),
        dark: dark,
        scale: 2,
      );
      expect(find.text('Chapter 12'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('comic_library_action')));
      await tester.tap(find.byKey(const ValueKey('comic_reading_action')));
      expect(collected, 1);
      expect(read, 1);
    });
  }

  testWidgets('忙碌收藏和空目录不触发写入或阅读', (tester) async {
    var operations = 0;
    await mount(
      tester,
      ComicReadingActionBar(
        collected: true,
        collecting: true,
        can_read: false,
        chapter_number: null,
        on_collect: () => operations++,
        on_read: () => operations++,
      ),
    );
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Not available'), findsOneWidget);
    expect(find.textContaining('Chapter'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('comic_library_action')));
    await tester.tap(find.byKey(const ValueKey('comic_reading_action')));
    expect(operations, 0);
    expect(tester.takeException(), isNull);
  });
}
