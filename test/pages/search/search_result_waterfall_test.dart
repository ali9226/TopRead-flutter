// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:app/components/app_wrapper/utils/app_router.dart';
import 'package:app/components/recommend_book_card/index.dart';
import 'package:app/components/window_content_layout/index.dart';
import 'package:app/models/comics.dart';
import 'package:app/models/recommend_ranking_item.dart';
import 'package:app/models/work_search.dart';
import 'package:app/pages/comics/widgets/comic_card.dart';
import 'package:app/pages/search/widgets/search_result_card.dart';
import 'package:app/pages/search/widgets/search_result_waterfall.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// 读取实际翻译文件，确保类型标签在较长语种下也能完整布局。
class _Assets extends AssetLoader {
  const _Assets();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      Map<String, dynamic>.from(
        jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
            as Map,
      );
}

RecommendRankingItem _novel(int id, {int status = 1}) =>
    RecommendRankingItem.from_json({
      'id': id,
      'title': '小说 Novel $id: A Journey Through the Distant Stars & Beyond',
      'publish_status': status,
      'cover_url': '',
      'cover_width': 600,
      'cover_height': 900,
      'introduction':
          '长篇简介 A long description that wraps across several '
          'lines at an accessible font size.',
      'category_list': ['Adventure through distant worlds', '奇幻冒险'],
    });

ComicItem _comic(int id) => ComicItem.from_json({
  'id': id,
  'title': '漫画 Comic $id: A Long Illustrated Journey Through the Universe',
  'cover_url': '',
  'description':
      '漫画简介 Illustrated adventures with a lengthy description '
      'that should wrap naturally.',
  'chapter_count': 12,
  'categories': [
    {
      'id': 1,
      'name': 'Adventure through distant worlds',
      'translations': {
        'en': 'Adventure through distant worlds',
        'zh': '遥远世界的奇幻冒险',
        'fr': 'Aventures dans des mondes lointains',
      },
    },
    {'id': 2, 'name': 'Fantasy'},
  ],
});

/// 同号的小说与漫画交错排列，模拟来自两个独立数据源的实际搜索结果。
List<SearchResultItem> _items() => [
  SearchResultItem.novel(_novel(1)),
  SearchResultItem.comic(_comic(1)),
  SearchResultItem.novel(_novel(2, status: 4)),
  SearchResultItem.comic(_comic(2)),
  SearchResultItem.novel(_novel(3, status: 2)),
  SearchResultItem.comic(_comic(3)),
];

