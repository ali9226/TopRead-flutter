import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:app/components/category_filter/index.dart';
import 'package:app/components/floating_back_to_top/index.dart';
import 'package:app/components/window_content_layout/index.dart';
import 'package:app/models/comics_discovery.dart';
import 'package:app/models/user_info.dart';
import 'package:app/pages/comics/widgets/discovery_grid/index.dart';
import 'package:app/pages/comics/widgets/empty_state.dart';
import 'package:app/pages/home/widgets/tab_contents/comics_tab/index.dart';
import 'package:app/pages/home/widgets/tab_contents/comics_tab/logic.dart';
import 'package:app/pages/home/widgets/tab_contents/comics_tab/section.dart';
import 'package:app/pages/home/widgets/tab_contents/comics_tab/skeleton.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/services/recommendation_refresh/index.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
// FileInfo使用缓存管理器已依赖的File接口，测试仅将本地封面适配为该接口。
// ignore: depend_on_referenced_packages
import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'fixtures.dart';

const _preview_dir = String.fromEnvironment('COMICS_HOME_PREVIEW_DIR');
final _cover_files = <String, File>{};

class _LocalCovers implements BaseCacheManager {
  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) async* {
    final file = _cover_files[url];
    if (file == null) return;
    yield FileInfo(
      const LocalFileSystem().file(file.path),
      FileSource.Cache,
      DateTime.now().add(const Duration(days: 1)),
      url,
    );
  }

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

