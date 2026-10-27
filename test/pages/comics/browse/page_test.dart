// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:app/components/app_wrapper/router/route_config.dart';
import 'package:app/components/window_content_layout/index.dart';
import 'package:app/models/comics.dart';
import 'package:app/models/comics_discovery.dart';
import 'package:app/models/user_info.dart';
import 'package:app/pages/comics/browse/index.dart';
import 'package:app/pages/comics/browse/logic.dart';
import 'package:app/pages/comics/browse/style.dart';
import 'package:app/pages/comics/widgets/empty_state.dart';
import 'package:app/pages/comics/widgets/discovery_grid/index.dart';
import 'package:app/pages/comics/widgets/discovery_grid/skeleton.dart';
import 'package:app/stores/user_information.dart';
import 'package:cached_network_image/cached_network_image.dart';
// ignore: depend_on_referenced_packages
import 'package:file/local.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';

const _preview_dir = String.fromEnvironment('COMIC_BROWSE_PREVIEW_DIR');
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

List<Map<String, dynamic>> _categories(int count) => List.generate(
  count,
  (index) => {
    'id': index + 1,
    'name': 'Genre ${index + 1}',
    'translations': {'en': 'Genre ${index + 1}', 'zh': '分类${index + 1}'},
  },
);

ComicDiscoveryPage _page(
  int category,
  int page, {
  int total = 48,
  String prefix = 'Comic',
  String? seed,
}) => ComicDiscoveryPage(
  items: List.generate(
    24,
    (index) => ComicItem.from_json({
      'id': category * 1000 + (page - 1) * 24 + index + 1,
      'cover_url': _cover_files.isEmpty
          ? ''
          : 'https://fixtures.invalid/cover-${index % 6}.webp',
      'title': '$prefix ${category * 1000 + (page - 1) * 24 + index + 1}',
      'categories': [_categories(2).first],
    }),
  ),
  total: total,
  page: page,
  page_size: 24,
  seed: seed ?? 'seed-$category',
);

