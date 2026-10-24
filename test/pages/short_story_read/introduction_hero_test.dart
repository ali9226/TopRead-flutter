// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:app/components/window_content_layout/index.dart';
import 'package:app/components/title_with_story_id/index.dart';
import 'package:app/components/work_hero_stats/index.dart';
import 'package:app/components/work_hero_glass_surface/index.dart';
import 'package:app/components/work_introduction_hero/index.dart';
import 'package:app/config/layout_config.dart';
import 'package:app/models/short_story_item.dart';
import 'package:app/models/short_story_read_data.dart';
import 'package:app/pages/short_story_read/widgets/introduction/index.dart';
import 'package:app/pages/short_story_read/widgets/introduction/synopsis.dart';
import 'package:app/stores/user_information.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:app/config/color_config.dart';

class _Assets extends AssetLoader {
  const _Assets();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      Map<String, dynamic>.from(
        jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
            as Map,
      );
}

/// 使用真实翻译和本地图像验证短篇新增卡片，不依赖网络或后端。
Future<void> _mount_introduction_widget(
  WidgetTester tester,
  Widget child, {
  bool dark = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
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
          theme: ThemeData(
            brightness: dark ? Brightness.dark : Brightness.light,
          ),
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
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
    Get.put(UserInformation());
  });
  tearDown(Get.reset);

  for (final show_rating in [false, true]) {
    for (final show_comments in [false, true]) {
      testWidgets('短篇评分$show_rating 评论$show_comments 均由封面玻璃简介替代', (
        tester,
      ) async {
        var favorite_taps = 0;
        var comment_taps = 0;
        await _mount_introduction_widget(
          tester,
          ShortStoryIntroduction(
            detail: const ShortStoryReadData(
              id: 7,
              title: 'A Story Beyond the Last Morning Star',
              introduction:
                  'A traveler returns to a city that has forgotten the morning.',
              novel_language_id: '1',
              score: '9.6',
              read_count: 2000,
              comment_count: 37,
            ),
            is_dark: false,
            show_rating: show_rating,
            show_comments: show_comments,
            cover_image: const ColoredBox(color: ColorConstants.whiteColor),
            backdrop_image: const ColoredBox(color: ColorConstants.whiteColor),
            on_back: () {},
            on_favorite: () => favorite_taps++,
            on_comment: () => comment_taps++,
          ),
        );
        expect(find.byIcon(Icons.star_rounded), findsNothing);
        expect(find.text('9.6'), findsNothing);
        expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsNothing);
        expect(find.text('37'), findsNothing);
        expect(find.byIcon(Icons.local_fire_department_rounded), findsNothing);
        expect(find.byType(WorkHeroStatsRow), findsNothing);
        expect(find.byType(ShortStorySynopsis), findsOneWidget);
        expect(find.byType(WorkHeroGlassSurface), findsOneWidget);
        expect(
          find.text(
            'A traveler returns to a city that has forgotten the morning.',
          ),
          findsOneWidget,
        );
        expect(comment_taps, 0);
        final favorite = find.byIcon(Icons.favorite_border_rounded);
        await tester.ensureVisible(favorite);
        await tester.tap(favorite);
        expect(favorite_taps, 1);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('短篇空简介不生成磨砂框及多余槽位，原统计也不保留', (tester) async {
    await _mount_introduction_widget(
      tester,
      ShortStoryIntroduction(
        detail: const ShortStoryReadData(
          id: 7,
          title: 'A Story',
          introduction: '',
          novel_language_id: '1',
          score: '  ',
          read_count: 23,
        ),
        is_dark: false,
        show_comments: false,
        cover_image: const ColoredBox(color: ColorConstants.whiteColor),
        backdrop_image: const ColoredBox(color: ColorConstants.whiteColor),
        on_back: () {},
        on_favorite: () {},
      ),
    );
    expect(find.byIcon(Icons.star_rounded), findsNothing);
    expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsNothing);
    expect(find.text('23'), findsNothing);
    expect(find.byType(WorkHeroStatsRow), findsNothing);
    expect(find.byType(ShortStorySynopsis), findsNothing);
    expect(find.byType(WorkHeroGlassSurface), findsNothing);
    expect(
      tester
          .widget<WorkIntroductionHero>(find.byType(WorkIntroductionHero))
          .overflow_builder,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    testWidgets('短篇简介昼夜主题$dark 可展开并在空文本时消失', (tester) async {
      const description =
          'A traveler returns to a city that has forgotten the morning. '
          'Every street leads to a different promise, and every door holds a memory. '
          'Beyond the harbor, a new journey begins beneath the last remaining star. '
          'A traveler returns to a city that has forgotten the morning. '
          'Every street leads to a different promise, and every door holds a memory.';
      final text = ValueNotifier(description);
      addTearDown(text.dispose);
      await _mount_introduction_widget(
        tester,
        Padding(
          padding: const EdgeInsets.all(24),
          child: ValueListenableBuilder<String>(
            valueListenable: text,
            builder: (_, value, _) =>
                ShortStorySynopsis(description: value, is_dark: dark),
          ),
        ),
        dark: dark,
      );
      final synopsis = find.byType(ShortStorySynopsis);
      final card = tester.widget<WorkHeroGlassSurface>(
        find.byType(WorkHeroGlassSurface),
      );
      expect(card.is_dark, dark);
      expect(find.text(description), findsOneWidget);
      final collapsed_height = tester.getSize(synopsis).height;
      await tester.tap(find.byKey(const ValueKey('short_story_about_toggle')));
      await tester.pumpAndSettle();
      expect(tester.getSize(synopsis).height, greaterThan(collapsed_height));
      final expanded_height = tester.getSize(synopsis).height;
      await tester.tap(find.byKey(const ValueKey('short_story_about_header')));
      await tester.tap(find.text(description));
      await tester.pumpAndSettle();
      expect(tester.getSize(synopsis).height, expanded_height);
      await tester.tap(find.byKey(const ValueKey('short_story_about_toggle')));
      await tester.pumpAndSettle();
      expect(tester.getSize(synopsis).height, collapsed_height);
      text.value = '   ';
      await tester.pumpAndSettle();
      expect(find.byType(WorkHeroGlassSurface), findsNothing);
      expect(tester.getSize(synopsis).height, 0);
      expect(tester.takeException(), isNull);
    });
  }

  for (final scenario in [
    (const Size(466, 678), 'zh', false),
    (const Size(466, 678), 'en', true),
    (const Size(951, 669), 'en', false),
    (const Size(320, 568), 'en', true),
  ]) {
    testWidgets('短篇共享海报 ${scenario.$1} ${scenario.$2} 完整长标题与正文独立布局', (
      tester,
    ) async {
      final (size, language, dark) = scenario;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final detail = ShortStoryReadData(
        id: 7,
        title: language == 'zh'
            ? '在群星闪耀的遥远世界寻找最后一缕晨光并重逢所有迷路灵魂的漫长旅途'
            : 'The Extraordinary Journey Across the World Beyond the Last Morning Star and Every Forgotten Promise',
        introduction: '',
        novel_language_id: '1',
        read_count: 120000,
        comment_count: 100,
        score: '9.6',
      );
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
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: const TextScaler.linear(1.6),
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
                    body: WindowContentLayout(
                      child: SingleChildScrollView(
                        controller: scroll,
                        child: Column(
                          children: [
                            ShortStoryIntroduction(
                              detail: detail,
                              is_dark: dark,
                              catalog_entries: [
                                ShortStoryItem(
                                  id: 7,
                                  title: detail.title,
                                  description: '',
                                  author_name: 'A Storyteller',
                                  tags: const [],
                                  like_count: 0,
                                ),
                              ],
                              cover_image: const ColoredBox(
                                color: Colors.amber,
                              ),
                              backdrop_image: const ColoredBox(
                                color: Colors.blueGrey,
                              ),
                              on_back: () {},
                              on_share: () {},
                              on_favorite: () {},
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    LayoutConfig.page_horizontal_padding,
                              ),
                              child: SizedBox(
                                key: ValueKey('reading_body'),
                                width: double.infinity,
                                height: 2000,
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
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final poster = tester.getRect(
        find.byKey(const ValueKey('work_introduction_poster')),
      );
      final title = tester.getRect(
        find.byKey(const ValueKey('short_story_introduction_title')),
      );
      final author_style = tester
          .widget<Text>(
            find.byKey(const ValueKey('short_story_introduction_author')),
          )
          .style!;
      final title_style = tester
          .widget<TitleWithStoryId>(
            find.byKey(const ValueKey('short_story_introduction_title')),
          )
          .title_style;
      expect(title_style.shadows, isNotEmpty);
      expect(author_style.shadows, title_style.shadows);
      final cover = tester.getRect(
        find.byKey(const ValueKey('work_introduction_cover')),
      );
      expect(poster.width, size.width);
      expect(poster.height, greaterThan(0));
      final panel = find.byKey(const ValueKey('work_introduction_panel'));
      if (panel.evaluate().isNotEmpty) {
        expect(title.top, greaterThanOrEqualTo(cover.bottom));
      } else {
        expect(title.left, greaterThanOrEqualTo(cover.right));
        expect(title.bottom, lessThanOrEqualTo(poster.bottom));
      }
      expect(title.width, greaterThan(cover.width));
      expect(find.text(detail.title), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const ValueKey('reading_body'))).width,
        size.width - LayoutConfig.page_horizontal_padding * 2,
      );
      if (size.width == 466 && language == 'en') {
        // 标题随滚动进入右上局部系统区时继续避让；正文不损失整列宽度。
        scroll.jumpTo(title.top);
        await tester.pumpAndSettle();
        final scrolled_title = tester.getRect(
          find.byKey(const ValueKey('short_story_introduction_title')),
        );
        expect(scrolled_title.right, lessThanOrEqualTo(size.width - 84));
        expect(tester.takeException(), isNull);
      }
    });
  }
}