Future<void> _mount(
  WidgetTester tester,
  ComicsTabLogic logic, {
  Size size = const Size(390, 844),
  String language = 'en',
  bool dark = false,
  double scale = 1,
  bool cutout = false,
  bool reduce_motion = false,
  ValueChanged<int>? on_more,
  ValueChanged<int>? on_open,
  bool tabs = false,
  bool is_active = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  final page = ComicsTabContent(
    controller: logic,
    is_active: is_active,
    on_more: on_more,
    on_open: (comic) => on_open?.call(comic.id),
  );
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('zh')],
      startLocale: Locale(language),
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
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(scale),
              disableAnimations: reduce_motion,
              padding: EdgeInsets.only(
                top: 32,
                bottom: 34,
                right: cutout ? 84 : 0,
              ),
              viewPadding: EdgeInsets.only(
                top: 32,
                bottom: 34,
                right: cutout ? 84 : 0,
              ),
              displayFeatures: cutout
                  ? [
                      ui.DisplayFeature(
                        bounds: Rect.fromLTWH(size.width - 84, 0, 84, 124),
                        type: ui.DisplayFeatureType.cutout,
                        state: ui.DisplayFeatureState.unknown,
                      ),
                    ]
                  : const [],
            ),
            child: WindowLayoutScope(
              child: RepaintBoundary(
                key: const ValueKey('comics_home_capture'),
                child: Scaffold(
                  body: WindowContentLayout(
                    child: tabs
                        ? DefaultTabController(
                            length: 2,
                            child: TabBarView(
                              children: [page, const SizedBox.expand()],
                            ),
                          )
                        : page,
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
  await tester.pump(const Duration(milliseconds: 400));
}

ComicDiscoveryFeed _feed({int groups = 12, bool real_covers = false}) =>
    discovery_feed(
      List.generate(groups, (index) {
        return discovery_section(
          index + 1,
          first_id: index * 10 + 1,
          cover_urls: real_covers
              ? List.generate(
                  6,
                  (item) => 'https://fixtures.invalid/cover-$item.webp',
                )
              : const [],
        );
      }),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (_) async => <String, Object>{},
        );
    await EasyLocalization.ensureInitialized();
    if (_preview_dir.isNotEmpty) {
      final root = Directory('/Users/ali/work/小说/后端/test/mangaberri漫画/数据/漫画');
      final files =
          root
              .listSync()
              .whereType<Directory>()
              .map((dir) => File('${dir.path}/cover.webp'))
              .where((file) => file.existsSync())
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));
      for (var index = 0; index < 6; index++) {
        _cover_files['https://fixtures.invalid/cover-$index.webp'] =
            files[index];
      }
      CachedNetworkImageProvider.defaultCacheManager = _LocalCovers();
      for (final name in ['Roboto', 'Georgia']) {
        final font = File(
          '/System/Library/Fonts/Supplemental/Arial Unicode.ttf',
        );
        if (font.existsSync()) {
          await (FontLoader(name)..addFont(
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
    Get.put(UserInformation());
  });
  tearDown(Get.reset);

  testWidgets('相邻Tab尚未请求时直接展示骨架，激活慢请求也不闪空态，成功空才展示无数据', (tester) async {
    final response = Completer<ComicDiscoveryFeed>();
    var requests = 0;
    final logic = ComicsTabLogic(
      home_loader: ({language, seed}) {
        requests++;
        return response.future;
      },
    );
    await _mount(tester, logic, is_active: false);
    expect(requests, 0, reason: '预构建页面显示骨架，不提前请求不可见Tab');
    expect(find.byType(ComicsHomeSectionsSkeleton), findsOneWidget);
    expect(find.byType(ComicsEmptyState), findsNothing);
    await _mount(tester, logic, is_active: true);
    expect(requests, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(ComicsHomeSectionsSkeleton), findsOneWidget);
    expect(find.byType(ComicsEmptyState), findsNothing);
    response.complete(discovery_feed([]));
    await tester.pump();
    expect(find.byType(ComicsHomeSectionsSkeleton), findsNothing);
    expect(find.byType(ComicsEmptyState), findsOneWidget);
    await _mount(tester, logic, is_active: false);
    expect(find.byType(ComicsEmptyState), findsOneWidget);
    expect(requests, 1, reason: '已确认的真实空结果可复用');
    await tester.pumpWidget(const SizedBox.shrink());
    logic.dispose();
  });

  testWidgets('首次请求失败仍展示重试错误，不会被未加载骨架遮住', (tester) async {
    final response = Completer<ComicDiscoveryFeed>();
    final logic = ComicsTabLogic(
      home_loader: ({language, seed}) => response.future,
    );
    await _mount(tester, logic);
    response.completeError(StateError('offline'));
    await tester.pump();
    expect(find.byType(ComicsHomeSectionsSkeleton), findsNothing);
    expect(find.byType(ComicsEmptyState), findsOneWidget);
    expect(logic.error, contains('offline'));
    await tester.pumpWidget(const SizedBox.shrink());
    logic.dispose();
  });

  testWidgets('未激活首页Tab不请求，隐藏期间行为合并为激活后的新首屏', (tester) async {
    var requests = 0;
    final seeds = <String?>[];
    final logic = ComicsTabLogic(
      home_loader: ({language, seed}) async {
        requests++;
        seeds.add(seed);
        return _feed(groups: 2);
      },
    );
    addTearDown(logic.dispose);
    await _mount(tester, logic, is_active: false);
    expect(requests, 0);
    await _mount(tester, logic, is_active: true);
    expect(requests, 1);
    await _mount(tester, logic, is_active: false);
    for (var index = 0; index < 8; index++) {
      RecommendationRefreshSignals.instance.record_success(
        'novel_favorite/click',
      );
    }
    await tester.pump(const Duration(seconds: 2));
    expect(requests, 1);
    await _mount(tester, logic, is_active: true);
    await tester.pumpAndSettle();
    expect(requests, 2);
    expect(seeds, everyElement(isNull));
    expect(tester.takeException(), isNull);
  });

  testWidgets('首页移除筛选、按真实分组懒构建，更多与封面点击保留分类/作品身份', (tester) async {
    final logic = ComicsTabLogic(
      home_loader: ({language, seed}) async => _feed(),
    );
    addTearDown(logic.dispose);
    int? more;
    int? opened;
    await _mount(
      tester,
      logic,
      on_more: (id) => more = id,
      on_open: (id) => opened = id,
    );
    expect(find.byType(CategoryFilter), findsNothing);
    expect(find.byType(ComicsHomeSection).evaluate().length, lessThan(12));
    expect(find.byType(ComicDiscoveryCard).evaluate().length, lessThan(72));
    expect(find.byKey(const ValueKey('comics_home_heading_1')), findsOneWidget);
    expect(find.byKey(const ValueKey('comics_home_heading_12')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('comic_discovery_card_1')));
    expect(opened, 1);
    await tester.tap(find.byKey(const ValueKey('comics_home_more_1')));
    expect(more, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('单组换批按钮独立加载并防连点，完成后自然交叉淡入且其他组保持', (tester) async {
    final pending = Completer<ComicDiscoverySection>();
    var requests = 0;
    final logic = ComicsTabLogic(
      home_loader: ({language, seed}) async => _feed(groups: 3),
      category_loader:
          ({
            required category_id,
            required exclude_ids,
            reserved_ids,
            language,
            seed,
          }) {
            requests++;
            return pending.future;
          },
    );
    addTearDown(logic.dispose);
    await _mount(tester, logic, size: const Size(951, 900));
    final second = tester.element(
      find.byKey(const ValueKey('comic_discovery_card_11')),
    );
    final shuffle = find.byKey(const ValueKey('comics_home_shuffle_1'));
    await tester.tap(shuffle);
    await tester.pump();
    await tester.tap(shuffle);
    expect(requests, 1);
    expect(
      find.byKey(const ValueKey('comic_discovery_card_1')),
      findsOneWidget,
    );
    expect(logic.is_shuffling(2), isFalse);
    pending.complete(discovery_section(1, first_id: 100));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final section = find.byKey(const ValueKey('comics_home_section_1'));
    expect(
      find.descendant(of: section, matching: find.byType(ComicDiscoveryGrid)),
      findsNWidgets(2),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('comic_discovery_card_1')), findsNothing);
    expect(
      find.byKey(const ValueKey('comic_discovery_card_100')),
      findsOneWidget,
    );
    expect(
      tester.element(find.byKey(const ValueKey('comic_discovery_card_11'))),
      same(second),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('单组失败保留封面并在本组显示重试提示，其他组保持可操作', (tester) async {
    var fail = true;
    final logic = ComicsTabLogic(
      home_loader: ({language, seed}) async => _feed(groups: 2),
      category_loader:
          ({
            required category_id,
            required exclude_ids,
            reserved_ids,
            language,
            seed,
          }) async {
            if (fail) throw StateError('offline');
            return discovery_section(category_id, first_id: 100);
          },
    );
    addTearDown(logic.dispose);
    await _mount(tester, logic, size: const Size(951, 900));
    final first = tester.element(
      find.byKey(const ValueKey('comic_discovery_card_1')),
    );
    await tester.tap(find.byKey(const ValueKey('comics_home_shuffle_1')));
    await tester.pumpAndSettle();
    expect(
      tester.element(find.byKey(const ValueKey('comic_discovery_card_1'))),
      same(first),
    );
    expect(
      find.byKey(const ValueKey('comics_home_shuffle_error_1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('comics_home_shuffle_error_2')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('comics_home_more_2')).hitTestable(),
      findsOneWidget,
    );
    fail = false;
    await tester.tap(find.byKey(const ValueKey('comics_home_shuffle_1')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('comics_home_shuffle_error_1')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('comic_discovery_card_100')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('下拉刷新全部分组并保留刷新前内容，账号和语种切换请求新的个性化列表', (tester) async {
    final pending = Completer<ComicDiscoveryFeed>();
    final languages = <String?>[];
    var requests = 0;
    final logic = ComicsTabLogic(
      home_loader: ({language, seed}) {
        languages.add(language);
        requests++;
        return requests == 2 ? pending.future : Future.value(_feed(groups: 2));
      },
    );
    addTearDown(logic.dispose);
    await _mount(tester, logic);
    await tester.dragFrom(const Offset(180, 12), const Offset(0, 600));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(requests, 2);
    expect(
      find.byKey(const ValueKey('comic_discovery_card_1')),
      findsOneWidget,
    );
    pending.complete(_feed(groups: 3));
    await tester.pumpAndSettle();
    expect(logic.sections, hasLength(3));
    final user = Get.find<UserInformation>();
    user.saveUserInfo(UserInfo.fromJson({'id': 15, 'name': 'Reader'}));
    await tester.pumpAndSettle();
    expect(requests, 3);
    user.saveUserInfo(UserInfo.fromJson({'id': 15, 'name': 'Renamed'}));
    await tester.pumpAndSettle();
    expect(requests, 3);
    user.clearUserInfo();
    await tester.pumpAndSettle();
    expect(requests, 4);
    await tester
        .element(find.byType(ComicsTabContent))
        .setLocale(const Locale('zh'));
    await tester.pumpAndSettle();
    expect(languages.last, 'zh');
    expect(requests, 5);
    expect(tester.takeException(), isNull);
  });

  testWidgets('切换首页Tab后保留原滚动位置和回顶入口，回顶遵循减少动画', (tester) async {
    final logic = ComicsTabLogic(
      home_loader: ({language, seed}) async => _feed(),
    );
    addTearDown(logic.dispose);
    await _mount(tester, logic, tabs: true, reduce_motion: true);
    final scroll = tester
        .state<ScrollableState>(
          find
              .descendant(
                of: find.byKey(
                  const PageStorageKey('comics_home_sections_scroll'),
                ),
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position;
    scroll.jumpTo(1000);
    await tester.pumpAndSettle();
    final before = scroll.pixels;
    final state = tester.state(find.byType(ComicsTabContent));
    final tabs = DefaultTabController.of(
      tester.element(find.byType(TabBarView)),
    );
    tabs.index = 1;
    await tester.pumpAndSettle();
    tabs.index = 0;
    await tester.pumpAndSettle();
    expect(tester.state(find.byType(ComicsTabContent)), same(state));
    expect(scroll.pixels, before);
    final back = tester.widget<FloatingBackToTop>(
      find.byType(FloatingBackToTop),
    );
    expect(back.show, isTrue);
    back.onTap();
    await tester.pump();
    expect(scroll.pixels, 0);
    expect(tester.takeException(), isNull);
  });

  for (final scenario in [
    (const Size(390, 844), 'zh', false, 1.0, false),
    (const Size(390, 844), 'en', true, 1.0, false),
    (const Size(951, 669), 'en', true, 1.6, false),
    (const Size(466, 678), 'zh', false, 1.4, true),
  ]) {
    testWidgets('分组书目 $scenario 无外壳、同高且大字Duo适配', (tester) async {
      final (size, language, dark, scale, cutout) = scenario;
      final previous_shadows = debugDisableShadows;
      if (_preview_dir.isNotEmpty) debugDisableShadows = false;
      try {
        final logic = ComicsTabLogic(
          home_loader: ({language, seed}) async =>
              _feed(groups: 4, real_covers: _preview_dir.isNotEmpty),
        );
        addTearDown(logic.dispose);
        await _mount(
          tester,
          logic,
          size: size,
          language: language,
          dark: dark,
          scale: scale,
          cutout: cutout,
          reduce_motion: true,
        );
        if (_preview_dir.isNotEmpty) {
          for (var frame = 0; frame < 8; frame++) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 30)),
            );
            await tester.pump(const Duration(milliseconds: 200));
          }
        }
        final first = find.byKey(const ValueKey('comic_discovery_card_1'));
        final third = find.byKey(const ValueKey('comic_discovery_card_3'));
        final fourth = find.byKey(const ValueKey('comic_discovery_card_4'));
        final sixth = find.byKey(const ValueKey('comic_discovery_card_6'));
        expect(
          tester.getSize(first).height,
          closeTo(tester.getSize(sixth).height, 0.1),
        );
        expect(tester.getTopLeft(first).dy, tester.getTopLeft(third).dy);
        if (size.width >= 900) {
          expect(tester.getTopLeft(first).dy, tester.getTopLeft(sixth).dy);
        } else {
          expect(
            tester.getTopLeft(fourth).dy,
            greaterThan(tester.getBottomLeft(first).dy),
          );
        }
        expect(tester.takeException(), isNull);
        if (_preview_dir.isNotEmpty) {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('comics_home_capture')),
          );
          await tester.runAsync(() async {
            await Directory(_preview_dir).create(recursive: true);
            final image = await boundary.toImage(pixelRatio: 2);
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            await File(
              '$_preview_dir/comics_home_${size.width.toInt()}_${language}_${dark ? 'dark' : 'light'}.png',
            ).writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
        }
      } finally {
        debugDisableShadows = previous_shadows;
      }
    });
  }
  testWidgets('服务器画像等待时补取无seed新首屏，完成后停止', (tester) async {
    var calls = 0;
    final seeds = <String?>[];
    final logic = ComicsTabLogic(
      home_loader: ({language, seed}) async {
        seeds.add(seed);
        calls++;
        return ComicDiscoveryFeed(
          sections: const [],
          categories: const [],
          seed: 'snapshot-$calls',
          profile_pending: calls == 1,
        );
      },
    );
    addTearDown(logic.dispose);
    await _mount(tester, logic);
    expect(calls, 1);
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump();
    expect(calls, 2);
    expect(seeds, [null, null]);
    expect(logic.profile_pending, isFalse);
    await tester.pump(const Duration(seconds: 4));
    expect(calls, 2);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
