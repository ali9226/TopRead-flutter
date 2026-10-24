// ignore_for_file: non_constant_identifier_names

import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;
import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:app/components/window_content_layout/index.dart';
import 'package:app/components/title_with_story_id/index.dart';
import 'package:app/pages/read/utils/read_models.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/hero/index.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:app/stores/user_information.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

const _preview_dir = String.fromEnvironment('READ_HERO_PREVIEW_DIR');

/// Hero 几何不依赖网络、磁盘缓存或原生路径插件。
class _NoImageCache implements BaseCacheManager {
  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) => Stream<FileResponse>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Assets extends AssetLoader {
  const _Assets();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      Map<String, dynamic>.from(
        jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
            as Map,
      );
}

ReadDetail _detail(String language) => ReadDetail(
  story_id: 42,
  title: language == 'zh'
      ? '在群星闪耀的遥远世界寻找最后一缕晨光的漫长旅途'
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
  intro_text: 'A story about the world beyond the last morning star.',
  chapter_title: 'First chapter',
  comment_list: const [],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    // 每个测试文件由独立 isolate 执行；直接覆盖可避免初始化原生缓存插件。
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
        final file = File(
          '/System/Library/Fonts/Supplemental/${entry.value}.ttf',
        );
        if (file.existsSync()) {
          await (FontLoader(entry.key)..addFont(
                Future.value(ByteData.sublistView(file.readAsBytesSync())),
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

  for (final size in [
    if (_preview_dir.isNotEmpty) const Size(390, 844),
    const Size(466, 678),
    const Size(951, 669),
  ]) {
    for (final language in ['zh', 'en']) {
      testWidgets('Duo小说Hero $size $language 1.6x保持全幅背景与独立可读内容', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final dark = language == 'en';
        final cutout = Rect.fromLTWH(size.width - 84, 0, 84, 124);
        await tester.pumpWidget(
          EasyLocalization(
            supportedLocales: [Locale(language)],
            startLocale: Locale(language),
            fallbackLocale: Locale(language),
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
                    textScaler: const TextScaler.linear(1.6),
                    padding: const EdgeInsets.only(right: 84, bottom: 34),
                    viewPadding: const EdgeInsets.only(right: 84, bottom: 34),
                    displayFeatures: [
                      DisplayFeature(
                        bounds: cutout,
                        type: DisplayFeatureType.cutout,
                        state: DisplayFeatureState.unknown,
                      ),
                    ],
                  ),
                  child: WindowLayoutScope(
                    child: Scaffold(
                      body: WindowContentLayout(
                        child: SingleChildScrollView(
                          child: RepaintBoundary(
                            key: const ValueKey('read_hero_capture'),
                            child: ReadIntroductionHero(
                              is_dark: dark,
                              detail: _detail(language),
                              on_back: () {},
                              on_share: () {},
                              on_read: () {},
                              on_favorite: () {},
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
        // 封面占位使用循环骨架屏；几何测试只推进布局与有限过渡帧。
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(tester.takeException(), isNull);
        Rect bounds(String key) => tester.getRect(find.byKey(ValueKey(key)));
        final hero = bounds('novel_introduction_hero');
        final cover = bounds('novel_hero_cover');
        final metadata = bounds('work_introduction_metadata');
        final title = bounds('novel_hero_title');
        final poster = bounds('work_introduction_poster');
        final author_style = tester
            .widget<Text>(find.text(_detail(language).author_name))
            .style!;
        final title_style = tester
            .widget<TitleWithStoryId>(
              find.byKey(const ValueKey('novel_hero_title')),
            )
            .title_style;
        expect(title_style.shadows, isNotEmpty);
        expect(author_style.shadows, title_style.shadows);
        expect(hero.left, closeTo(0, 0.1));
        expect(hero.width, closeTo(size.width, 0.1));
        expect(cover.left, greaterThanOrEqualTo(hero.left));
        expect(poster.height, greaterThan(0));
        if (find
            .byKey(const ValueKey('work_introduction_panel'))
            .evaluate()
            .isNotEmpty) {
          expect(title.top, greaterThanOrEqualTo(cover.bottom));
          expect(
            bounds('novel_hero_author').top,
            greaterThanOrEqualTo(title.bottom),
          );
        } else {
          expect(cover.right, lessThanOrEqualTo(metadata.left + 0.1));
        }
        final stats = bounds('novel_hero_stats');
        expect(stats.top, greaterThanOrEqualTo(metadata.bottom));
        expect(stats.right, lessThanOrEqualTo(hero.right));
        expect(stats.bottom, lessThanOrEqualTo(hero.bottom));
        for (final key in ['novel_hero_title', 'novel_hero_author']) {
          final rect = bounds(key);
          expect(rect.left, greaterThanOrEqualTo(metadata.left - 0.1));
          expect(rect.right, lessThanOrEqualTo(hero.right + 0.1));
          expect(rect.bottom, lessThanOrEqualTo(hero.bottom + 0.1));
        }
        expect(title.overlaps(cutout), isFalse);
        if (_preview_dir.isNotEmpty) {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('read_hero_capture')),
          );
          await tester.runAsync(() async {
            await Directory(_preview_dir).create(recursive: true);
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              '$_preview_dir/hero_${size.width.toInt()}_${language}_${dark ? 'dark' : 'light'}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
