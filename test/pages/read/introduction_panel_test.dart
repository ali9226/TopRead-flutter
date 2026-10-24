import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;
import 'package:app/components/expandable_synopsis/index.dart';
import 'package:app/components/expandable_synopsis/toggle_button.dart';
import 'package:app/components/window_content_layout/index.dart';
import 'package:app/components/title_with_story_id/index.dart';
import 'package:app/components/work_genres_section/index.dart';
import 'package:app/pages/read/utils/read_models.dart';
import 'package:app/pages/read/widgets/introduction_section/index.dart';
import 'package:app/pages/read/widgets/introduction_section/style.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/comment_section/index.dart';
import 'package:app/components/work_about_section/index.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:app/stores/user_information.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:app/config/color_config.dart';

const _preview_dir = String.fromEnvironment('READ_HERO_PREVIEW_DIR');

/// 图片占位骨架持续动画，有限帧只等待局部避让与尺寸观察器完成当前布局。
Future<void> _settle_layout(WidgetTester tester) async {
  for (var frame = 0; frame < 6; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
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
  status_text: language == 'zh' ? '已完结' : 'Completed',
  title: language == 'zh'
      ? '在遥远世界寻找最后一缕晨光的漫长旅途'
      : 'The Extraordinary Journey Across the World Beyond the Last Morning Star '
            'and the Forgotten Kingdom Where Every Promise Begins Again',
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
    (const Size(320, 844), 'en', 2.0),
    (const Size(320, 844), 'zh', 2.0),
    (const Size(390, 844), 'en', 1.0),
    (const Size(390, 844), 'zh', 2.0),
    (const Size(466, 678), 'en', 1.6),
    (const Size(951, 669), 'en', 1.6),
  ]) {
    testWidgets(
      '小说简介 ${scenario.$1} ${scenario.$2} ${scenario.$3}x 始终左右排版且完整长标题与正文锚点稳定',
      (tester) async {
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
        await _settle_layout(tester);
        Rect bounds(String key) => tester.getRect(find.byKey(ValueKey(key)));
        void verify_geometry() {
          final hero = bounds('novel_introduction_hero');
          final panel = bounds('novel_introduction_content_panel');
          final layout = bounds('novel_introduction_layout');
          expect(panel.top, closeTo(hero.bottom, 0.01));
          final poster = bounds('work_introduction_poster');
          final surface = bounds('work_introduction_surface');
          final cover = bounds('work_introduction_cover');
          final title = bounds('novel_hero_title');
          final metadata = bounds('work_introduction_metadata');
          // 包括320dp窄屏与两倍字号，封面和完整信息组保持底部对齐的左右结构。
          expect(title.top, greaterThanOrEqualTo(poster.top));
          expect(title.bottom, lessThanOrEqualTo(poster.bottom));
          expect(
            tester
                .widget<TitleWithStoryId>(
                  find.byKey(const ValueKey('novel_hero_title')),
                )
                .title_style
                .color,
            ColorConstants.whiteColor,
          );
          expect(cover.width / cover.height, closeTo(2 / 3, 0.001));
          final status = bounds('novel_hero_status');
          expect(status.top, closeTo(cover.top + 6, 0.01));
          expect(status.right, closeTo(cover.right - 6, 0.01));
          expect(status.bottom, lessThanOrEqualTo(cover.bottom));
          expect(
            find.descendant(
              of: find.byKey(const ValueKey('novel_hero_author')),
              matching: find.byKey(const ValueKey('novel_hero_status')),
            ),
            findsNothing,
          );
          expect(
            find.byKey(const ValueKey('work_introduction_panel')),
            findsNothing,
          );
          expect(metadata.bottom, closeTo(cover.bottom, 0.01));
          expect(metadata.left, greaterThan(cover.right));
          expect(title.left, greaterThan(cover.right));
          expect(title.right, lessThanOrEqualTo(poster.right));
          final title_widget = tester.widget<TitleWithStoryId>(
            find.byKey(const ValueKey('novel_hero_title')),
          );
          expect(title_widget.max_lines, isNull);
          final title_paragraph = tester.renderObject<RenderParagraph>(
            find
                .descendant(
                  of: find.byKey(const ValueKey('novel_hero_title')),
                  matching: find.byType(RichText),
                )
                .first,
          );
          expect(title_paragraph.didExceedMaxLines, isFalse);
          final stats = bounds('work_introduction_overflow');
          expect(stats.top, greaterThan(metadata.bottom));
          expect(stats.top, greaterThan(cover.bottom));
          expect(
            bounds('work_introduction_actions').top,
            greaterThan(stats.bottom),
          );
          expect(
            surface.top,
            closeTo(
              poster.bottom - IntroductionStyle.content_panel_overlap,
              0.01,
            ),
          );
          expect(panel.bottom, closeTo(layout.bottom, 0.01));
          expect(bounds('reading_anchor').top, closeTo(panel.bottom, 0.01));
          expect(panel.width, size.width);
          expect(bounds('novel_hero_cover').bottom, lessThan(panel.top));
          expect(
            find.descendant(
              of: find.byKey(
                const ValueKey('novel_introduction_content_panel'),
              ),
              matching: find.byType(WorkAboutSection),
            ),
            findsOneWidget,
          );
          // 分类位于海报统计下方，简介位于内容面板中，展开只推移面板后续内容。
          final about = find.byType(ExpandableSynopsis);
          final genres = find.byType(WorkGenresSection);
          expect(
            tester.getTopLeft(genres).dy,
            lessThan(tester.getTopLeft(about).dy),
          );
          expect(
            find.descendant(
              of: find.byKey(
                const ValueKey('novel_introduction_content_panel'),
              ),
              matching: find.byType(ReadCommentSection),
            ),
            findsOneWidget,
          );
        }

        verify_geometry();
        // 三种作品详情共用两行预览；用真实字号、语种和行宽核对自然文字高度。
        final description_finder = find.text(_detail(scenario.$2).intro_text);
        final description_text = tester.widget<Text>(description_finder);
        final description_context = tester.element(description_finder);
        final painter = TextPainter(
          text: TextSpan(
            text: description_text.data,
            style: DefaultTextStyle.of(
              description_context,
            ).style.merge(description_text.style),
          ),
          maxLines: 2,
          textDirection: Directionality.of(description_context),
          textScaler: MediaQuery.textScalerOf(description_context),
          locale: Localizations.maybeLocaleOf(description_context),
        )..layout(maxWidth: tester.getSize(description_finder).width);
        expect(
          bounds('novel_about_viewport').height,
          closeTo(painter.height, 0.01),
        );
        painter.dispose();
        final accent = bounds('novel_about_accent');
        final heading = bounds('novel_about_header');
        expect(accent.right, lessThan(heading.left));
        expect(accent.center.dy, closeTo(heading.center.dy, 0.01));
        expect(accent.height, lessThan(heading.height));
        final fade = bounds('novel_about_fade');
        final viewport = bounds('novel_about_viewport');
        final about_bounds = tester.getRect(find.byType(WorkAboutSection));
        expect(about_bounds.left, WorkAboutSectionStyle.horizontal_padding);
        expect(
          about_bounds.right,
          size.width - WorkAboutSectionStyle.horizontal_padding,
        );
        expect(fade.bottom, closeTo(viewport.bottom, 0.01));
        expect(fade.height, lessThan(viewport.height / 4));
        final fade_gradient =
            (tester
                            .widget<DecoratedBox>(
                              find.byKey(const ValueKey('novel_about_fade')),
                            )
                            .decoration
                        as BoxDecoration)
                    .gradient!
                as LinearGradient;
        final panel_surface = tester
            .widget<Material>(
              find.byKey(const ValueKey('novel_introduction_content_panel')),
            )
            .color!;
        expect(fade_gradient.colors.last.withValues(alpha: 1), panel_surface);
        final toggle = find.byKey(const ValueKey('novel_about_toggle'));
        final toggle_container = tester.widget<Container>(
          find.descendant(of: toggle, matching: find.byType(Container)),
        );
        expect(toggle_container.decoration, isNull);
        expect(tester.getSize(toggle), const Size.square(44));
        final svg_finder = find.descendant(
          of: toggle,
          matching: find.byType(SvgPicture),
        );
        expect(
          (tester.widget<SvgPicture>(svg_finder).bytesLoader as SvgAssetLoader)
              .assetName,
          'assets/svg/up.svg',
        );
        expect(tester.getSize(svg_finder), const Size.square(12));
        final rotation = find.descendant(
          of: find.byType(SynopsisToggleButton),
          matching: find.byType(RotationTransition),
        );
        double turns() =>
            tester.widget<RotationTransition>(rotation).turns.value;
        expect(turns(), 0.5);
        if (_preview_dir.isNotEmpty) {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('novel_panel_capture')),
          );
          await tester.runAsync(() async {
            await Directory(_preview_dir).create(recursive: true);
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              '$_preview_dir/panel_${size.width.toInt()}_${scenario.$2}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        expect(find.byType(ExpandableSynopsis), findsOneWidget);
        final header = find.byKey(const ValueKey('novel_about_header'));
        final position = tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position;
        final hero_height_before_scroll = bounds(
          'novel_introduction_hero',
        ).height;
        final anchor_document_top =
            bounds('reading_anchor').top + position.pixels;
        final toggle_size_before_scroll = tester.getSize(
          find.byKey(const ValueKey('novel_about_toggle')),
        );
        await tester.ensureVisible(header);
        await _settle_layout(tester);
        // Hero完全移出视口后，不得撤销局部避让而改变上方高度及后续文档锚点。
        expect(bounds('novel_introduction_hero').bottom, lessThanOrEqualTo(0));
        expect(
          bounds('novel_introduction_hero').height,
          hero_height_before_scroll,
        );
        expect(
          bounds('reading_anchor').top + position.pixels,
          closeTo(anchor_document_top, 0.01),
        );
        // 正文需要局部避让时，已处于系统区下方的展开按钮不得跟随缩窄、换行增高。
        expect(
          tester.getSize(find.byKey(const ValueKey('novel_about_toggle'))),
          toggle_size_before_scroll,
        );
        final header_rect = tester.getRect(header);
        final collapsed_height = bounds('novel_about_viewport').height;
        await tester.tap(header);
        await _settle_layout(tester);
        expect(bounds('novel_about_viewport').height, collapsed_height);
        expect(
          find.byKey(const ValueKey('novel_about_collapse')),
          findsNothing,
        );
        await tester.tap(toggle);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        final expanding_height = bounds('novel_about_viewport').height;
        expect(turns(), greaterThan(0));
        expect(turns(), lessThan(0.5));
        final collapse = find.byKey(const ValueKey('novel_about_collapse'));
        expect(tester.getRect(collapse), header_rect);
        await tester.pump(const Duration(milliseconds: 300));
        final expanded_height = bounds('novel_about_viewport').height;
        expect(expanding_height, greaterThan(collapsed_height));
        expect(expanding_height, lessThan(expanded_height));
        expect(turns(), 0);
        verify_geometry();
        await tester.ensureVisible(toggle);
        await _settle_layout(tester);
        await tester.tap(toggle);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        expect(
          bounds('novel_about_viewport').height,
          greaterThan(collapsed_height),
        );
        expect(
          bounds('novel_about_viewport').height,
          lessThan(expanded_height),
        );
        expect(
          tester
              .widget<Text>(find.text(_detail(scenario.$2).intro_text))
              .maxLines,
          isNull,
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(bounds('novel_about_viewport').height, collapsed_height);
        expect(turns(), 0.5);
        verify_geometry();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
