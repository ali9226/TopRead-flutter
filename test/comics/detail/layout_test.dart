// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:app/models/comics.dart';
import 'package:app/models/language_info.dart';
import 'package:app/models/user_info.dart';
import 'package:app/pages/comics/detail/index.dart';
import 'package:app/pages/comics/detail/logic.dart';
import 'package:app/pages/comics/comments/logic.dart';
import 'package:app/pages/comics/detail/widgets/chapter_preview/index.dart';
import 'package:app/pages/comics/detail/widgets/hot_comments/index.dart';
import 'package:app/pages/comics/detail/widgets/chapter_list.dart';
import 'package:app/pages/comics/widgets/chapter_sheet/index.dart';
import 'package:app/pages/comics/detail/widgets/hero_header.dart';
import 'package:app/pages/comics/detail/widgets/overview_tab.dart';
import 'package:app/pages/comics/detail/widgets/similar_comics/index.dart';
import 'package:app/pages/comics/widgets/comic_surface.dart';
import 'package:app/stores/language_store.dart';
import 'package:app/stores/user_information.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:flutter/rendering.dart';
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
  late ComicCommentsLogic comments;
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
    comments = ComicCommentsLogic(
      comic_id: 42,
      sort: 'hot',
      page_size: 3,
      requester: (action, parameter, {authorization_token}) async => {
        'list': <dynamic>[],
        'total': 0,
        'comment_count': 324,
      },
      token_reader: () async => '',
    );
    addTearDown(comments.dispose);
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
          comments_controller: comments,
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
      expect(find.byType(ComicChapterPreview), findsOneWidget);
      expect(find.byType(ComicHotComments), findsOneWidget);
      expect(
        find.byKey(const ValueKey('comic_completion_badge')),
        findsNothing,
      );
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
            comments_controller: comments,
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
          comments_controller: comments,
          comic_id: 42,
          controller: _Logic('en'),
          cover_image: const ColoredBox(color: Colors.orange),
        ),
        dark: dark,
      );
      // 切换到 Chapters tab（点击 Tab 栏中的标签）
      final chapters_tab = find.byKey(const ValueKey('comic_detail_chapters'));
      await tester.ensureVisible(chapters_tab);
      await tester.pumpAndSettle();
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
        comments_controller: comments,
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
        comments_controller: comments,
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
        comments_controller: comments,
        comic_id: 42,
        controller: logic,
        cover_image: const ColoredBox(
          color: ColorConstants.comics_detail_layout_test_tone_ff9e947c,
        ),
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
    await tester.ensureVisible(
      find.byKey(const ValueKey('comic_about_toggle')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('comic_about_toggle')));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(ComicDetailOverviewTab)).height,
      greaterThan(before),
    );
    expect(find.byKey(const ValueKey('comic_hero_genres')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('长标题漫画自然增高且完整显示，保留导航和阅读收藏回调', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const title =
        'The Unabridged Journey Across the Faraway Kingdoms Where '
        'Every Lost Star Finds Its Way Back to the People Who Remember Its Name';
    const author = 'An Artist With A Complete Name That Must Remain Visible';
    final detail = ComicDetail.from_json({
      'comic': {
        'id': 42,
        'title': title,
        'author_name': author,
        'rating': 9.6,
        'rating_count': 12400,
        'view_count': 234100,
        'favorite_count': 8200,
      },
    });
    for (final width in [320.0, 780.0]) {
      final dark = width > 500;
      tester.view.physicalSize = Size(width, 900);
      var backs = 0;
      var shares = 0;
      var reads = 0;
      var saves = 0;
      await mount(
        tester,
        MediaQuery(
          data: MediaQueryData(
            size: Size(width, 900),
            textScaler: const TextScaler.linear(2),
          ),
          child: Scaffold(
            body: CustomScrollView(
              slivers: [
                ComicDetailHeroHeader(
                  detail: detail,
                  is_dark: dark,
                  cover_image: const ColoredBox(color: Colors.orange),
                  on_back: () => backs++,
                  on_share: () => shares++,
                  on_read: () => reads++,
                  on_collect: () => saves++,
                ),
              ],
            ),
          ),
        ),
        dark: dark,
      );
      final poster = find.byKey(const ValueKey('work_introduction_poster'));
      final cover = find.byKey(const ValueKey('work_introduction_cover'));
      final panel = find.byKey(const ValueKey('work_introduction_panel'));
      final title_finder = find.text(title);
      final author_finder = find.byKey(const ValueKey('comic_hero_author'));
      expect(
        tester.getBottomLeft(title_finder).dy,
        lessThan(tester.getBottomLeft(poster).dy),
      );
      expect(panel, findsNothing);
      expect(
        tester
            .getBottomLeft(
              find.byKey(const ValueKey('work_introduction_metadata')),
            )
            .dy,
        closeTo(tester.getBottomLeft(cover).dy, 0.01),
      );
      expect(
        tester.getTopLeft(title_finder).dx,
        greaterThanOrEqualTo(tester.getTopRight(cover).dx + 16),
      );
      expect(tester.widget<Text>(title_finder).maxLines, isNull);
      expect(tester.widget<Text>(author_finder).maxLines, isNull);
      final title_style = tester.widget<Text>(title_finder).style!;
      expect(title_style.shadows, isNotEmpty);
      expect(
        tester.widget<Text>(author_finder).style!.shadows,
        title_style.shadows,
      );
      expect(
        tester
            .renderObject<RenderParagraph>(
              find.descendant(
                of: title_finder,
                matching: find.byType(RichText),
              ),
            )
            .didExceedMaxLines,
        isFalse,
      );
      expect(
        tester.getTopLeft(author_finder).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(title_finder).dy),
      );
      expect(tester.getSize(title_finder).width, lessThan(width - 40));
      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.tap(find.byIcon(Icons.share_outlined));
      expect(backs, 1);
      expect(shares, 1);
      await tester.ensureVisible(find.text('Start reading'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start reading'));
      await tester.tap(find.byKey(const ValueKey('comic_save_button')));
      expect(reads, 1);
      expect(saves, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('完结状态移到章节上方，封面不再展示状态角标', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final language in ['en', 'zh']) {
      final logic = _Logic(language);
      addTearDown(logic.dispose);
      await mount(
        tester,
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 900),
            textScaler: TextScaler.linear(2),
          ),
          child: ComicDetailPage(
            comic_id: 42,
            controller: logic,
            comments_controller: comments,
            cover_image: const ColoredBox(color: Colors.orange),
          ),
        ),
        language: language,
      );
      expect(
        find.byKey(const ValueKey('comic_completion_badge')),
        findsNothing,
      );
      final status = find.byKey(const ValueKey('comic_serialization_status'));
      await tester.scrollUntilVisible(
        status,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(status).data,
        language == 'en' ? 'Completed' : '已完结',
      );
      expect(
        tester.getTopLeft(status).dy,
        lessThan(
          tester
              .getTopLeft(find.byKey(const ValueKey('comic_chapter_previews')))
              .dy,
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('收藏响应立即更新详情按钮', (tester) async {
    final logic = _Logic('en');
    addTearDown(logic.dispose);
    await mount(
      tester,
      ComicDetailPage(
        comments_controller: comments,
        comic_id: 42,
        controller: logic,
        cover_image: const ColoredBox(color: Colors.orange),
      ),
    );
    logic.collected = true;
    logic.notifyListeners();
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) => widget is SvgIcon && widget.name == 'user_selected',
      ),
      findsWidgets,
    );
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
            comments_controller: comments,
            comic_id: 42,
            controller: logic,
            cover_image: const ColoredBox(color: Colors.orange),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final scenario in const [
    (Size(390, 844), false),
    (Size(844, 390), true),
    (Size(466, 678), true),
  ]) {
    testWidgets('真实漫画目录列表贯穿底部，安全区仅保留在列表内容内 $scenario', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = scenario.$1;
      tester.view.padding = const FakeViewPadding(bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(bottom: 34);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      final logic = _Logic('en');
      addTearDown(logic.dispose);
      await mount(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => show_comic_chapter_sheet(
                context,
                comic_id: 42,
                controller: logic,
              ),
              child: const Text('Open chapters'),
            ),
          ),
        ),
        dark: scenario.$2,
      );
      await tester.tap(find.text('Open chapters'));
      await tester.pumpAndSettle();
      for (final key in [
        'comic_chapter_sheet_surface',
        'comic_chapter_sheet_list_region',
      ]) {
        expect(
          tester.getBottomLeft(find.byKey(ValueKey(key))).dy,
          closeTo(scenario.$1.height, 0.1),
          reason: '背景和可滚动视口都必须延伸到窗口底部',
        );
      }
      final list = tester.widget<CustomScrollView>(
        find.byKey(const PageStorageKey('comic_chapters_scroll')),
      );
      final tail = list.slivers.whereType<SliverPadding>().last;
      expect(
        tail.padding.resolve(ui.TextDirection.ltr).bottom,
        greaterThanOrEqualTo(34),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
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
        comments_controller: comments,
        comic_id: 42,
        controller: logic,
        cover_image: const ColoredBox(color: Colors.orange),
      ),
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('comic_about_toggle')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('comic_about_toggle')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('comic_detail_chapters')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('comic_detail_chapters')));
    await tester.pumpAndSettle();
    expect(find.byType(ComicChapterSheet), findsOneWidget);
    expect(find.byType(ComicDetailChapterTile), findsWidgets);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(ComicChapterSheet), findsNothing);
    expect(find.byType(TabBar), findsNothing);
    await tester.ensureVisible(
      find.byKey(const ValueKey('comic_about_collapse')),
    );
    await tester.pumpAndSettle();
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
        comments_controller: comments,
        comic_id: 42,
        controller: logic,
        cover_image: const ColoredBox(color: Colors.orange),
      ),
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('comic_detail_chapters')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('comic_detail_chapters')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Newest first'));
    await tester.pumpAndSettle();
    final tiles = tester
        .widgetList<ComicDetailChapterTile>(find.byType(ComicDetailChapterTile))
        .toList();
    expect(tiles, isNotEmpty);
    for (final tile in tiles) {
      expect(tile.number, tile.chapter.id);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('简介紧接封面，章节和独立推荐卡片可横滑到窗口边缘', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final logic = _Logic('en');
    addTearDown(logic.dispose);
    logic.similar_comics = List.generate(
      5,
      (index) => ComicItem(
        id: index + 100,
        title: 'A new adventure ${index + 1}',
        cover_url: '',
        author_id: 1,
        author_name: 'Artist',
        categories: const [],
        chapter_count: 12,
        language_count: 1,
        status: 'published',
      ),
    );
    await mount(
      tester,
      ComicDetailPage(
        comic_id: 42,
        controller: logic,
        comments_controller: comments,
        cover_image: const ColoredBox(color: Colors.orange),
      ),
    );
    final about = find.byKey(const ValueKey('comic_about_header'));
    final status = find.byKey(const ValueKey('comic_serialization_status'));
    expect(tester.getTopLeft(about).dy, lessThan(tester.getTopLeft(status).dy));
    final chapter_scroll = find.byKey(const ValueKey('comic_chapter_previews'));
    await tester.ensureVisible(chapter_scroll);
    await tester.pumpAndSettle();
    expect(tester.getRect(chapter_scroll).left, 0);
    expect(tester.getRect(chapter_scroll).right, 390);
    await tester.drag(chapter_scroll, const Offset(-60, 0));
    await tester.pumpAndSettle();
    expect(
      tester
          .getRect(find.byKey(const ValueKey('comic_chapter_preview_1')))
          .left,
      lessThan(0),
    );
    final row = find.byType(ComicSimilarComicsRow);
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    expect(
      find.ancestor(of: row, matching: find.byType(ComicSurface)),
      findsNothing,
    );
    expect(
      find.descendant(of: row, matching: find.byType(ComicSurface)),
      findsAtLeastNWidgets(2),
    );
    final scroll = find.byKey(const ValueKey('comic_similar_scroll'));
    expect(tester.getRect(scroll).left, 0);
    expect(tester.getRect(scroll).right, 390);
    await tester.drag(scroll, const Offset(-60, 0));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(const ValueKey('comic_similar_card_100'))).left,
      lessThan(0),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('反复展开关闭简介与目录后推荐仍可双向滑动，重建保持位置', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final logic = _Logic('en');
    addTearDown(logic.dispose);
    logic.similar_comics = List.generate(
      30,
      (index) => ComicItem(
        id: 100 + index,
        title: index.isEven
            ? 'A short title'
            : 'The long journey beyond the mountains and stars',
        cover_url: '',
        author_id: 1,
        author_name: index.isEven ? '' : 'Artist',
        categories: const [],
        chapter_count: 12,
        language_count: 1,
        status: 'published',
      ),
    );
    await mount(
      tester,
      ComicDetailPage(
        comic_id: 42,
        controller: logic,
        comments_controller: comments,
        cover_image: const ColoredBox(color: Colors.orange),
      ),
    );
    final row = find.byType(ComicSimilarComicsRow);
    final scrollable = find.descendant(
      of: row,
      matching: find.byType(Scrollable),
    );
    final toggle = find.byKey(const ValueKey('comic_about_toggle'));
    final chapters = find.byKey(const ValueKey('comic_detail_chapters'));
    for (var cycle = 0; cycle < 3; cycle++) {
      await tester.ensureVisible(toggle);
      await tester.pumpAndSettle();
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      await tester.ensureVisible(toggle);
      await tester.pumpAndSettle();
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      await tester.ensureVisible(chapters);
      await tester.pumpAndSettle();
      await tester.tap(chapters);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(ComicChapterSheet), findsNothing);
      expect(find.byType(ModalBarrier).hitTestable(), findsNothing);
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      final position = tester.state<ScrollableState>(scrollable).position;
      final before = position.pixels;
      await tester.drag(row, const Offset(-160, 0));
      await tester.pumpAndSettle();
      expect(position.pixels, greaterThan(before));
      final after = position.pixels;
      await tester.drag(row, const Offset(80, 0));
      await tester.pumpAndSettle();
      expect(position.pixels, lessThan(after));
      final retained = position.pixels;
      logic.notifyListeners();
      await tester.pumpAndSettle();
      expect(position.pixels, retained);
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.takeException(), isNull);
    }
    expect(
      find
          .descendant(of: row, matching: find.byType(ComicSurface))
          .evaluate()
          .length,
      lessThan(30),
    );
  });

  if (Platform.environment['COMIC_CAPTURE'] == '1') {
    for (final dark in [false, true]) {
      testWidgets('详情全页视觉检查 $dark', (tester) async {
        final previous_disable_shadows = debugDisableShadows;
        debugDisableShadows = false;
        try {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(430, 1100);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final key = GlobalKey();
          final logic = _Logic('en');
          addTearDown(logic.dispose);
          logic.similar_comics = List.generate(
            5,
            (index) => ComicItem(
              id: 100 + index,
              title: index.isEven
                  ? 'The journey beyond tomorrow'
                  : 'A new beginning',
              cover_url: '',
              author_id: 1,
              author_name: 'Artist',
              categories: const [],
              chapter_count: 12,
              language_count: 1,
              status: 'published',
            ),
          );
          final preview = ComicCommentsLogic(
            comic_id: 42,
            sort: 'hot',
            page_size: 3,
            requester: (action, params, {authorization_token}) async => {
              'list': [
                {
                  'id': 1,
                  'user_id': 2,
                  'nickname': 'Mira',
                  'comment_content':
                      'Every chapter feels like stepping into another world. The artwork keeps getting better.',
                  'like_count': 124,
                  'create_time': '2026-10-23 10:00:00',
                },
                {
                  'id': 2,
                  'user_id': 3,
                  'nickname': 'Oliver',
                  'comment_content':
                      'That last panel! I had to go back and read it twice.',
                  'like_count': 86,
                  'create_time': '2026-10-23 12:00:00',
                },
                {
                  'id': 3,
                  'user_id': 4,
                  'nickname': 'Luna',
                  'comment_content': 'Looking forward to the next adventure.',
                  'like_count': 52,
                  'create_time': '2026-10-23 13:00:00',
                },
              ],
              'total': 324,
              'comment_count': 324,
            },
            token_reader: () async => '',
          );
          addTearDown(preview.dispose);
          await mount(
            tester,
            RepaintBoundary(
              key: key,
              child: ComicDetailPage(
                comments_controller: preview,
                comic_id: 42,
                controller: logic,
                cover_image: const ColoredBox(
                  color: ColorConstants.comics_detail_layout_test_tone_ff9e947c,
                ),
              ),
            ),
            dark: dark,
          );
          Future<void> capture(String suffix) async {
            final boundary =
                key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            await tester.runAsync(() async {
              final image = suffix == 'catalog'
                  ? await (tester.binding.renderViews.first.debugLayer!
                            as OffsetLayer)
                        .toImage(
                          Offset.zero & tester.binding.renderViews.first.size,
                          pixelRatio: 2,
                        )
                  : await boundary.toImage(pixelRatio: 2);
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File(
                '/tmp/comic_detail_${dark ? 'dark' : 'light'}_$suffix.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }

          await capture('hero');
          await tester.ensureVisible(
            find.byKey(const ValueKey('comic_serialization_status')),
          );
          await tester.pumpAndSettle();
          await capture('content');
          await tester.ensureVisible(find.byType(ComicSimilarComicsRow));
          await tester.pumpAndSettle();
          await capture('recommendations');
          await tester.ensureVisible(
            find.byKey(const ValueKey('comic_detail_chapters')),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('comic_detail_chapters')));
          await tester.pumpAndSettle();
          await capture('catalog');
          expect(tester.takeException(), isNull);
        } finally {
          // Flutter checks painting invariants before addTearDown callbacks run.
          debugDisableShadows = previous_disable_shadows;
        }
      });
    }
  }
}
