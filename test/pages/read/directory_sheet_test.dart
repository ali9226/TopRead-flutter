// TODO 本地数据渲染真实目录弹窗，验证设计约束、左右切页和阅读定位。
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:app/api/dio_client.dart';
import 'package:app/components/comment_list/index.dart';
import 'package:app/components/comment_list/widgets/comment_header.dart';
import 'package:app/components/comment_list/widgets/comment_input.dart';
import 'package:app/components/comment_list/widgets/comment_item.dart';
import 'package:app/components/positioning/index.dart';
import 'package:app/components/window_content_layout/index.dart';
import 'package:app/components/work_introduction_hero/style.dart';
import 'package:app/components/work_hero_stats/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/novel_info.dart';
import 'package:app/pages/read/logic.dart';
import 'package:app/pages/read/widgets/read_directory_sheet/index.dart';
import 'package:app/pages/read/widgets/read_directory_sheet/widgets/book_header_backdrop.dart';
import 'package:app/pages/read/widgets/read_directory_sheet/widgets/book_introduction.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/comment_section/index.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/novel_reading_store.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/encryption/get_encryption.dart';
import 'package:app/util/language_util/language_change_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:get_storage/get_storage.dart';

class _Assets extends AssetLoader {
  const _Assets();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      Map<String, dynamic>.from(
        jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
            as Map,
      );
}

class _Device extends DeviceInfo {
  @override
  // TODO 本组只验证布局，不订阅真实设备的网络插件。
  // ignore: must_call_super
  void onInit() {}
}

/// TODO 只提供目录消费的数据，点击回调由测试记录，评论请求由本地拦截器响应。
class _DirectoryLogic extends Fake implements Logic {
  _DirectoryLogic({
    int current = 0,
    int count = 40,
    bool long_titles = false,
    this.review_count = 1509,
    this.tags = const ['Fantasy', 'Completed'],
    this.description = 'A promise changes the course of a quiet life.',
  }) : current_chapter_index = current.obs,
       chapter_list = List.generate(
         count,
         (index) => NovelChapterInfo.from_json({
           'id': '${index + 1}',
           'chapter_no': index + 1,
           'title': long_titles
               ? 'Chapter ${index + 1}: A promise beyond the ruined city and the last light of the kingdom'
               : (index == 0 ? 'A Crazy Wizard' : 'Chapter ${index + 1}'),
         }),
       ) {
    _sync_novel_info();
  }

  @override
  final RxInt current_chapter_index;

  @override
  final List<NovelChapterInfo> chapter_list;

  @override
  final NovelReadingStore store = NovelReadingStore();

  int? review_count;
  final List<String> tags;
  final String description;

  @override
  int get comment_count => review_count ?? 0;

  @override
  void update_comment_count(int new_count) {
    review_count = new_count;
    _sync_novel_info();
  }

  void _sync_novel_info() => store.set_novel_info(
    NovelInfo.from_json({
      'id': '1',
      'title': 'Re:Chimaera',
      'subtitle': 'A Monster Evolution Time Loop LitRPG',
      'favorite_count': '42900',
      'comment_count': review_count?.toString(),
      'publish_status': 4,
      'language_info': {'id': '1', 'word_count': 185320},
    }),
  );

  @override
  ReadDetail build_detail() => ReadDetail(
    story_id: 1,
    title: 'Re:Chimaera',
    cover_url: '',
    author_id: 1,
    author_avatar_url: '',
    author_name: 'Mira',
    focus_on: false,
    score_major_text: '9.81',
    score_minor_text: '',
    review_count_text:
        '${NumberFormat.decimalPattern('en').format(review_count ?? 0)} reviews',
    reading_major_text: '10.4',
    reading_minor_text: 'K',
    reading_subtitle_text: 'Readers',
    reading_value_text: '10.4K',
    reading_label_text: 'Readers',
    word_count_major_text: '185.3',
    word_count_minor_text: 'K',
    word_count_subtitle_text: 'Words',
    word_count_value_text: '185,320',
    word_count_label_text: 'Words',
    status_text: 'Completed',
    tag_list: tags,
    intro_text: description,
    chapter_title: 'Chapter 1',
    comment_count: review_count,
    comment_list: const [
      ReadComment(
        avatar_url: '',
        user_name: 'A reader',
        content: 'An unexpected beginning, and a world worth returning to.',
        star_count: 5,
        user_id: 1,
      ),
    ],
  );
}

