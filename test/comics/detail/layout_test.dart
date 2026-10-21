// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:app/models/comics.dart';
import 'package:app/models/language_info.dart';
import 'package:app/models/user_info.dart';
import 'package:app/pages/comics/detail/index.dart';
import 'package:app/pages/comics/detail/logic.dart';
import 'package:app/pages/comics/detail/widgets/chapter_list.dart';
import 'package:app/pages/comics/widgets/chapter_sheet/index.dart';
import 'package:app/pages/comics/detail/widgets/hero_header.dart';
import 'package:app/pages/comics/detail/widgets/overview_tab.dart';
import 'package:app/stores/language_store.dart';
import 'package:app/stores/user_information.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Assets extends AssetLoader {
  const _Assets();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      Map<String, dynamic>.from(
        jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
            as Map,
      );
}

class _LanguageStore extends LanguageStore {
  _LanguageStore()
    : super(asset_language_code_list: <String>['en', 'zh', 'ja', 'ko']) {
    supported_language_list.assignAll(const <LanguageInfo>[
      LanguageInfo(id: 1, code: 'en', title: 'English'),
      LanguageInfo(id: 2, code: 'zh', title: '简体中文'),
      LanguageInfo(id: 3, code: 'ja', title: '日本語'),
      LanguageInfo(id: 4, code: 'ko', title: '한국어'),
    ]);
  }
  @override
  // ignore: must_call_super
  void onInit() {}
}

const long_description =
    'A heartwarming action love story about Lily, who is a type of girl '
    'full of energy and kindness, and a boy who carries a mysterious past. '
    'When their peaceful town is threatened by dark forces, they must stand '
    'together to protect the people they love. This long description verifies '
    'a continuous expansion without changing the underlying text.';

ComicDetail _fixture(String language) => ComicDetail(
  comic: ComicItem(
    id: 42,
    title: language == 'zh' ? '在遥远世界寻找晨光的漫长旅途' : 'The Town Where God Lives',
    cover_url: '',
    author_id: 1,
    author_name: 'Ryukou',
    categories: const <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 1,
        'name': 'Action',
        'translations': {'en': 'Action', 'zh': '动作'},
      },
      <String, dynamic>{
        'id': 2,
        'name': 'Fantasy',
        'translations': {'en': 'Fantasy', 'zh': '奇幻'},
      },
      <String, dynamic>{
        'id': 3,
        'name': 'Romance',
        'translations': {'en': 'Romance', 'zh': '浪漫'},
      },
    ],
    chapter_count: 1,
    language_count: 1,
    status: 'published',
    completion_status: 'completed',
    favorite_count: 8200,
    view_count: 234100,
    comment_count: 324,
    rating: 9.6,
    rating_count: 12400,
    update_time: '2026-10-15T00:00:00.000Z',
  ),
  languages: <ComicLanguage>[
    ComicLanguage(
      id: 7,
      language: language,
      title: language == 'zh' ? '在遥远世界寻找晨光的漫长旅途' : 'The Town Where God Lives',
      description: language == 'zh' ? '一个温暖人心的冒险爱情故事。' : long_description,
      cover_url: '',
    ),
  ],
  selected_language_id: 7,
  chapters: List<ComicChapter>.generate(
    5,
    (index) => ComicChapter(
      id: index + 1,
      title: 'Chapter ${index + 1}',
      page_count: 32,
      sort_order: index + 1,
      status: 'published',
      images: const <ComicImageData>[],
    ),
  ),
  is_collected: false,
  read_record: <String, dynamic>{},
);