Future<void> _mount(
  WidgetTester tester,
  ComicBrowseLogic logic, {
  Size size = const Size(390, 844),
  double scale = 1,
  bool dark = false,
  String locale = 'en',
  bool duo = false,
  bool reduce_motion = false,
  bool settle = true,
  ValueChanged<ComicItem>? on_open,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('zh')],
      path: 'assets/i18n',
      assetLoader: const _Assets(),
      startLocale: Locale(locale),
      saveLocale: false,
      child: Builder(
        builder: (context) => MaterialApp(
          debugShowCheckedModeBanner: false,
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
              padding: EdgeInsets.only(
                top: 34,
                bottom: 34,
                right: duo ? 84 : 0,
              ),
              viewPadding: EdgeInsets.only(
                top: 34,
                bottom: 34,
                right: duo ? 84 : 0,
              ),
              disableAnimations: reduce_motion,
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
              child: RepaintBoundary(
                key: const ValueKey('comic_browse_capture'),
                child: ComicBrowsePage(controller: logic, on_open: on_open),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  if (_preview_dir.isNotEmpty) {
    await tester.pump();
    for (var frame = 0; frame < 8; frame++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump(const Duration(milliseconds: 200));
    }
  }
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Get.reset);
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (_) async => <String, Object>{},
        );
    await EasyLocalization.ensureInitialized();
    if (_preview_dir.isNotEmpty) {
      final root = Directory('/Users/ali/work/小说/后端/test/mangaberri漫画/数据/漫画');
      if (root.existsSync()) {
        final files =
            root
                .listSync()
                .whereType<Directory>()
                .map((dir) => File('${dir.path}/cover.webp'))
                .where((file) => file.existsSync())
                .toList()
              ..sort((a, b) => a.path.compareTo(b.path));
        for (var index = 0; index < 6 && index < files.length; index++) {
          _cover_files['https://fixtures.invalid/cover-$index.webp'] =
              files[index];
        }
        CachedNetworkImageProvider.defaultCacheManager = _LocalCovers();
      }
      final font = File('/System/Library/Fonts/Supplemental/Arial Unicode.ttf');
      if (font.existsSync()) {
        await (FontLoader('Roboto')..addFont(
              Future.value(ByteData.sublistView(font.readAsBytesSync())),
            ))
            .load();
      }
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
  });

  test('真实路由注册并保留首页更多传入的category_id查询', () {
    final router = RouteConfig.createRouter();
    addTearDown(router.dispose);
    final match = router.configuration.findMatch(
      Uri.parse('/comics/browse?category_id=18'),
    );
    expect(match.error, isNull);
    expect(match.uri.queryParameters['category_id'], '18');
    expect(match.last.route.path, '/comics/browse');
  });

  testWidgets('滑动未选中的相邻分类直接显示骨架，真实空结果与失败才展示空态', (tester) async {
    final second = Completer<ComicDiscoveryPage>();
    final calls = <int>[];
    final logic = ComicBrowseLogic(
      categories_loader: () async => _categories(3),
      page_loader:
          ({
            required category_id,
            required page,
            required page_size,
            seed,
            language,
          }) {
            calls.add(category_id);
            if (category_id == 1) return Future.value(_page(1, 1, total: 24));
            if (category_id == 2) return second.future;
            return Future.error(StateError('fixture page failure'));
          },
    );
    addTearDown(logic.dispose);
    await _mount(tester, logic);
    expect(calls, [1]);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(TabBarView)),
    );
    final viewport_width = tester.getSize(find.byType(TabBarView)).width;
    await gesture.moveBy(const Offset(-20, 0));
    await tester.pump();
    await gesture.moveBy(Offset(-viewport_width * 0.7, 0));
    await tester.pump();
    expect(logic.state_for(2).loaded, isFalse);
    expect(logic.state_for(2).loading, isFalse);
    expect(
      find.byKey(const ValueKey('comic_browse_skeleton_2')),
      findsOneWidget,
    );
    expect(find.byType(ComicsEmptyState, skipOffstage: false), findsNothing);
    expect(calls, [1], reason: '滑动还未完成时仅显示骨架，不提前请求相邻分类');

    await gesture.up();
    for (var frame = 0; frame < 12 && !calls.contains(2); frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(calls, [1, 2]);
    expect(logic.state_for(2).loading, isTrue);
    expect(
      find.byKey(const ValueKey('comic_browse_skeleton_2')),
      findsOneWidget,
    );

    second.complete(
      const ComicDiscoveryPage(
        items: [],
        total: 0,
        page: 1,
        page_size: 24,
        seed: 'empty-second',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('comic_browse_skeleton_2')), findsNothing);
    expect(find.byType(ComicsEmptyState), findsOneWidget);
    expect(
      tester.widget<ComicsEmptyState>(find.byType(ComicsEmptyState)).error,
      isNull,
    );

    logic.select_category(3);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('comic_browse_skeleton_3')), findsNothing);
    expect(
      tester.widget<ComicsEmptyState>(find.byType(ComicsEmptyState)).error,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('分类上下文重置后仍显示初始骨架，只有成功空分类响应才显示无数据', (tester) async {
    final first = Completer<List<Map<String, dynamic>>>();
    var categories_calls = 0;
    final logic = ComicBrowseLogic(
      categories_loader: () {
        categories_calls++;
        return categories_calls == 1 ? first.future : Future.value([]);
      },
      page_loader:
          ({
            required category_id,
            required page,
            required page_size,
            seed,
            language,
          }) => throw StateError('Empty categories should not request books'),
    );
    addTearDown(logic.dispose);
    await _mount(tester, logic, settle: false);
    logic.prepare_context(language: 'en');
    await tester.pump();
    expect(logic.loading_categories, isFalse);
    expect(logic.categories_loaded, isFalse);
    expect(
      find.byKey(const ValueKey('comic_browse_initial_skeleton')),
      findsOneWidget,
    );
    expect(find.byType(ComicsEmptyState), findsNothing);

    await logic.load_categories();
    first.complete([]);
    await tester.pumpAndSettle();
    expect(logic.categories_loaded, isTrue);
    expect(
      find.byKey(const ValueKey('comic_browse_initial_skeleton')),
      findsNothing,
    );
    expect(find.byType(ComicsEmptyState), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('分类、首屏和后续分页等待时都展示骨架，完成后替换为真实网格', (tester) async {
    final categories = Completer<List<Map<String, dynamic>>>();
    final first = Completer<ComicDiscoveryPage>();
    final more = Completer<ComicDiscoveryPage>();
    final logic = ComicBrowseLogic(
      categories_loader: () => categories.future,
      page_loader:
          ({
            required category_id,
            required page,
            required page_size,
            seed,
            language,
          }) => page == 1 ? first.future : more.future,
    );
    addTearDown(logic.dispose);
    await _mount(tester, logic, settle: false);
    expect(
      find.byKey(const ValueKey('comic_browse_initial_skeleton')),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.binding.hasScheduledFrame, isTrue);

    categories.complete(_categories(3));
    await tester.pump();
    await tester.pump();
    expect(
      find.byKey(const ValueKey('comic_browse_skeleton_1')),
      findsOneWidget,
    );
    expect(find.byType(ComicDiscoveryCard), findsNothing);

    first.complete(_page(1, 1));
    await tester.pumpAndSettle();
    expect(find.byType(ComicDiscoverySliverSkeleton), findsNothing);
    expect(find.byType(ComicDiscoveryCard), findsWidgets);
    final scroll = tester
        .widget<CustomScrollView>(
          find.byKey(const PageStorageKey('comic_browse_scroll_1_0')),
        )
        .controller!;
    scroll.jumpTo(scroll.position.maxScrollExtent - 100);
    await tester.pump();
    expect(
      find.byKey(const ValueKey('comic_browse_more_skeleton_1')),
      findsOneWidget,
    );
    expect(logic.state_for(1).items, hasLength(24));

    more.complete(_page(1, 2));
    await tester.pumpAndSettle();
    expect(find.byType(ComicDiscoverySliverSkeleton), findsNothing);
    expect(logic.state_for(1).items, hasLength(48));
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final config in [
    (
      size: const Size(320, 844),
      scale: 2.0,
      dark: false,
      locale: 'en',
      duo: false,
    ),
    (
      size: const Size(390, 844),
      scale: 1.0,
      dark: false,
      locale: 'zh',
      duo: false,
    ),
    (
      size: const Size(390, 844),
      scale: 1.0,
      dark: true,
      locale: 'en',
      duo: false,
    ),
    (
      size: const Size(466, 678),
      scale: 1.5,
      dark: false,
      locale: 'zh',
      duo: true,
    ),
    (
      size: const Size(951, 669),
      scale: 1.5,
      dark: true,
      locale: 'en',
      duo: true,
    ),
    (
      size: const Size(844, 390),
      scale: 1.4,
      dark: true,
      locale: 'en',
      duo: false,
    ),
  ]) {
    testWidgets(
      '分类列表首选自动可见与无框网格布局 ${config.size} ${config.locale} ${config.scale}x',
      (tester) async {
        final logic = ComicBrowseLogic(
          initial_category_id: 18,
          categories_loader: () async => _categories(20),
          page_loader:
              ({
                required category_id,
                required page,
                required page_size,
                seed,
                language,
              }) async => _page(category_id, page),
        );
        addTearDown(logic.dispose);
        int? opened;
        await _mount(
          tester,
          logic,
          size: config.size,
          scale: config.scale,
          dark: config.dark,
          locale: config.locale,
          duo: config.duo,
          reduce_motion: true,
          on_open: (item) => opened = item.id,
        );
        expect(
          find.byKey(const ValueKey('comic_browse_category_18')).hitTestable(),
          findsOneWidget,
        );
        expect(logic.selected_category_id, 18);
        final grid = tester.widget<SliverGrid>(find.byType(SliverGrid).first);
        final delegate =
            grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
        final width = tester
            .getSize(
              find.byKey(const PageStorageKey('comic_browse_scroll_18_0')),
            )
            .width;
        expect(
          delegate.crossAxisCount,
          ComicDiscoveryGridStyle.columns(
            width - ComicBrowseStyle.horizontal_padding * 2,
            section: false,
          ),
        );
        expect(delegate.crossAxisCount, inInclusiveRange(3, 6));
        final first_card = find.byKey(
          const ValueKey('comic_discovery_card_18001'),
        );
        expect(first_card.hitTestable(), findsOneWidget);
        await tester.tap(first_card);
        expect(opened, 18001);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(tester.binding.hasScheduledFrame, isFalse);
        if (_preview_dir.isNotEmpty) {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('comic_browse_capture')),
          );
          await tester.runAsync(() async {
            await Directory(_preview_dir).create(recursive: true);
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              '$_preview_dir/browse_${config.size.width.toInt()}_${config.locale}_${config.dark ? 'dark' : 'light'}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets('接近底部自动翻页，切分类再回来恢复滚动与已加载页面', (tester) async {
    final requests = <(int, int)>[];
    final logic = ComicBrowseLogic(
      initial_category_id: 1,
      categories_loader: () async => _categories(3),
      page_loader:
          ({
            required category_id,
            required page,
            required page_size,
            seed,
            language,
          }) async {
            requests.add((category_id, page));
            return _page(category_id, page);
          },
    );
    addTearDown(logic.dispose);
    await _mount(tester, logic);
    ScrollController scroll(int category) => tester
        .widget<CustomScrollView>(
          find.byKey(PageStorageKey('comic_browse_scroll_${category}_0')),
        )
        .controller!;
    final first_scroll = scroll(1);
    first_scroll.jumpTo(first_scroll.position.maxScrollExtent - 100);
    await tester.pumpAndSettle();
    expect(logic.state_for(1).page, 2);
    expect(requests.where((request) => request == (1, 2)).length, 1);
    final offset = first_scroll.offset;
    await tester.tap(find.byKey(const ValueKey('comic_browse_category_2')));
    await tester.pumpAndSettle();
    expect(logic.selected_category_id, 2);
    expect(scroll(2).offset, 0);
    await tester.tap(find.byKey(const ValueKey('comic_browse_category_1')));
    await tester.pumpAndSettle();
    expect(scroll(1).offset, closeTo(offset, 0.1));
    expect(logic.state_for(1).items, hasLength(48));
    expect(requests.where((request) => request == (1, 1)).length, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('下拉刷新失败仍保留漫画，分类失败可独立重试', (tester) async {
    var fail_categories = true;
    var fail_page = false;
    final seeds = <String?>[];
    final logic = ComicBrowseLogic(
      initial_category_id: 1,
      categories_loader: () async {
        if (fail_categories) throw StateError('offline categories');
        return _categories(3);
      },
      page_loader:
          ({
            required category_id,
            required page,
            required page_size,
            seed,
            language,
          }) async {
            seeds.add(seed);
            if (fail_page) throw StateError('offline comics');
            return _page(category_id, page, total: 24);
          },
    );
    addTearDown(logic.dispose);
    await _mount(tester, logic);
    expect(
      find.byKey(const ValueKey('comic_browse_categories_error')),
      findsOneWidget,
    );
    expect(find.byType(ComicDiscoveryCard), findsWidgets);
    fail_categories = false;
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('comic_browse_categories_error')),
        matching: find.byType(TextButton),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('comic_browse_category_1')),
      findsOneWidget,
    );
    fail_page = true;
    await tester.drag(
      find.byKey(const PageStorageKey('comic_browse_scroll_1_0')),
      const Offset(0, 500),
    );
    await tester.pumpAndSettle();
    expect(logic.state_for(1).error, isNotNull);
    expect(logic.state_for(1).items, hasLength(24));
    expect(
      find.byKey(const ValueKey('comic_browse_refresh_error_1')),
      findsOneWidget,
    );
    expect(seeds.last, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('语种切换重新加载内容并更新分类标题，旧语种缓存不保留', (tester) async {
    final languages = <String?>[];
    final logic = ComicBrowseLogic(
      initial_category_id: 2,
      categories_loader: () async => _categories(3),
      page_loader:
          ({
            required category_id,
            required page,
            required page_size,
            seed,
            language,
          }) async {
            languages.add(language);
            return _page(
              category_id,
              page,
              total: 24,
              prefix: language == 'zh' ? '中文漫画' : 'English comic',
            );
          },
    );
    addTearDown(logic.dispose);
    await _mount(tester, logic);
    expect(find.text('Genre 2'), findsOneWidget);
    await tester
        .element(find.byType(ComicBrowsePage))
        .setLocale(const Locale('zh'));
    await tester.pumpAndSettle();
    expect(languages.last, 'zh');
    expect(logic.language, 'zh');
    expect(find.text('分类2'), findsOneWidget);
    expect(find.textContaining('English comic'), findsNothing);
    expect(find.textContaining('中文漫画'), findsWidgets);
    expect(logic.context_revision, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('登录切换清空全部分类快照与滚动，迟到访客分页不覆盖已登录内容', (tester) async {
    Get.testMode = true;
    final user = Get.put(UserInformation());
    final old_more = Completer<ComicDiscoveryPage>();
    final seeds = <String?>[];
    final logic = ComicBrowseLogic(
      initial_category_id: 1,
      categories_loader: () async => _categories(3),
      page_loader:
          ({
            required category_id,
            required page,
            required page_size,
            seed,
            language,
          }) async {
            seeds.add(seed);
            final id = user.userInfo.value?.id ?? 0;
            if (id == 0 && page > 1) return old_more.future;
            return _page(
              category_id,
              page,
              total: 48,
              prefix: id == 0 ? 'Guest comic' : 'Member comic',
              seed: 'identity-$id',
            );
          },
    );
    addTearDown(logic.dispose);
    await _mount(tester, logic);
    final old_scroll = tester
        .widget<CustomScrollView>(
          find.byKey(const PageStorageKey('comic_browse_scroll_1_0')),
        )
        .controller!;
    old_scroll.jumpTo(old_scroll.position.maxScrollExtent - 100);
    await tester.pump();
    expect(logic.state_for(1).loading_more, isTrue);
    user.saveUserInfo(UserInfo.fromJson({'id': 7, 'name': 'Reader'}));
    await tester.pumpAndSettle();
    final context_revision = logic.context_revision;
    final new_scroll = tester
        .widget<CustomScrollView>(
          find.byKey(PageStorageKey('comic_browse_scroll_1_$context_revision')),
        )
        .controller!;
    expect(new_scroll.offset, 0);
    expect(seeds.last, isNull);
    expect(logic.state_for(1).seed, 'identity-7');
    old_more.complete(_page(1, 2, prefix: 'Guest comic', seed: 'identity-0'));
    await tester.pumpAndSettle();
    expect(logic.state_for(1).items, hasLength(24));
    expect(logic.state_for(1).items.first.title, startsWith('Member comic'));
    expect(find.textContaining('Guest comic'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('分页种子过期换成新快照后列表安全回到顶部', (tester) async {
    var requests = 0;
    final logic = ComicBrowseLogic(
      initial_category_id: 1,
      categories_loader: () async => _categories(3),
      page_loader:
          ({
            required category_id,
            required page,
            required page_size,
            seed,
            language,
          }) async {
            requests++;
            return _page(
              category_id,
              1,
              prefix: requests == 1 ? 'Old' : 'Fresh',
              seed: requests == 1 ? 'expired' : 'new-seed',
            );
          },
    );
    addTearDown(logic.dispose);
    await _mount(tester, logic);
    final scroll = tester
        .widget<CustomScrollView>(
          find.byKey(const PageStorageKey('comic_browse_scroll_1_0')),
        )
        .controller!;
    scroll.jumpTo(scroll.position.maxScrollExtent - 100);
    await tester.pumpAndSettle();
    expect(scroll.offset, 0);
    expect(logic.state_for(1).seed, 'new-seed');
    expect(logic.state_for(1).page, 1);
    expect(logic.state_for(1).items, hasLength(24));
    expect(find.textContaining('Old '), findsNothing);
    expect(find.textContaining('Fresh '), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('画像等待只补当前分类第一页，重新请求不带旧seed', (tester) async {
    var calls = 0;
    final seeds = <String?>[];
    final logic = ComicBrowseLogic(
      initial_category_id: 1,
      categories_loader: () async => _categories(1),
      page_loader:
          ({
            required category_id,
            required page,
            required page_size,
            seed,
            language,
          }) async {
            seeds.add(seed);
            calls++;
            expect(page, 1);
            return ComicDiscoveryPage(
              items: const [],
              total: 0,
              page: 1,
              page_size: 24,
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
    expect(logic.state_for(1).profile_pending, isFalse);
    await tester.pump(const Duration(seconds: 4));
    expect(calls, 2);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
