// ignore_for_file: non_constant_identifier_names

import 'package:app/models/comics.dart';
import 'package:app/pages/comics/reader/logic.dart';
import 'package:app/pages/comics/reader/widgets/reading_panels/index.dart';
import 'package:app/stores/device_info.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Assets extends AssetLoader {
  const _Assets();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {
    'comics': {
      'reading_progress': 'Reading progress',
      'reader_page_progress': 'Page {page} of {total}',
      'screen_brightness': 'Brightness',
      'brightness_unavailable': 'Unavailable',
    },
    'short_story_read': {
      'auto_read': 'Auto-Read',
      'theme': 'Theme',
      'theme_day': 'Day',
      'theme_night': 'Night',
    },
    'bookshelf': {
      'progress': {'read_progress': 'Read {progress}%'},
    },
  };
}

class _Device extends DeviceInfo {
  @override
  // ignore: must_call_super
  void onInit() {}
  @override
  void changeTheme(ThemeMode mode) {
    theme.value = mode;
    dark.value = mode == ThemeMode.dark;
  }
}

class _Reader extends ComicReaderLogic {
  _Reader() {
    loading = false;
    set_width(320);
    reading = ComicReading.from_json({
      'comic': {'id': 1},
      'language': {'id': 1},
      'chapter': {'id': 1, 'title': 'First chapter'},
      'images': [
        {'image_url': '', 'width': 320, 'height': 3000},
      ],
    });
  }
  @override
  Future<void> flush() async {}
  @override
  Future<void> save_progress() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  setUpAll(() async {
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (_) async => <String, Object>{},
    );
    await EasyLocalization.ensureInitialized();
  });
  setUp(() {
    Get.testMode = true;
    Get.put<DeviceInfo>(_Device());
  });
  tearDown(() {
    Get.reset();
    messenger.setMockMethodCallHandler(
      ComicReaderBrightnessSession.channel,
      null,
    );
  });

  Future<void> mount(
    WidgetTester tester,
    Widget Function(BuildContext) body,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        startLocale: const Locale('en'),
        path: 'unused',
        saveLocale: false,
        assetLoader: const _Assets(),
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(padding: const EdgeInsets.only(bottom: 34)),
              child: child!,
            ),
            home: Scaffold(body: Builder(builder: body)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('进度面板覆盖底部安全区，自动阅读居中且定位平滑', (tester) async {
    final logic = _Reader();
    addTearDown(logic.dispose);
    await mount(
      tester,
      (context) => Stack(
        children: [
          SingleChildScrollView(
            controller: logic.scroll,
            child: const SizedBox(width: 320, height: 3000),
          ),
          TextButton(
            onPressed: () => show_comic_progress_sheet(
              context,
              logic: logic,
              on_start_auto_read: () {},
            ),
            child: const Text('open'),
          ),
        ],
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final surface = tester.getRect(
      find.byKey(const ValueKey('comic_reading_panel_surface')),
    );
    expect(surface.bottom, closeTo(700, 0.1));
    final auto = tester.getRect(find.widgetWithText(TextButton, 'Auto-Read'));
    expect(auto.center.dx, closeTo(160, 0.1));
    final slider = tester.widget<Slider>(
      find.byKey(const ValueKey('comic_chapter_progress_slider')),
    );
    slider.onChanged!(0.75);
    slider.onChangeEnd!(0.75);
    await tester.pump();
    expect(logic.scroll.offset, 0);
    await tester.pump(const Duration(milliseconds: 160));
    final halfway = logic.scroll.offset;
    expect(halfway, greaterThan(0));
    expect(halfway, lessThan(logic.chapter_scroll_extent * 0.75));
    await tester.pumpAndSettle();
    expect(logic.chapter_progress, closeTo(0.75, 0.01));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('主题与亮度面板覆盖安全区，主题在共用动画中点切换', (tester) async {
    messenger.setMockMethodCallHandler(
      ComicReaderBrightnessSession.channel,
      (call) async => call.method == 'getBrightness'
          ? {'brightness': 0.5, 'override': 0.5}
          : null,
    );
    final brightness = ComicReaderBrightnessSession();
    addTearDown(brightness.dispose);
    await mount(
      tester,
      (context) => TextButton(
        onPressed: () =>
            show_comic_appearance_sheet(context, brightness: brightness),
        child: const Text('open'),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final surface = tester.getRect(
      find.byKey(const ValueKey('comic_reading_panel_surface')),
    );
    expect(surface.bottom, closeTo(700, 0.1));
    await tester.tap(find.text('Night'));
    await tester.pump();
    expect(Get.find<DeviceInfo>().theme.value, ThemeMode.light);
    await tester.pump(const Duration(milliseconds: 400));
    expect(Get.find<DeviceInfo>().theme.value, ThemeMode.light);
    await tester.pump(const Duration(milliseconds: 250));
    expect(Get.find<DeviceInfo>().theme.value, ThemeMode.dark);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