class _Logic extends ComicDetailLogic {
  _Logic(String language) : super(42) {
    detail = _fixture(language);
    loading = false;
  }
  @override
  Future<void> load({String? language}) async {}
  @override
  Future<void> load_similar() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (call) async => call.method == 'getAll' ? <String, Object>{} : true,
        );
    await EasyLocalization.ensureInitialized();
    if (Platform.environment['COMIC_CAPTURE'] == '1') {
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      for (final entry in {
        'Roboto': 'Arial',
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
    }
  });
  setUp(() {
    Get.testMode = true;
    final user = Get.put<UserInformation>(UserInformation());
    user.saveUserInfo(UserInfo.fromJson(<String, dynamic>{'id': 1}));
    Get.put<LanguageStore>(_LanguageStore());
  });
  tearDown(Get.reset);

  Future<void> mount(
    WidgetTester tester,
    Widget child, {
    bool dark = false,
    String language = 'en',
  }) async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: <Locale>[Locale(language)],
        path: 'assets/i18n',
        assetLoader: const _Assets(),
        startLocale: Locale(language),
        fallbackLocale: Locale(language),
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
            home: child,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final dark in <bool>[false, true]) {
    testWidgets('详情页渲染完整 ${dark ? 'dark' : 'light'}', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await mount(
        tester,
        ComicDetailPage(
          comic_id: 42,
          controller: _Logic('en'),
          cover_image: const ColoredBox(color: Colors.orange),
        ),
        dark: dark,
      );
      expect(tester.takeException(), isNull);
      // Hero 元素
      expect(find.byType(ComicDetailHeroHeader), findsOneWidget);
      // Tab 栏（Chapters 在 Tab 和 Details 区块都出现）
      expect(find.byType(TabBar), findsNothing);
      expect(find.byType(NestedScrollView), findsNothing);
      expect(find.text('Chapters'), findsWidgets);
      expect(find.text('Comments'), findsWidgets);
    });
  }

  for (final language in <String>['en', 'zh']) {
    for (final dark in <bool>[false, true]) {
      testWidgets('详情 $language ${dark ? 'dark' : 'light'} 核心区块', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await mount(
          tester,
          ComicDetailPage(
            comic_id: 42,
            controller: _Logic(language),
            cover_image: const ColoredBox(color: Colors.orange),
          ),
          dark: dark,
          language: language,
        );
        expect(tester.takeException(), isNull);
        // Overview 标签页内容
        expect(find.byType(ComicDetailOverviewTab), findsOneWidget);
        // 标题存在
        final title_text = language == 'zh'
            ? '在遥远世界寻找晨光的漫长旅途'
            : 'The Town Where God Lives';
        expect(find.textContaining(title_text.split(' ').first), findsWidgets);
      });
    }
  }

  for (final dark in <bool>[false, true]) {
    testWidgets('章节列表展示 ${dark ? 'dark' : 'light'}', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await mount(
        tester,
        ComicDetailPage(
          comic_id: 42,
          controller: _Logic('en'),
          cover_image: const ColoredBox(color: Colors.orange),
        ),
        dark: dark,
      );
      // 切换到 Chapters tab（点击 Tab 栏中的标签）
      final chapters_tab = find.byKey(const ValueKey('comic_detail_chapters'));
      await tester.tap(chapters_tab);
      await tester.pumpAndSettle();
      expect(find.byType(ComicDetailChapterTile), findsWidgets);
    });
  }

  testWidgets('CTA 按钮存在并可点击', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(
      tester,
      ComicDetailPage(
        comic_id: 42,
        controller: _Logic('en'),
        cover_image: const ColoredBox(color: Colors.orange),
      ),
    );
    // Start reading 按钮存在
    expect(find.text('Start reading'), findsWidgets);
    // Save 按钮存在
    expect(find.byKey(const ValueKey('comic_save_button')), findsOneWidget);
    expect(find.text('Save'), findsNothing);
    // Completed 角标存在
    expect(find.text('Completed'), findsWidgets);
  });

  testWidgets('统计数据展示', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(
      tester,
      ComicDetailPage(
        comic_id: 42,
        controller: _Logic('en'),
        cover_image: const ColoredBox(color: Colors.orange),
      ),
    );
    // 评分 / 浏览 / 收藏 数值存在
    expect(find.text('9.6'), findsWidgets);
    expect(find.text('234.1K'), findsWidgets);
    expect(find.text('8.2K'), findsWidgets);
  });
  testWidgets('单一滚动简介自然展开，作者仅在标题下方展示', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final logic = _Logic('en');
    addTearDown(logic.dispose);
    await mount(
      tester,
      ComicDetailPage(
        comic_id: 42,
        controller: logic,
        cover_image: const ColoredBox(color: Color(0xFF9E947C)),
      ),
    );
    final hero_author = find.byKey(const ValueKey('comic_hero_author'));
    expect(hero_author, findsOneWidget);
    expect(tester.widget<Text>(hero_author).data, 'Ryukou');
    final hero_title = find.descendant(
      of: find.byType(ComicDetailHeroHeader),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.semanticsLabel == 'The Town Where God Lives',
      ),
    );
    expect(
      tester.getTopLeft(hero_author).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(hero_title).dy),
    );
    expect(find.text('Details'), findsNothing);
    expect(find.text('Author'), findsNothing);
    expect(find.text('Ryukou'), findsOneWidget);
    final before = tester.getSize(find.byType(ComicDetailOverviewTab)).height;
    await tester.tap(find.byKey(const ValueKey('comic_about_toggle')));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(ComicDetailOverviewTab)).height,
      greaterThan(before),
    );
    await tester.drag(
      find.byKey(const PageStorageKey('comic_detail_scroll')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    expect(find.text('Genres').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('收藏响应立即更新详情按钮', (tester) async {
    final logic = _Logic('en');
    addTearDown(logic.dispose);
    await mount(
      tester,
      ComicDetailPage(
        comic_id: 42,
        controller: logic,
        cover_image: const ColoredBox(color: Colors.orange),
      ),
    );
    logic.collected = true;
    logic.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite_rounded), findsWidgets);
    expect(find.text('Saved'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 430.0]) {
    testWidgets('窄屏与大字适配 $width', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final logic = _Logic('en');
      addTearDown(logic.dispose);
      await mount(
        tester,
        MediaQuery(
          data: MediaQueryData(
            size: Size(width, 900),
            textScaler: const TextScaler.linear(1.5),
          ),
          child: ComicDetailPage(
            comic_id: 42,
            controller: logic,
            cover_image: const ColoredBox(color: Colors.orange),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('目录弹窗关闭后保留简介状态且详情没有Tab', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final logic = _Logic('en');
    addTearDown(logic.dispose);
    await mount(
      tester,
      ComicDetailPage(
        comic_id: 42,
        controller: logic,
        cover_image: const ColoredBox(color: Colors.orange),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('comic_about_toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('comic_detail_chapters')));
    await tester.pumpAndSettle();
    expect(find.byType(ComicChapterSheet), findsOneWidget);
    expect(find.byType(ComicDetailChapterTile), findsWidgets);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(ComicChapterSheet), findsNothing);
    expect(find.byType(TabBar), findsNothing);
    expect(
      find.byKey(const ValueKey('comic_about_collapse')).hitTestable(),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.more_vert_rounded), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('目录倒序不改变章节原始编号', (tester) async {
    final logic = _Logic('en');
    addTearDown(logic.dispose);
    await mount(
      tester,
      ComicDetailPage(
        comic_id: 42,
        controller: logic,
        cover_image: const ColoredBox(color: Colors.orange),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('comic_detail_chapters')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Newest first'));
    await tester.pumpAndSettle();
    final tiles = tester
        .widgetList<ComicDetailChapterTile>(find.byType(ComicDetailChapterTile))
        .toList();
    expect(tiles.first.chapter.id, 5);
    expect(tiles.first.number, 5);
    expect(tester.takeException(), isNull);
  });

  if (Platform.environment['COMIC_CAPTURE'] == '1') {
    testWidgets('详情全页视觉检查', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(430, 1100);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      final logic = _Logic('en');
      addTearDown(logic.dispose);
      await mount(
        tester,
        RepaintBoundary(
          key: key,
          child: ComicDetailPage(
            comic_id: 42,
            controller: logic,
            cover_image: const ColoredBox(color: Color(0xFF9E947C)),
          ),
        ),
      );
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '/tmp/comic_detail_review.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      expect(tester.takeException(), isNull);
    });
  }
}
