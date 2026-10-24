import 'dart:convert';
import 'dart:io';

import 'package:app/components/page_top_gradient_overlay/index.dart';
import 'package:app/components/top_header_gradient/index.dart';
import 'package:app/components/window_content_layout/index.dart';
import 'package:app/pages/short_story_read/widgets/reader_overlay_layer.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Assets extends AssetLoader {
  const _Assets();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      Map<String, dynamic>.from(
        jsonDecode(File('$path/en.json').readAsStringSync()) as Map,
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (_) async => <String, Object>{},
        );
    await EasyLocalization.ensureInitialized();
  });
  setUp(() {
    Get.testMode = true;
    Get.put(ProjectConfigStore());
  });
  tearDown(Get.reset);

  testWidgets('短篇覆盖层随正文可见状态淡入淡出，Duo边缘保持全幅且穿透点击', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(466, 678);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final body_visible = ValueNotifier(false);
    addTearDown(body_visible.dispose);
    var taps = 0;
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        startLocale: const Locale('en'),
        fallbackLocale: const Locale('en'),
        path: 'assets/i18n',
        saveLocale: false,
        assetLoader: const _Assets(),
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(466, 678),
                padding: EdgeInsets.only(top: 32, right: 84, bottom: 34),
                viewPadding: EdgeInsets.only(top: 32, right: 84, bottom: 34),
              ),
              child: WindowLayoutScope(
                child: Scaffold(
                  body: Stack(
                    fit: StackFit.expand,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => taps++,
                        child: const SizedBox.expand(),
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: body_visible,
                        builder: (_, visible, _) => ReaderOverlayLayer(
                          is_dark: false,
                          status_bar_height: 32,
                          bottom_padding: 34,
                          bg_color: Colors.white,
                          is_appbar_visible: false,
                          show_top_bar: visible,
                          bottom_bar_slide_animation:
                              const AlwaysStoppedAnimation(Offset(0, 1)),
                          floating_button_fade_animation:
                              const AlwaysStoppedAnimation(0),
                          show_floating_button: false,
                          show_progress_bar: false,
                          catalog_loaded: false,
                          is_favorited: false,
                          is_favorite_loading: false,
                          comment_count: 0,
                          like_count: 0,
                          is_liked: false,
                          is_like_loading: false,
                          reading_progress: 0,
                          has_previous: false,
                          has_next: false,
                          is_bottom_bar_visible: false,
                          is_auto_reading: false,
                          on_back: () {},
                          on_favorite_tap: () {},
                          on_share: () {},
                          on_catalog_tap: () {},
                          on_comment_tap: () {},
                          on_like_tap: () {},
                          on_setting_tap: () {},
                          on_previous_tap: () {},
                          on_next_tap: () {},
                          on_progress_changed: (_) {},
                          on_progress_change_end: (_, complete) => complete(),
                          on_scroll_to_bottom: () {},
                          on_auto_read_settings_tap: () {},
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final overlay = find.byType(PageTopGradientOverlay);
    final gradient = find.descendant(
      of: overlay,
      matching: find.byType(TopHeaderGradient),
    );
    double opacity() => tester
        .widget<FadeTransition>(
          find.descendant(of: overlay, matching: find.byType(FadeTransition)),
        )
        .opacity
        .value;
    final original_element = tester.element(gradient);
    expect(opacity(), 0);
    expect(tester.getRect(gradient), const Rect.fromLTWH(0, 0, 466, 90));
    body_visible.value = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(opacity(), inExclusiveRange(0, 1));
    await tester.pump(const Duration(milliseconds: 300));
    expect(opacity(), 1);
    await tester.tapAt(const Offset(430, 30));
    expect(taps, 1);
    body_visible.value = false;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(opacity(), inExclusiveRange(0, 1));
    await tester.pump(const Duration(milliseconds: 300));
    expect(opacity(), 0);
    expect(tester.element(gradient), same(original_element));
    expect(tester.takeException(), isNull);
  });
}
