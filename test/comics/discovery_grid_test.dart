import 'dart:convert';
import 'dart:io';

import 'package:app/models/comics.dart';
import 'package:app/models/comics_discovery.dart';
import 'package:app/pages/comics/widgets/discovery_grid/index.dart';
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

ComicItem _comic(int id) => ComicItem.from_json({
  'id': id,
  'title': '星空下的漫长旅途 A Very Long Journey Through the Distant Stars $id',
  'cover_url': '',
  'categories': [
    {
      'id': 1,
      'name': 'Action',
      'translations': {'en': 'Action', 'zh': '战斗'},
    },
    {
      'id': 2,
      'name': 'Adventure',
      'translations': {'en': 'Adventure', 'zh': '冒险'},
    },
  ],
});

Future<void> _mount(
  WidgetTester tester, {
  required Size size,
  required String language,
  required bool dark,
  required double scale,
  required Widget child,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
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
              textScaler: TextScaler.linear(scale),
            ),
            child: Scaffold(body: child),
          ),
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

  test('分组保留服务端排序，不把空分类、重复漫画或非法记录渲染成推荐', () {
    final feed = ComicDiscoveryFeed.from_json({
      'seed': 'snapshot-1',
      'list': [
        {
          'category': {'id': 9, 'name': 'Action'},
          'total': '10',
          'list': [
            null,
            {'id': 0},
            for (var i = 1; i <= 8; i++) {'id': i},
            {'id': 1},
          ],
        },
        {
          'category': {'id': 10},
          'list': [],
        },
        {
          'category': {'id': 9},
          'list': [
            {'id': 20},
          ],
        },
        {
          'category': {'id': 3},
          'list': [
            {'id': 15},
            {'id': 15},
          ],
        },
      ],
    });
    expect(feed.sections.map((section) => section.id), [9, 3]);
    expect(feed.sections.first.items.map((item) => item.id), [
      1,
      2,
      3,
      4,
      5,
      6,
    ]);
    expect(feed.sections.last.items.map((item) => item.id), [15]);
    expect(feed.categories.map((category) => category['id']), [9, 3]);
    expect(feed.seed, 'snapshot-1');
    expect(feed.sections.first.total, 10);
  });

  test('分类分页与换批保留服务端种子和游标，非法列表安全回退', () {
    final page = ComicDiscoveryPage.from_json({
      'list': [
        {'id': '8'},
        {'id': 8},
        'bad',
      ],
      'total': '30',
      'page': 2,
      'page_size': '24',
      'seed': 'stable',
    });
    expect(page.items.single.id, 8);
    expect(
      (page.total, page.page, page.page_size, page.seed),
      (30, 2, 24, 'stable'),
    );
    expect(ComicDiscoveryFeed.from_json({'list': false}).sections, isEmpty);
  });

  for (final size in const [Size(320, 844), Size(844, 390), Size(951, 669)]) {
    for (final language in ['zh', 'en']) {
      for (final dark in [false, true]) {
        testWidgets('六本封面网格 $size $language dark=$dark 大字号保持整齐完整点击区域', (
          tester,
        ) async {
          int? opened;
          await _mount(
            tester,
            size: size,
            language: language,
            dark: dark,
            scale: 1.8,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ComicDiscoveryGrid(
                  items: List.generate(6, (i) => _comic(i + 1)),
                  on_open: (item) => opened = item.id,
                ),
              ),
            ),
          );
          final first = tester.getRect(
            find.byKey(const ValueKey('comic_discovery_card_1')),
          );
          final fourth = tester.getRect(
            find.byKey(const ValueKey('comic_discovery_card_4')),
          );
          if (size.width < 680) {
            expect(fourth.top, greaterThan(first.bottom));
            expect(fourth.left, closeTo(first.left, .1));
          } else {
            expect(fourth.top, closeTo(first.top, .1));
          }
          final cover = tester.getRect(
            find.descendant(
              of: find.byKey(const ValueKey('comic_discovery_card_1')),
              matching: find.byType(AspectRatio),
            ),
          );
          expect(cover.width / cover.height, closeTo(2 / 3, .001));
          expect(find.byType(ComicDiscoveryCard), findsNWidgets(6));
          await tester.tapAt(cover.center);
          expect(opened, 1);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('分类千本列表采用Sliver惰性构建，滚动持续访问后续书目', (tester) async {
    await _mount(
      tester,
      size: const Size(390, 844),
      language: 'en',
      dark: false,
      scale: 1,
      child: CustomScrollView(
        slivers: [
          ComicDiscoverySliverGrid(
            items: List.generate(1000, (i) => _comic(i + 1)),
          ),
        ],
      ),
    );
    expect(find.byType(ComicDiscoveryCard).evaluate().length, lessThan(30));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1500));
    await tester.pumpAndSettle();
    expect(find.byType(ComicDiscoveryCard).evaluate().length, lessThan(30));
    expect(
      tester
          .widgetList<ComicDiscoveryCard>(find.byType(ComicDiscoveryCard))
          .last
          .comic
          .id,
      greaterThan(15),
    );
    expect(tester.takeException(), isNull);
  });
}