const _catalog_key = ValueKey('read_directory_catalog_list');
const _tab_view_key = ValueKey('read_directory_tab_view');
const _position_key = ValueKey('read_directory_position');
const _continue_key = ValueKey('read_directory_continue');
const _preview_dir = String.fromEnvironment('READ_DIRECTORY_PREVIEW_DIR');

Finder _chapter(int index) =>
    find.byKey(ValueKey('read_directory_chapter_$index'));

Map<String, dynamic> _comment_parameters(RequestOptions options) =>
    Map<String, dynamic>.from(
      decryptEncryption(options.data['encryption'] as String) as Map,
    );

/// TODO 在 Dio 发送前返回本地分页数据，目录切页测试不会访问真实评论服务。
void _respond_comments(
  RequestOptions options,
  RequestInterceptorHandler handler, {
  required List<int> ids,
  required int total,
}) {
  final page = _comment_parameters(options)['page'] as int;
  final payload = base64Url
      .encode(
        utf8.encode(
          jsonEncode({
            'status': true,
            'message': '',
            'content': {
              'list': ids
                  .skip((page - 1) * 20)
                  .take(20)
                  .map(
                    (id) => {
                      'id': id,
                      'user_id': id,
                      'avatar_url': '',
                      'nickname': 'Reader $id',
                      'comment_content': 'Comment $id. A memorable chapter.',
                      'create_time': '2026-11-05T00:00:00Z',
                      'like_count': 0,
                      'score': 5,
                      'replies': <dynamic>[],
                    },
                  )
                  .toList(),
              'total': total,
              'page': page,
              'page_size': 20,
            },
          }),
        ),
      )
      .replaceAll('=', '');
  handler.resolve(
    Response<dynamic>(
      requestOptions: options,
      statusCode: 200,
      data: {'encryption': 'e30.$payload.signature'},
    ),
  );
}

