import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;
import 'package:app/components/expandable_synopsis/index.dart';
import 'package:app/components/window_content_layout/index.dart';
import 'package:app/pages/read/utils/read_models.dart';
import 'package:app/pages/read/widgets/introduction_section/index.dart';
import 'package:app/pages/read/widgets/introduction_section/style.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/comment_section/index.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/tag_section/index.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:app/stores/user_information.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

const _preview_dir = String.fromEnvironment('READ_HERO_PREVIEW_DIR');

class _Assets extends AssetLoader {
  const _Assets();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      Map<String, dynamic>.from(
        jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
            as Map,
      );
}

class _NoImageCache implements BaseCacheManager {
  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) => const Stream<FileResponse>.empty();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ReadDetail _detail(String language) => ReadDetail(
  story_id: 42,
  title: language == 'zh'
      ? '在遥远世界寻找最后一缕晨光的漫长旅途'
      : 'The Extraordinary Journey Across the World Beyond the Last Morning Star',
  cover_url: '',
  author_id: 7,
  author_avatar_url: '',
  author_name: language == 'zh' ? '在云端写故事的人' : 'An Author With a Long Name',
  focus_on: false,
  score_major_text: '9.6',
  score_minor_text: '',
  review_count_text: '12.4K ratings',
  reading_major_text: '234.1',
  reading_minor_text: 'K',
  reading_subtitle_text: 'Reading',
  word_count_major_text: '1.2',
  word_count_minor_text: 'M',
  word_count_subtitle_text: 'Words',
  tag_list: language == 'zh'
      ? ['奇幻', '冒险', '浪漫']
      : ['Fantasy', 'Adventure', 'Romance'],
  intro_text: List.filled(
    8,
    language == 'zh'
        ? '在遥远的世界中，他们一起穿越黑暗与群星，找寻属于自己的晨光。'
        : 'Together they travel across the world beyond the last morning star, discovering a mysterious past.',
  ).join(' '),
  chapter_title: 'First chapter',
  comment_list: const [],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    CachedNetworkImageProvider.defaultCacheManager = _NoImageCache();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (_) async => <String, Object>{},
        );
    await EasyLocalization.ensureInitialized();
    if (_preview_dir.isNotEmpty) {
      for (final entry in {
        'Roboto': 'Arial Unicode',
        'Georgia': 'Times New Roman',
      }.entries) {
        final font = File(
          '/System/Library/Fonts/Supplemental/${entry.value}.ttf',
        );
        if (font.existsSync()) {
          await (FontLoader(entry.key)..addFont(
                Future.value(ByteData.sublistView(font.readAsBytesSync())),
              ))
              .load();
        }
      }
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
  });
  setUp(() {
    Get.testMode = true;
    Get.put<UserInformation>(UserInformation());
    Get.put<ProjectConfigStore>(ProjectConfigStore());
  });
  tearDown(Get.reset);

  for (final scenario in [
    (const Size(390, 844), 'zh', 2.0),
    (const Size(466, 678), 'en', 1.6),
    (const Size(951, 669), 'en', 1.6),
  ]) {
    testWidgets('小说简介 ${scenario.$1} ${scenario.$2} 真实圆角重叠且动画不移动标题和章节锚点', (
      tester,
    ) async {
      final size = scenario.$1;
      final dark = scenario.$2 == 'en';
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: [Locale(scenario.$2)],
          startLocale: Locale(scenario.$2),
          fallbackLocale: Locale(scenario.$2),
          path: 'assets/i18n',
          saveLocale: false,
          assetLoader: const _Assets(),
          child: Builder(
            builder: (context) => MaterialApp(
              locale: context.locale,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              theme: ThemeData(
                brightness: dark ? Brightness.dark : Brightness.light,
              ),
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: TextScaler.linear(scenario.$3),
                  padding: const EdgeInsets.only(right: 84, bottom: 34),
                  viewPadding: const EdgeInsets.only(right: 84, bottom: 34),
                  displayFeatures: [
                    DisplayFeature(
                      bounds: Rect.fromLTWH(size.width - 84, 0, 84, 124),
                      type: DisplayFeatureType.cutout,
                      state: DisplayFeatureState.unknown,
                    ),
                  ],
                ),
                child: WindowLayoutScope(
                  child: Scaffold(
                    body: SingleChildScrollView(
                      child: Column(
                        children: [
                          RepaintBoundary(
                            key: const ValueKey('novel_panel_capture'),
                            child: ReadIntroductionSection(
                              is_dark: dark,
                              detail: _detail(scenario.$2),
                              on_back: () {},
                              on_share: () {},
                              on_read: () {},
                              on_favorite: () {},
                            ),
                          ),
                          const SizedBox(
                            key: ValueKey('reading_anchor'),
                            height: 1000,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      Rect bounds(String key) => tester.getRect(find.byKey(ValueKey(key)));
      void verify_geometry() {
        final hero = bounds('novel_introduction_hero');
        final panel = bounds('novel_introduction_content_panel');
        final layout = bounds('novel_introduction_layout');
        expect(
          panel.top,
          closeTo(hero.bottom - IntroductionStyle.content_panel_overlap, 0.01),
        );
        expect(panel.bottom, closeTo(layout.bottom, 0.01));
        expect(bounds('reading_anchor').top, closeTo(panel.bottom, 0.01));
        expect(panel.width, size.width);
        expect(bounds('novel_hero_cover').bottom, lessThan(panel.top));
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('novel_introduction_content_panel')),
            matching: find.byType(ReadTagSection),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('novel_introduction_content_panel')),
            matching: find.byType(ReadCommentSection),
          ),
          findsOneWidget,
        );
      }

      verify_geometry();
      if (_preview_dir.isNotEmpty) {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('novel_panel_capture')),
        );
        await tester.runAsync(() async {
          await Directory(_preview_dir).create(recursive: true);
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '$_preview_dir/panel_${size.width.toInt()}_${scenario.$2}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      expect(find.byType(ExpandableSynopsis), findsOneWidget);
      final header = find.byKey(const ValueKey('novel_about_header'));
      await tester.ensureVisible(header);
      await tester.pump(const Duration(milliseconds: 300));
      final header_rect = tester.getRect(header);
      final collapsed_height = bounds('novel_about_viewport').height;
      await tester.tap(header);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      final expanding_height = bounds('novel_about_viewport').height;
      final collapse = find.byKey(const ValueKey('novel_about_collapse'));
      expect(tester.getRect(collapse), header_rect);
      await tester.pump(const Duration(milliseconds: 300));
      final expanded_height = bounds('novel_about_viewport').height;
      expect(expanding_height, greaterThan(collapsed_height));
      expect(expanding_height, lessThan(expanded_height));
      verify_geometry();
      await tester.tap(collapse);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(
        bounds('novel_about_viewport').height,
        greaterThan(collapsed_height),
      );
      expect(bounds('novel_about_viewport').height, lessThan(expanded_height));
      expect(
        tester
            .widget<Text>(find.text(_detail(scenario.$2).intro_text))
            .maxLines,
        isNull,
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(bounds('novel_about_viewport').height, collapsed_height);
      verify_geometry();
      expect(tester.takeException(), isNull);
    });
  }
}