Future<GoRouter> _mount(
  WidgetTester tester, {
  required List<SearchResultItem> items,
  Size size = const Size(390, 844),
  String language = 'en',
  bool dark = false,
  double scale = 1,
  bool duo = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(scale),
              padding: EdgeInsets.only(right: duo ? 84 : 0),
              viewPadding: EdgeInsets.only(right: duo ? 84 : 0),
              displayFeatures: duo
                  ? [
                      ui.DisplayFeature(
                        bounds: Rect.fromLTWH(size.width - 84, 0, 84, 124),
                        type: ui.DisplayFeatureType.cutout,
                        state: ui.DisplayFeatureState.unknown,
                      ),
                    ]
                  : [],
            ),
            child: WindowLayoutScope(
              child: WindowContentLayout(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SearchResultWaterfall(items: items, is_dark: dark),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      for (final path in ['/read', '/short_story_read', '/comics/detail'])
        GoRoute(
          path: path,
          builder: (_, state) => Scaffold(body: Text(state.uri.toString())),
        ),
    ],
  );
  AppRouter.setRouter(router);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: [Locale(language)],
      startLocale: Locale(language),
      fallbackLocale: Locale(language),
      path: 'assets/i18n',
      saveLocale: false,
      assetLoader: const _Assets(),
      child: Builder(
        builder: (context) => MaterialApp.router(
          routerConfig: router,
          locale: context.locale,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          theme: ThemeData(
            brightness: dark ? Brightness.dark : Brightness.light,
          ),
        ),
      ),
    ),
  );
  // 瀑布流的真实高度通过两轮 post-frame 测量稳定后再检查几何位置。
  await tester.pumpAndSettle();
  await tester.pump();
  await tester.pumpAndSettle();
  return router;
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

  for (final config in [
    (size: const Size(320, 844), locale: 'zh', dark: false, duo: false),
    (size: const Size(320, 844), locale: 'en', dark: true, duo: false),
    (size: const Size(844, 390), locale: 'fr', dark: false, duo: false),
    (size: const Size(951, 669), locale: 'zh', dark: true, duo: true),
    (size: const Size(466, 678), locale: 'en', dark: false, duo: true),
  ]) {
    testWidgets('同号小说漫画均显示类型，2倍字号无溢出或卡片重叠 ${config.size} '
        '${config.locale} dark=${config.dark} duo=${config.duo}', (
      tester,
    ) async {
      final items = _items();
      await _mount(
        tester,
        items: items,
        size: config.size,
        language: config.locale,
        dark: config.dark,
        scale: 2,
        duo: config.duo,
      );

      expect(find.byType(RecommendBookCard), findsNWidgets(3));
      expect(find.byType(ComicCard), findsNWidgets(3));
      expect(find.byType(SearchResultCard), findsNWidgets(items.length));
      final translations =
          jsonDecode(
                File('assets/i18n/${config.locale}.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      final labels = translations['search'] as Map<String, dynamic>;
      expect(find.text(labels['type_novel'] as String), findsNWidgets(3));
      expect(find.text(labels['type_comic'] as String), findsNWidgets(3));

      final waterfall_rect = tester.getRect(find.byType(SearchResultWaterfall));
      final cards = find.byType(SearchResultCard).evaluate().map((element) {
        final box = element.renderObject! as RenderBox;
        return box.localToGlobal(Offset.zero) & box.size;
      }).toList();
      for (var index = 0; index < cards.length; index++) {
        final card = cards[index];
        expect(card.width, greaterThan(0));
        expect(card.height, greaterThan(0));
        expect(card.left, greaterThanOrEqualTo(waterfall_rect.left - 0.1));
        expect(card.right, lessThanOrEqualTo(waterfall_rect.right + 0.1));
        expect(card.bottom, lessThanOrEqualTo(waterfall_rect.bottom + 0.1));
        for (final following in cards.skip(index + 1)) {
          expect(card.overlaps(following), isFalse);
        }
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('结果默认点击分别打开漫画、普通小说与短篇小说并保留标题编码', (tester) async {
    final novel = _novel(1);
    final short_story = _novel(2, status: 4);
    final router = await _mount(
      tester,
      items: [
        SearchResultItem.novel(novel),
        SearchResultItem.comic(_comic(1)),
        SearchResultItem.novel(short_story),
      ],
      size: const Size(844, 670),
    );

    await tester.tap(find.byType(ComicCard));
    await tester.pumpAndSettle();
    expect(AppRouter.currentLocation(), '/comics/detail?id=1');
    router.pop();
    await tester.pumpAndSettle();

    final regular_card = find.byWidgetPredicate(
      (widget) => widget is RecommendBookCard && widget.item.story_id == 1,
    );
    await tester.tap(regular_card);
    await tester.pumpAndSettle();
    final novel_uri = Uri.parse(AppRouter.currentLocation());
    expect(novel_uri.path, '/read');
    expect(novel_uri.queryParameters, {'id': '1', 'title': novel.title});
    router.pop();
    await tester.pumpAndSettle();

    final short_card = find.byWidgetPredicate(
      (widget) => widget is RecommendBookCard && widget.item.story_id == 2,
    );
    await tester.ensureVisible(short_card);
    await tester.tap(short_card);
    await tester.pumpAndSettle();
    expect(AppRouter.currentLocation(), '/short_story_read?id=2');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