/// TODO 使用真实本地化及窗口布局；modal=true 时验证关闭和回调，不模拟导航行为。
Future<void> _mount(
  WidgetTester tester,
  _DirectoryLogic logic, {
  Size size = const Size(390, 844),
  bool dark = false,
  double scale = 1,
  String language = 'en',
  bool modal = false,
  double keyboard_height = 0,
  ValueChanged<int>? on_chapter_tap,
  VoidCallback? on_continue,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard_height);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  final device = Get.find<DeviceInfo>();
  device.theme.value = dark ? ThemeMode.dark : ThemeMode.light;
  LanguageChangeHandler.sync_initial_language(language);
  await tester.pumpWidget(
    RepaintBoundary(
      key: const ValueKey('read_directory_preview_capture'),
      child: EasyLocalization(
        key: ValueKey(language),
        supportedLocales: const [Locale('en'), Locale('zh')],
        startLocale: Locale(language),
        fallbackLocale: const Locale('en'),
        path: 'assets/i18n',
        saveLocale: false,
        assetLoader: const _Assets(),
        child: Builder(
          builder: (context) => MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              platform: TargetPlatform.iOS,
              brightness: dark ? Brightness.dark : Brightness.light,
              fontFamily: _preview_dir.isNotEmpty ? 'Roboto' : null,
            ),
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(scale),
                viewPadding: const EdgeInsets.only(bottom: 34),
                viewInsets: EdgeInsets.only(bottom: keyboard_height),
              ),
              child: WindowLayoutScope(
                child: Scaffold(
                  resizeToAvoidBottomInset: false,
                  body: Builder(
                    builder: (context) => modal
                        ? Center(
                            child: TextButton(
                              key: const ValueKey('open_directory'),
                              onPressed: () => ReadDirectorySheet.show(
                                context: context,
                                logic: logic,
                                is_dark: dark,
                                current_chapter_progress_percent: 37,
                                on_chapter_tap: on_chapter_tap,
                                on_continue: on_continue,
                              ),
                              child: const Text('Open directory'),
                            ),
                          )
                        : Align(
                            alignment: Alignment.bottomCenter,
                            child: ReadDirectorySheet(
                              logic: logic,
                              is_dark: dark,
                              current_chapter_progress_percent: 37,
                              on_chapter_tap: on_chapter_tap,
                              on_continue: on_continue,
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
  await tester.pumpAndSettle();
  if (modal) {
    await tester.tap(find.byKey(const ValueKey('open_directory')));
    await tester.pumpAndSettle();
  }
}

ScrollController _catalog_controller(WidgetTester tester) =>
    tester.widget<ListView>(find.byKey(_catalog_key)).controller!;

/// TODO 只在显式导图时输出真实字体下的整页 PNG，不改变普通离线测试环境。
Future<void> _export_preview(WidgetTester tester, String name) async {
  if (_preview_dir.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('read_directory_preview_capture')),
  );
  await tester.runAsync(() async {
    await Directory(_preview_dir).create(recursive: true);
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(
      '$_preview_dir/$name.png',
    ).writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storage_directory;
  late Interceptor interceptor;
  final comment_requests = <RequestOptions>[];
  var comment_ids = <int>[];
  var comment_total = 0;
  setUpAll(() async {
    storage_directory = Directory.systemTemp.createTempSync(
      'read_directory_comments_',
    );
    File('${storage_directory.path}/GetStorage.gs').writeAsStringSync('{}');
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => storage_directory.path,
    );
    await GetStorage('GetStorage', storage_directory.path).initStorage;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (call) async => call.method == 'getAll' ? <String, Object>{} : true,
        );
    await EasyLocalization.ensureInitialized();
    if (_preview_dir.isNotEmpty) {
      // TODO 仅导出预览时加载本地真实字体，避免测试默认 Ahem 方块掩盖排版。
      for (final entry in {
        'Roboto': 'Arial Unicode',
        '.SF UI Text': 'Arial Unicode',
        '.SF UI Display': 'Arial Unicode',
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
    comment_requests.clear();
    comment_ids = <int>[];
    comment_total = 0;
    Get.put<DeviceInfo>(_Device());
    Get.put(ProjectConfigStore());
    Get.put(UserInformation());
    interceptor = InterceptorsWrapper(
      onRequest: (options, handler) {
        comment_requests.add(options);
        _respond_comments(
          options,
          handler,
          ids: comment_ids,
          total: comment_total,
        );
      },
    );
    DioClient().instance.interceptors.add(interceptor);
  });
  tearDown(() {
    DioClient().instance.interceptors.remove(interceptor);
    Get.reset();
  });
  tearDownAll(() async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    await storage_directory.delete(recursive: true);
  });

  testWidgets('当前章节仅用红边强调，文字正常且无左侧装饰图标或章节缩略图', (tester) async {
    final logic = _DirectoryLogic();
    await _mount(tester, logic);
    final current = _chapter(0);
    expect(current, findsOneWidget);
    final title = find.descendant(
      of: current,
      matching: find.text('Chapter 1'),
    );
    expect(title, findsOneWidget);
    expect(
      tester.widget<Text>(title).style!.color,
      ColorConstants.lightTextColor,
    );
    final material = tester.widget<Material>(
      find.descendant(of: current, matching: find.byType(Material)).first,
    );
    expect(material.color, ColorConstants.whiteColor);
    final outline = (material.shape! as RoundedRectangleBorder).side;
    expect(outline.color.r, ColorConstants.dangerColor.r);
    expect(outline.color.g, ColorConstants.dangerColor.g);
    expect(outline.color.b, ColorConstants.dangerColor.b);
    expect(outline.color.a, greaterThan(.4));
    final progress = tester.widget<LinearProgressIndicator>(
      find.byKey(const ValueKey('read_directory_current_progress')),
    );
    expect(progress.color, ColorConstants.themeColor);
    expect(progress.value, closeTo(.37, .001));
    expect(
      find.descendant(of: current, matching: find.byType(CachedNetworkImage)),
      findsNothing,
    );
    expect(
      find.descendant(of: current, matching: find.byType(Image)),
      findsNothing,
    );
    final icons = find.descendant(of: current, matching: find.byType(Icon));
    for (final element in icons.evaluate()) {
      final icon = find.byElementPredicate(
        (candidate) => identical(candidate, element),
      );
      expect(
        tester.getCenter(icon).dx,
        greaterThan(tester.getCenter(current).dx),
      );
    }
    expect(find.byKey(_continue_key), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _export_preview(tester, 'directory_normal_390_light');
  });

  testWidgets('封面背景贯穿顶部和Tab下方，日夜均与第一屏Hero相同并保留白字投影', (tester) async {
    for (final dark in [false, true]) {
      await _mount(tester, _DirectoryLogic(), dark: dark);
      final backdrop = find.byKey(
        const ValueKey('read_directory_header_backdrop'),
      );
      final backdrop_rect = tester.getRect(backdrop);
      final tab_rect = tester.getRect(find.byType(TabBar));
      final close_rect = tester.getRect(
        find.byKey(const ValueKey('read_directory_close')),
      );
      expect(backdrop_rect.top, lessThanOrEqualTo(close_rect.top));
      expect(backdrop_rect.bottom, greaterThan(tab_rect.bottom));
      final background = tester.widget<ColoredBox>(
        find.descendant(of: backdrop, matching: find.byType(ColoredBox)).first,
      );
      expect(background.color, WorkIntroductionHeroStyle.poster_background);
      final scrim = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('read_directory_header_scrim')),
      );
      final gradient = (scrim.decoration as BoxDecoration).gradient!;
      expect(gradient, isA<LinearGradient>());
      final linear_gradient = gradient as LinearGradient;
      expect(linear_gradient.begin, Alignment.topCenter);
      expect(linear_gradient.end, Alignment.bottomCenter);
      expect(linear_gradient.colors, WorkIntroductionHeroStyle.scrim_colors);
      expect(linear_gradient.stops, WorkIntroductionHeroStyle.scrim_stops);
      final title = tester.widget<Text>(
        find.byKey(const ValueKey('directory_book_title')),
      );
      expect(title.style!.color, ColorConstants.whiteColor);
      expect(title.style!.shadows, WorkIntroductionHeroStyle.title_shadows);
      expect(find.byType(BookHeaderBackdrop), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _export_preview(
        tester,
        dark ? 'directory_normal_390_dark' : 'directory_normal_390_light',
      );
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('章节详情书评保留左右滑动切页，回到章节仍保留目录位置', (tester) async {
    await _mount(tester, _DirectoryLogic());
    final tab_view = find.byKey(_tab_view_key);
    expect(tab_view, findsOneWidget);
    final controller = tester.widget<TabBarView>(tab_view).controller!;
    expect(controller.index, 0);
    final catalog = _catalog_controller(tester);
    catalog.jumpTo(280);
    await tester.pumpAndSettle();
    final before = catalog.offset;
    await tester.drag(tab_view, const Offset(-320, 0));
    await tester.pumpAndSettle();
    expect(controller.index, 1);
    await tester.drag(tab_view, const Offset(-320, 0));
    await tester.pumpAndSettle();
    expect(controller.index, 2);
    await tester.drag(tab_view, const Offset(320, 0));
    await tester.pumpAndSettle();
    await tester.drag(tab_view, const Offset(320, 0));
    await tester.pumpAndSettle();
    expect(controller.index, 0);
    expect(_catalog_controller(tester).offset, closeTo(before, .1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('详情不重复作品统计，分类去重且完整保留简介段落和段内换行', (tester) async {
    const first_paragraph = 'A promise changes everything.\nA quiet life ends.';
    const second_paragraph =
        'Beyond the ruined city, a new chapter begins. '
        'The final sentence must remain available in the complete synopsis.';
    await _mount(
      tester,
      _DirectoryLogic(
        tags: const [' Fantasy ', 'Fantasy', 'Progression Fantasy'],
        description: '  $first_paragraph\r\n\r\n$second_paragraph  ',
      ),
      size: const Size(320, 700),
      scale: 2,
    );
    await tester.tap(find.byType(Tab).at(1));
    await tester.pumpAndSettle();
    final details = find.byType(BookIntroduction);
    expect(details, findsOneWidget);
    expect(
      find.descendant(of: details, matching: find.byType(WorkHeroStatsRow)),
      findsNothing,
    );
    for (final value in [
      '9.81',
      '10.4K',
      '42.9K',
      '185,320',
      '1,509 reviews',
    ]) {
      expect(
        find.descendant(of: details, matching: find.text(value)),
        findsNothing,
      );
    }
    expect(
      find.byKey(const ValueKey('directory_details_genres_heading')),
      findsOneWidget,
    );
    final genres = find.byKey(const ValueKey('directory_details_genres'));
    expect(
      find.descendant(of: genres, matching: find.text('Fantasy')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: genres, matching: find.text('Progression Fantasy')),
      findsOneWidget,
    );
    for (final entry in [first_paragraph, second_paragraph].asMap().entries) {
      final paragraph = find.byKey(
        ValueKey('directory_details_paragraph_${entry.key}'),
      );
      await tester.scrollUntilVisible(
        paragraph,
        180,
        scrollable: find.descendant(
          of: details,
          matching: find.byType(Scrollable),
        ),
      );
      final text = tester.widget<Text>(paragraph);
      expect(text.data, entry.value);
      expect(text.maxLines, isNull);
      expect(text.overflow, isNull);
    }
    expect(comment_requests, isEmpty);
    expect(tester.takeException(), isNull);
    await _export_preview(tester, 'directory_details_320_700_2.0_light');
    if (_preview_dir.isNotEmpty) {
      await _mount(
        tester,
        _DirectoryLogic(
          tags: const ['Fantasy', 'Progression Fantasy'],
          description: '$first_paragraph\n\n$second_paragraph',
        ),
      );
      await tester.tap(find.byType(Tab).at(1));
      await tester.pumpAndSettle();
      final scroll = tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(BookIntroduction),
          matching: find.byType(Scrollable),
        ),
      );
      scroll.position.jumpTo(0);
      await tester.pumpAndSettle();
      await _export_preview(tester, 'directory_details_390_light');
    }
  });

  for (final scenario in [
    (count: null, size: const Size(390, 844), scale: 1.0),
    (count: 0, size: const Size(390, 844), scale: 1.0),
    (count: 1509, size: const Size(390, 844), scale: 1.0),
    (count: 1509, size: const Size(320, 700), scale: 2.0),
    (count: 1000000, size: const Size(844, 390), scale: 1.0),
  ]) {
    testWidgets('评论Tab只显示图标和精简总数，零或未知回退文字 $scenario', (tester) async {
      await _mount(
        tester,
        _DirectoryLogic(review_count: scenario.count),
        size: scenario.size,
        scale: scenario.scale,
      );
      final tab = find.byType(Tab).at(2);
      final expected = (scenario.count ?? 0) > 0
          ? NumberFormat.compact(locale: 'en').format(scenario.count)
          : 'Reviews';
      final label = find.descendant(of: tab, matching: find.byType(Text));
      expect(label, findsOneWidget);
      expect(tester.widget<Text>(label).data, expected);
      expect(
        find.descendant(
          of: tab,
          matching: find.byIcon(Icons.chat_bubble_outline_rounded),
        ),
        findsOneWidget,
      );
      expect(
        tester.renderObject<RenderParagraph>(label).didExceedMaxLines,
        isFalse,
      );
      expect(comment_requests, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('评论Tab首次进入才请求并直接嵌入共用评论，触底加载下一页', (tester) async {
    comment_ids = List.generate(22, (index) => index + 1);
    comment_total = 22;
    final logic = _DirectoryLogic();
    await _mount(tester, logic);
    expect(comment_requests, isEmpty);
    await tester.tap(find.byType(Tab).at(1));
    await tester.pumpAndSettle();
    expect(comment_requests, isEmpty);
    await tester.tap(find.byType(Tab).at(2));
    await tester.pumpAndSettle();
    expect(comment_requests, hasLength(1));
    expect(comment_requests.single.path, endsWith('novel_comment/inquire'));
    expect(_comment_parameters(comment_requests.single)['novel_id'], 1);
    expect(_comment_parameters(comment_requests.single)['page'], 1);
    final sheet = find.byType(CommentSheet);
    expect(sheet, findsOneWidget);
    final shared = tester.widget<CommentSheet>(sheet);
    expect(shared.embedded, isTrue);
    expect(shared.active, isTrue);
    expect(shared.is_dark, isFalse);
    expect(find.byType(CommentHeader), findsNothing);
    expect(find.byType(ReadCommentSection), findsNothing);
    expect(find.byKey(const ValueKey('read_comments_count')), findsNothing);
    expect(find.byKey(const ValueKey('read_comments_all')), findsNothing);
    for (final element
        in find
            .descendant(of: sheet, matching: find.byType(Divider))
            .evaluate()) {
      final divider = find.byElementPredicate(
        (candidate) => identical(candidate, element),
      );
      expect(
        find.ancestor(of: divider, matching: find.byType(CommentItem)),
        findsWidgets,
      );
    }
    expect(find.byType(CommentInput), findsOneWidget);
    expect(logic.review_count, 22);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('directory_book_hero')),
        matching: find.text('22 reviews'),
      ),
      findsOneWidget,
    );
    final review_tab = find.byType(Tab).at(2);
    expect(
      find.descendant(of: review_tab, matching: find.text('22')),
      findsOneWidget,
    );
    final list = find.descendant(of: sheet, matching: find.byType(ListView));
    final controller = tester.widget<ListView>(list).controller!;
    expect(controller.position.maxScrollExtent, greaterThan(0));
    await tester.fling(list, const Offset(0, -4000), 3000);
    await tester.pumpAndSettle();
    expect(comment_requests, hasLength(2));
    expect(_comment_parameters(comment_requests.last)['page'], 2);
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) => widget is CommentItem && widget.comment.id == 22,
      ),
      findsOneWidget,
    );
    final before = controller.offset;
    final comment_state = tester.state(sheet);
    await tester.tap(find.byKey(const ValueKey('comment_input_preview')));
    await tester.pumpAndSettle();
    final editor = find.byType(TextField).hitTestable();
    expect(editor, findsOneWidget);
    expect(tester.widget<TextField>(editor).focusNode!.hasFocus, isTrue);
    await tester.tap(find.byType(Tab).at(1));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('comment_send_button_editor')).hitTestable(),
      findsNothing,
    );
    expect(
      tester
          .widgetList<TextField>(find.byType(TextField))
          .every((field) => !(field.focusNode?.hasFocus ?? false)),
      isTrue,
    );
    await tester.tap(find.byType(Tab).at(2));
    await tester.pumpAndSettle();
    expect(tester.state(sheet), same(comment_state));
    expect(tester.widget<ListView>(list).controller, same(controller));
    expect(controller.offset, closeTo(before, .1));
    expect(comment_requests, hasLength(2));
    expect(tester.takeException(), isNull);
    await _export_preview(tester, 'directory_comments_390_light');
  });

  testWidgets('评论键盘不抬高整张目录，横屏收起顶部且竖屏保留Tab', (tester) async {
    comment_ids = List.generate(5, (index) => index + 1);
    comment_total = 5;
    for (final size in [const Size(844, 390), const Size(390, 844)]) {
      comment_requests.clear();
      final logic = _DirectoryLogic();
      await _mount(tester, logic, size: size);
      tester.widget<TabBarView>(find.byKey(_tab_view_key)).controller!.index =
          2;
      await tester.pumpAndSettle();
      expect(comment_requests, hasLength(1));
      final sheet = find.byType(CommentSheet);
      final comment_state = tester.state(sheet);
      final bounds = tester.getRect(find.byType(ReadDirectorySheet));
      await tester.tap(find.byKey(const ValueKey('comment_input_preview')));
      await tester.pumpAndSettle();
      await _mount(tester, logic, size: size, keyboard_height: 240);
      expect(tester.state(sheet), same(comment_state));
      expect(tester.getRect(find.byType(ReadDirectorySheet)), bounds);
      expect(find.byKey(const ValueKey('directory_book_hero')), findsNothing);
      expect(find.byType(CommentInput), findsOneWidget);
      final list = find.descendant(of: sheet, matching: find.byType(ListView));
      expect(list, findsOneWidget);
      expect(tester.getSize(list).height, greaterThan(0));
      final editor = find.byType(TextField).hitTestable();
      expect(editor, findsOneWidget);
      expect(tester.widget<TextField>(editor).focusNode!.hasFocus, isTrue);
      final editor_bounds = tester.getRect(editor);
      expect(tester.getRect(list).top, lessThan(editor_bounds.top));
      expect(editor_bounds.bottom, lessThanOrEqualTo(size.height - 240));
      if (size.height < 500) {
        expect(find.byType(TabBar), findsNothing);
        expect(
          find.byKey(const ValueKey('read_directory_close')),
          findsNothing,
        );
      } else {
        expect(find.byType(TabBar), findsOneWidget);
        expect(
          find.byKey(const ValueKey('read_directory_close')),
          findsOneWidget,
        );
      }
      expect(comment_requests, hasLength(1));
      expect(tester.takeException(), isNull);
      await _export_preview(
        tester,
        size.height < 500
            ? 'directory_comments_landscape_keyboard_240'
            : 'directory_comments_portrait_keyboard_240',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('当前章部分可见不显示定位，完全离屏后可动画回到当前章', (tester) async {
    await _mount(tester, _DirectoryLogic());
    final controller = _catalog_controller(tester);
    final height = tester.getSize(_chapter(0)).height;
    controller.jumpTo(height / 2);
    await tester.pumpAndSettle();
    expect(
      tester.widget<PositioningButton>(find.byKey(_position_key)).show,
      isFalse,
    );
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(
      tester.widget<PositioningButton>(find.byKey(_position_key)).show,
      isTrue,
    );
    final before = controller.offset;
    await tester.tap(find.byKey(_position_key));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.offset, lessThan(before));
    expect(controller.offset, greaterThan(0));
    await tester.pumpAndSettle();
    expect(
      tester.widget<PositioningButton>(find.byKey(_position_key)).show,
      isFalse,
    );
    expect(
      tester
          .getRect(_chapter(0))
          .overlaps(tester.getRect(find.byKey(_catalog_key))),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('三百章长标题目录可初次定位第268章，远距离离开后仍可返回', (tester) async {
    await _mount(
      tester,
      _DirectoryLogic(current: 267, count: 300, long_titles: true),
    );
    final current = _chapter(267);
    expect(current, findsOneWidget);
    expect(
      tester
          .getRect(current)
          .overlaps(tester.getRect(find.byKey(_catalog_key))),
      isTrue,
    );
    expect(
      tester.widget<PositioningButton>(find.byKey(_position_key)).show,
      isFalse,
    );
    _catalog_controller(tester).jumpTo(0);
    await tester.pumpAndSettle();
    expect(
      tester.widget<PositioningButton>(find.byKey(_position_key)).show,
      isTrue,
    );
    await tester.tap(find.byKey(_position_key));
    await tester.pumpAndSettle();
    expect(current, findsOneWidget);
    expect(
      tester
          .getRect(current)
          .overlaps(tester.getRect(find.byKey(_catalog_key))),
      isTrue,
    );
    expect(
      tester.widget<PositioningButton>(find.byKey(_position_key)).show,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('继续阅读只关闭弹窗，不重新跳章或清零现有进度', (tester) async {
    final selected = <int>[];
    var resumed = 0;
    final logic = _DirectoryLogic(current: 12);
    await _mount(
      tester,
      logic,
      modal: true,
      on_chapter_tap: selected.add,
      on_continue: () => resumed++,
    );
    expect(_chapter(12).hitTestable(), findsOneWidget);
    await tester.tap(find.byKey(_continue_key));
    await tester.pumpAndSettle();
    expect(resumed, 1);
    expect(selected, isEmpty);
    expect(logic.current_chapter_index.value, 12);
    expect(find.byType(ReadDirectorySheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('倒序排序后点击条目仍回调真实章节索引', (tester) async {
    final selected = <int>[];
    await _mount(
      tester,
      _DirectoryLogic(),
      modal: true,
      on_chapter_tap: selected.add,
    );
    await tester.tap(find.byKey(const ValueKey('read_directory_sort')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Newest first'));
    await tester.pumpAndSettle();
    _catalog_controller(tester).jumpTo(0);
    await tester.pumpAndSettle();
    expect(_chapter(39).hitTestable(), findsOneWidget);
    expect(
      tester.getTopLeft(_chapter(39)).dy,
      lessThan(tester.getTopLeft(_chapter(38)).dy),
    );
    await tester.tap(_chapter(39));
    await tester.pumpAndSettle();
    expect(selected, [39]);
    expect(find.byType(ReadDirectorySheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('搜索保留原章节索引，定位可清空筛选返回当前章', (tester) async {
    final selected = <int>[];
    await _mount(
      tester,
      _DirectoryLogic(),
      modal: true,
      on_chapter_tap: selected.add,
    );
    await tester.tap(
      find.byKey(const ValueKey('read_directory_search_toggle')),
    );
    await tester.pumpAndSettle();
    final field = find.byKey(const ValueKey('read_directory_search_field'));
    expect(field, findsOneWidget);
    await tester.enterText(field, 'chapter 27');
    await tester.pumpAndSettle();
    expect(_chapter(26).hitTestable(), findsOneWidget);
    expect(_chapter(0), findsNothing);
    expect(
      tester.widget<PositioningButton>(find.byKey(_position_key)).show,
      isTrue,
    );
    await tester.tap(find.byKey(_position_key));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field).controller!.text, isEmpty);
    expect(_chapter(0).hitTestable(), findsOneWidget);
    expect(
      tester.widget<PositioningButton>(find.byKey(_position_key)).show,
      isFalse,
    );
    await tester.enterText(field, 'chapter 27');
    await tester.pumpAndSettle();
    await tester.tap(_chapter(26));
    await tester.pumpAndSettle();
    expect(selected, [26]);
    expect(find.byType(ReadDirectorySheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('空目录不显示定位且继续阅读不执行无效跳转', (tester) async {
    var resumed = 0;
    await _mount(
      tester,
      _DirectoryLogic(count: 0),
      modal: true,
      on_continue: () => resumed++,
    );
    final position = find.byKey(_position_key);
    if (position.evaluate().isNotEmpty) {
      expect(tester.widget<PositioningButton>(position).show, isFalse);
    }
    await tester.tap(find.byKey(_continue_key));
    await tester.pumpAndSettle();
    expect(resumed, 0);
    expect(find.byType(ReadDirectorySheet), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('当前章不在筛选结果内时，切换排序仍保留搜索条件', (tester) async {
    await _mount(tester, _DirectoryLogic(current: 12));
    await tester.tap(
      find.byKey(const ValueKey('read_directory_search_toggle')),
    );
    await tester.pumpAndSettle();
    final field = find.byKey(const ValueKey('read_directory_search_field'));
    await tester.enterText(field, 'chapter 27');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('read_directory_sort')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Newest first'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field).controller!.text, 'chapter 27');
    expect(_chapter(26).hitTestable(), findsOneWidget);
    expect(_chapter(12), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('搜索无结果时仍能定位当前章，清空筛选后精确返回', (tester) async {
    await _mount(tester, _DirectoryLogic(current: 12));
    await tester.tap(
      find.byKey(const ValueKey('read_directory_search_toggle')),
    );
    await tester.pumpAndSettle();
    final field = find.byKey(const ValueKey('read_directory_search_field'));
    await tester.enterText(field, 'no chapter matches this phrase');
    await tester.pumpAndSettle();
    expect(_chapter(12), findsNothing);
    expect(
      tester.widget<PositioningButton>(find.byKey(_position_key)).show,
      isTrue,
    );
    await tester.tap(find.byKey(_position_key));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field).controller!.text, isEmpty);
    expect(_chapter(12).hitTestable(), findsOneWidget);
    expect(
      tester.widget<PositioningButton>(find.byKey(_position_key)).show,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('横屏390高度弹出240高度键盘后搜索与目录仍可操作', (tester) async {
    await _mount(
      tester,
      _DirectoryLogic(),
      size: const Size(844, 390),
      dark: true,
      modal: true,
      keyboard_height: 240,
    );
    await tester.tap(
      find.byKey(const ValueKey('read_directory_search_toggle')),
    );
    await tester.pumpAndSettle();
    final field = find.byKey(const ValueKey('read_directory_search_field'));
    expect(field.hitTestable(), findsOneWidget);
    await tester.enterText(field, 'chapter 2');
    await tester.pumpAndSettle();
    expect(find.byKey(_catalog_key).hitTestable(), findsOneWidget);
    expect(tester.getSize(find.byKey(_catalog_key)).height, greaterThan(0));
    expect(tester.takeException(), isNull);
    await _export_preview(tester, 'directory_landscape_keyboard_240');
  });

  for (final (size, dark, scale, language) in [
    (const Size(390, 844), false, 1.0, 'en'),
    (const Size(320, 700), false, 1.0, 'en'),
    (const Size(844, 390), true, 1.0, 'en'),
    (const Size(466, 678), true, 2.0, 'zh'),
    (const Size(951, 669), false, 1.6, 'en'),
  ]) {
    testWidgets('目录适配 $size / $language / ${scale}x 且列表与续读按钮始终可见', (
      tester,
    ) async {
      await _mount(
        tester,
        _DirectoryLogic(long_titles: true),
        size: size,
        dark: dark,
        scale: scale,
        language: language,
      );
      expect(find.byKey(_catalog_key).hitTestable(), findsOneWidget);
      expect(find.byKey(_continue_key).hitTestable(), findsOneWidget);
      final list = tester.getRect(find.byKey(_catalog_key));
      final button = tester.getRect(find.byKey(_continue_key));
      expect(list.height, greaterThan(40));
      expect(list.bottom, lessThanOrEqualTo(button.top));
      expect(button.left, greaterThanOrEqualTo(0));
      expect(button.right, lessThanOrEqualTo(size.width));
      expect(button.bottom, lessThanOrEqualTo(size.height));
      expect(tester.takeException(), isNull);
      await _export_preview(
        tester,
        'directory_${size.width.toInt()}_${size.height.toInt()}_${language}_${scale}_${dark ? 'dark' : 'light'}',
      );
    });
  }
}
