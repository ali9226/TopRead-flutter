// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:app/config/layout_config.dart';
import 'package:app/components/window_content_layout/index.dart';
import 'package:app/pages/comics/detail/widgets/action_bar.dart';
import 'package:app/models/comics.dart';
import 'package:app/models/language_info.dart';
import 'package:app/models/user_info.dart';
import 'package:app/pages/comics/detail/index.dart';
import 'package:app/pages/comics/detail/logic.dart';
import 'package:app/pages/comics/detail/style.dart';
import 'package:app/pages/comics/detail/widgets/about_section.dart';
import 'package:app/pages/comics/detail/widgets/chapter_list.dart';
import 'package:app/pages/comics/detail/widgets/hero_header.dart';
import 'package:app/pages/comics/detail/widgets/language_selector.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/tag_section/index.dart';
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

/// 只提供显示名称；布局回归不读取设备缓存，也不触发远端语言请求。
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
  // Fixtures own their initial data and intentionally skip storage restoration.
  // ignore: must_call_super
  void onInit() {}
}

const long_description =
    'Each page opens a new illustrated world and lets the reader explore a different horizon. '
    'Across mountains and quiet cities, the travelers discover stories that bring them together. '
    'Every chapter offers another reason to keep reading, with careful drawings and rich details. '
    'The journey continues through unexpected friendships and distant worlds. '
    'This long description verifies a continuous expansion without changing the underlying text. '
    'The last paragraph remains part of the same story, and the animation reveals it smoothly.';
ComicDetail _fixture(String language) => ComicDetail(
  comic: ComicItem(
    id: 42,
    title: language == 'zh'
        ? '在遥远世界寻找晨光的漫长旅途'
        : 'An Extraordinary Journey Through Distant Worlds and Unexpected Friendships',
    cover_url: '',
    author_id: 1,
    author_name: 'A Creator With a Long Name',
    categories: const <Map<String, dynamic>>[
      <String, dynamic>{'id': 1, 'name': 'Fantasy'},
      <String, dynamic>{'id': 2, 'name': 'A Long Adventure Category'},
    ],
    chapter_count: 1076,
    language_count: 4,
    status: 'published',
  ),
  languages: <ComicLanguage>[
    ComicLanguage(
      id: 7,
      language: language,
      title: language == 'zh'
          ? '在遥远世界寻找晨光的漫长旅途'
          : 'An Extraordinary Journey Through Distant Worlds and Unexpected Friendships',
      description: language == 'zh'
          ? List<String>.filled(12, '每一页都开启新的世界。旅人在山川与城市之间发现让彼此相遇的故事。').join()
          : long_description,
      cover_url: '',
    ),
    for (final code in <String>['en', 'zh', 'ja', 'ko'])
      if (code != language)
        ComicLanguage(
          id: <String>['en', 'zh', 'ja', 'ko'].indexOf(code) + 8,
          language: code,
          title: 'An illustrated journey',
          description: '',
          cover_url: '',
        ),
  ],
  selected_language_id: 7,
  chapters: List<ComicChapter>.generate(
    1076,
    (index) => ComicChapter(
      id: index + 1,
      title: language == 'zh'
          ? '第${index + 1}话 晨光'
          : 'Chapter ${index + 1}: Morning Light',
      page_count: 32,
      sort_order: index + 1,
      status: 'published',
      images: const <ComicImageData>[],
    ),
  ),
  is_collected: false,
  read_record: <String, dynamic>{
    'chapter_id': 12,
    'page_index': 4,
    'language': language,
    'comic_language_id': 7,
  },
);

class _Logic extends ComicDetailLogic {
  _Logic(String language) : super(42) {
    detail = _fixture(language);
    loading = false;
  }
  @override
  Future<void> load({String? language}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const output = String.fromEnvironment('COMIC_DETAIL_PREVIEW_DIR');
  const cover_file = String.fromEnvironment('COMIC_DETAIL_COVER_FILE');
  ui.Image? preview_cover;
  Widget? cover() => preview_cover == null
      ? null
      : RawImage(image: preview_cover, fit: BoxFit.contain);
  tearDownAll(() => preview_cover?.dispose());
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (call) async => call.method == 'getAll' ? <String, Object>{} : true,
        );
    await EasyLocalization.ensureInitialized();
    if (cover_file.isNotEmpty) {
      final codec = await ui.instantiateImageCodec(
        File(cover_file).readAsBytesSync(),
      );
      preview_cover = (await codec.getNextFrame()).image;
      codec.dispose();
    }
    if (output.isNotEmpty) {
      for (final entry in <String, String>{
        'PreviewLatin': '/System/Library/Fonts/Supplemental/Arial.ttf',
        'PreviewChinese': '/System/Library/Fonts/STHeiti Light.ttc',
        'PreviewKorean': '/System/Library/Fonts/AppleSDGothicNeo.ttc',
        'MaterialIcons':
            '.fvm/flutter_sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      }.entries) {
        await (FontLoader(entry.key)..addFont(
              Future<ByteData>.value(
                ByteData.sublistView(File(entry.value).readAsBytesSync()),
              ),
            ))
            .load();
      }
    }
  });
  setUp(() {
    Get.testMode = true;
    final user = Get.put<UserInformation>(UserInformation());
    user.saveUserInfo(
      UserInfo.fromJson(<String, dynamic>{'id': 1, 'debug': 2}),
    );
    Get.put<LanguageStore>(_LanguageStore());
  });
  tearDown(Get.reset);

  Future<void> mount(
    WidgetTester tester,
    Widget child, {
    bool dark = false,
    String language = 'en',
    double scale = 1,
    bool reduce_motion = false,
    GlobalKey? boundary,
    EdgeInsets? safe_padding,
  }) async {
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: EasyLocalization(
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
                fontFamily: output.isEmpty ? null : 'PreviewLatin',
                fontFamilyFallback: output.isEmpty
                    ? null
                    : const <String>['PreviewChinese', 'PreviewKorean'],
              ),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  padding: safe_padding ?? MediaQuery.paddingOf(context),
                  textScaler: TextScaler.linear(scale),
                  disableAnimations: reduce_motion,
                ),
                child: child!,
              ),
              home: child,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, GlobalKey key, String file) async {
    if (output.isEmpty) return;
    await tester.runAsync(() async {
      final image =
          await (key.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final destination = File('$output/$file');
      await destination.parent.create(recursive: true);
      await destination.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  for (final dark in <bool>[false, true]) {
    testWidgets('Duo保留区只约束控件，海报和底栏表面贯穿整窗 ${dark ? 'dark' : 'light'}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(466, 678);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await mount(
        tester,
        WindowLayoutScope(
          child: ComicDetailPage(
            comic_id: 42,
            controller: _Logic('en'),
            cover_image: const ColoredBox(color: Colors.orange),
          ),
        ),
        dark: dark,
        safe_padding: const EdgeInsets.only(right: 84, bottom: 34),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byKey(const ValueKey('comic_detail_cover'))).width,
        466,
      );
      expect(tester.getSize(find.byType(ComicDetailActionBar)).width, 466);
      for (final key in <String>[
        'comic_detail_back',
        'comic_detail_comments',
        'comic_detail_collect',
        'comic_detail_read',
      ]) {
        final rect = tester.getRect(find.byKey(ValueKey(key)));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(382));
      }
      // 模拟展开后实时增长视口，封面继续满幅，不复用收起态的旧宽度。
      tester.view.physicalSize = const Size(1048, 748);
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(const ValueKey('comic_detail_cover'))).width,
        1048,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('辅助文案在真实日夜主题的正文与章节表面均达到4.5:1', (tester) async {
    for (final dark in <bool>[false, true]) {
      late BuildContext painted_context;
      await mount(
        tester,
        Builder(
          builder: (context) {
            painted_context = context;
            return const SizedBox.shrink();
          },
        ),
        dark: dark,
      );
      expect(ComicDetailStyle.is_dark(painted_context), dark);
      final foreground = ComicDetailStyle.muted(painted_context);
      for (final background in <Color>[
        ComicDetailStyle.card_background(dark),
        dark ? ComicDetailStyle.surface_dark : ComicDetailStyle.surface_light,
      ]) {
        final painted = Color.alphaBlend(foreground, background);
        final high = painted.computeLuminance() > background.computeLuminance()
            ? painted.computeLuminance()
            : background.computeLuminance();
        final low = painted.computeLuminance() < background.computeLuminance()
            ? painted.computeLuminance()
            : background.computeLuminance();
        expect((high + 0.05) / (low + 0.05), greaterThanOrEqualTo(4.5));
      }
    }
  });
  for (final language in <String>['en', 'zh']) {
    for (final dark in <bool>[false, true]) {
      for (final width in <double>[320, 390]) {
        testWidgets(
          '详情 $language ${dark ? 'dark' : 'light'} ${width.toInt()}px 1.6x长文',
          (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = Size(width, 900);
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final key = GlobalKey();
            await mount(
              tester,
              ComicDetailPage(
                comic_id: 42,
                controller: _Logic(language),
                cover_image: cover(),
              ),
              dark: dark,
              language: language,
              scale: 1.6,
              boundary: key,
            );
            expect(tester.takeException(), isNull);
            expect(
              find.textContaining(language == 'zh' ? '第12话' : 'Chapter 12'),
              findsOneWidget,
            );
            final full_title = _fixture(language).comic.title;
            final title = tester.widget<Text>(find.text(full_title).first);
            expect(title.maxLines, isNull);
            expect(title.textAlign, TextAlign.center);
            final tags = tester.widget<ReadTagSection>(
              find.byType(ReadTagSection),
            );
            expect(tags.is_dark, dark);
            expect(tags.tag_list, <String>[
              'Fantasy',
              'A Long Adventure Category',
            ]);
            for (final button_finder in <Finder>[
              find.byKey(const ValueKey('comic_detail_read')),
              find.byKey(const ValueKey('comic_detail_collect')),
            ]) {
              final button = tester.widget<ButtonStyleButton>(button_finder);
              final shape = button.style!.shape!.resolve(<WidgetState>{});
              expect(
                (shape! as RoundedRectangleBorder).borderRadius,
                BorderRadius.circular(LayoutConfig.section_radius),
              );
            }
            expect(
              find.byType(ComicDetailChapterTile).evaluate().length,
              lessThan(20),
            );
            if (width == 390) {
              await capture(
                tester,
                key,
                'detail_${language}_${dark ? 'dark' : 'light'}_large.png',
              );
            }
            await tester.drag(
              find.byType(CustomScrollView),
              const Offset(0, -2200),
            );
            await tester.pumpAndSettle();
            expect(
              find.byType(ComicDetailChapterTile).evaluate().length,
              greaterThan(0),
            );
            expect(
              find.byType(ComicDetailChapterTile).evaluate().length,
              lessThan(20),
            );
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpAndSettle();
          },
        );
      }
    }
  }
  for (final dark in <bool>[false, true]) {
    testWidgets('默认字号390px真实封面 ${dark ? 'dark' : 'light'}', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await mount(
        tester,
        ComicDetailPage(
          comic_id: 42,
          controller: _Logic('en'),
          cover_image: cover(),
        ),
        dark: dark,
        boundary: key,
      );
      expect(tester.takeException(), isNull);
      await capture(
        tester,
        key,
        'detail_en_${dark ? 'dark' : 'light'}_normal.png',
      );
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();
      await capture(
        tester,
        key,
        'detail_en_${dark ? 'dark' : 'light'}_content.png',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
  for (final language in <String>['en', 'zh']) {
    for (final dark in <bool>[false, true]) {
      for (final width in <double>[320, 390]) {
        for (final scale in <double>[1, 1.6]) {
          testWidgets(
            '四语种标签垂直居中 $language ${dark ? 'dark' : 'light'} ${width.toInt()}px ${scale}x',
            (tester) async {
              tester.view.devicePixelRatio = 1;
              tester.view.physicalSize = Size(width, 900);
              addTearDown(tester.view.resetPhysicalSize);
              addTearDown(tester.view.resetDevicePixelRatio);
              String? selected_language;
              await mount(
                tester,
                Scaffold(
                  body: Padding(
                    padding: const EdgeInsets.all(20),
                    child: ComicDetailLanguageSelector(
                      detail: _fixture(language),
                      is_dark: dark,
                      on_selected: (value) => selected_language = value,
                    ),
                  ),
                ),
                dark: dark,
                language: language,
                scale: scale,
              );
              final chips = find.descendant(
                of: find.byType(ComicDetailLanguageSelector),
                matching: find.byWidgetPredicate(
                  (widget) =>
                      widget is Semantics &&
                      widget.properties.button == true &&
                      widget.properties.selected != null,
                ),
              );
              expect(chips, findsNWidgets(4));
              final heights = <double>[];
              final visual_heights = <double>[];
              for (final element in chips.evaluate()) {
                final chip = find.byWidget(element.widget);
                final text = find.descendant(
                  of: chip,
                  matching: find.byType(Text),
                );
                expect(text, findsOneWidget);
                final chip_rect = tester.getRect(chip);
                final text_rect = tester.getRect(text);
                heights.add(chip_rect.height);
                expect(chip_rect.height, greaterThanOrEqualTo(48));
                expect(chip_rect.width, lessThan(width - 40));
                expect(
                  text_rect.center.dy,
                  closeTo(chip_rect.center.dy, 0.5),
                  reason: '${tester.widget<Text>(text).data} must be centered',
                );
                expect(text_rect.left, greaterThan(chip_rect.left));
                expect(text_rect.right, lessThan(chip_rect.right));
              }
              for (final version in _fixture(language).languages) {
                final visual = find.byKey(
                  ValueKey('comic_language_visual_${version.id}'),
                );
                expect(visual, findsOneWidget);
                visual_heights.add(tester.getSize(visual).height);
                expect(tester.getSize(visual).height, greaterThanOrEqualTo(32));
              }
              expect(
                heights.every((height) => (height - heights.first).abs() < 0.5),
                isTrue,
              );
              expect(
                visual_heights.every(
                  (height) => (height - visual_heights.first).abs() < 0.5,
                ),
                isTrue,
                reason: '背景色块也必须等高，不能只让透明触摸区等高：$visual_heights',
              );
              expect(find.text('English'), findsOneWidget);
              expect(find.text('简体中文'), findsOneWidget);
              expect(find.text('日本語'), findsOneWidget);
              expect(find.text('한국어'), findsOneWidget);
              await tester.tap(find.text(language == 'en' ? '日本語' : 'English'));
              expect(selected_language, language == 'en' ? 'ja' : 'en');
              expect(tester.takeException(), isNull);
              await tester.pumpWidget(const SizedBox.shrink());
              await tester.pumpAndSettle();
            },
          );
        }
      }
    }
  }
  for (final dark in <bool>[false, true]) {
    testWidgets('满幅封面与无描边半透明导航 ${dark ? 'dark' : 'light'}', (tester) async {
      int back = 0, comments = 0;
      await mount(
        tester,
        Scaffold(
          body: CustomScrollView(
            slivers: <Widget>[
              ComicDetailHeroHeader(
                detail: _fixture('en'),
                is_dark: dark,
                on_back: () => back++,
                on_comments: () => comments++,
                cover_image: const SizedBox.expand(
                  child: ColoredBox(
                    key: ValueKey('fixture_complete_cover'),
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        ),
        dark: dark,
      );
      final back_finder = find.byKey(const ValueKey('comic_detail_back'));
      expect(tester.getSize(back_finder), const Size(48, 48));
      await tester.tap(back_finder);
      // 可视圆36px，但48px触摸区的角部也必须响应。
      await tester.tapAt(tester.getTopLeft(back_finder) + const Offset(2, 2));
      await tester.tap(find.byKey(const ValueKey('comic_detail_comments')));
      expect(back, 2);
      expect(comments, 1);
      final foreground = ComicDetailStyle.floating_foreground(dark);
      final background = ComicDetailStyle.floating_background(dark);
      expect(foreground, dark ? Colors.black : Colors.white);
      expect(background.a, closeTo(dark ? 0.78 : 0.56, 0.005));
      expect(background.r, dark ? 1 : 0);
      expect(background.g, dark ? 1 : 0);
      expect(background.b, dark ? 1 : 0);
      final visual = find.descendant(
        of: back_finder,
        matching: find.byWidgetPredicate(
          (widget) => widget is Material && widget.color == background,
        ),
      );
      expect(visual, findsOneWidget);
      expect(tester.getSize(visual), const Size(36, 36));
      final material = tester.widget<Material>(visual);
      expect(material.elevation, 0);
      if (material.shape is OutlinedBorder) {
        expect((material.shape! as OutlinedBorder).side, BorderSide.none);
      }
      final header = find.byType(ComicDetailHeroHeader);
      expect(
        find.descendant(of: header, matching: find.byType(ShaderMask)),
        findsNothing,
      );
      expect(
        find.descendant(
          of: header,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is DecoratedBox &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).gradient != null,
          ),
        ),
        findsNothing,
      );
      final cover_finder = find.byKey(const ValueKey('comic_detail_cover'));
      final cover_size = Size(
        tester.view.physicalSize.width / tester.view.devicePixelRatio,
        ComicDetailStyle.cover_height,
      );
      expect(tester.getSize(cover_finder), cover_size);
      final clip = tester.widget<ClipRRect>(
        find.byKey(const ValueKey('comic_detail_cover_art')),
      );
      expect(
        clip.borderRadius,
        const BorderRadius.vertical(
          bottom: Radius.circular(ComicDetailStyle.cover_radius),
        ),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('fixture_complete_cover'))),
        cover_size,
      );
      expect(tester.takeException(), isNull);
    });
    testWidgets('简介动画连续尺寸/渐隐/旋转 ${dark ? 'dark' : 'light'}', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await mount(
        tester,
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: ComicDetailAboutSection(
              description: long_description,
              is_dark: dark,
              is_cjk: false,
            ),
          ),
        ),
        dark: dark,
      );
      final size = find.byKey(const ValueKey('comic_about_size'));
      final collapsed = tester.getSize(size).height;
      await tester.tap(find.byKey(const ValueKey('comic_about_toggle')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 90));
      final middle = tester.getSize(size).height;
      expect(middle, greaterThan(collapsed));
      await tester.pumpAndSettle();
      final expanded = tester.getSize(size).height;
      expect(expanded, greaterThan(middle));
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.byKey(const ValueKey('comic_about_fade')),
            )
            .opacity,
        0,
      );
      expect(
        tester
            .widget<AnimatedRotation>(
              find.byKey(const ValueKey('comic_about_arrow')),
            )
            .turns,
        0.5,
      );
      await tester.tap(find.byKey(const ValueKey('comic_about_toggle')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 90));
      expect(tester.getSize(size).height, lessThan(expanded));
      expect(tester.getSize(size).height, greaterThan(collapsed));
      await tester.pumpAndSettle();
      expect(tester.getSize(size).height, closeTo(collapsed, 0.1));
      expect(tester.takeException(), isNull);
    });
  }
  for (final dimensions in <Size>[
    const Size(280, 400),
    const Size(480, 320),
    const Size(300, 300),
  ]) {
    for (final viewport in const <Size>[
      Size(466, 678),
      Size(669, 951),
      Size(951, 669),
    ]) {
      testWidgets(
        '满幅封面底部圆角 ${dimensions.width}×${dimensions.height} 窗口$viewport',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = viewport;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          // 不依赖外部网络：真实Image尺寸驱动RenderImage布局，而非固定占位框。
          final recorder = ui.PictureRecorder();
          Canvas(
            recorder,
          ).drawRect(Offset.zero & dimensions, Paint()..color = Colors.orange);
          final picture = recorder.endRecording();
          final image = picture.toImageSync(
            dimensions.width.toInt(),
            dimensions.height.toInt(),
          );
          picture.dispose();
          addTearDown(image.dispose);
          await mount(
            tester,
            Scaffold(
              body: CustomScrollView(
                slivers: <Widget>[
                  ComicDetailHeroHeader(
                    detail: _fixture('en'),
                    is_dark: false,
                    on_back: () {},
                    on_comments: () {},
                    cover_image: RawImage(image: image, fit: BoxFit.cover),
                  ),
                ],
              ),
            ),
          );
          final slot = find.byKey(const ValueKey('comic_detail_cover'));
          final art = find.byKey(const ValueKey('comic_detail_cover_art'));
          final expected = Size(viewport.width, ComicDetailStyle.cover_height);
          expect(tester.getSize(slot), expected);
          expect(tester.getSize(art), expected);
          expect(tester.getRect(art).center, tester.getRect(slot).center);
          expect(tester.getSize(find.byType(RawImage)), tester.getSize(art));
          expect(
            tester.widget<ClipRRect>(art).borderRadius,
            const BorderRadius.vertical(
              bottom: Radius.circular(ComicDetailStyle.cover_radius),
            ),
          );
          expect(
            tester.widget<RawImage>(find.byType(RawImage)).fit,
            BoxFit.cover,
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        },
      );
    }
  }
  testWidgets('减少动画偏好立即展开，短简介没有无效展开按钮', (tester) async {
    await mount(
      tester,
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: ComicDetailAboutSection(
            description: long_description,
            is_dark: false,
            is_cjk: false,
          ),
        ),
      ),
      reduce_motion: true,
    );
    await tester.tap(find.byKey(const ValueKey('comic_about_toggle')));
    await tester.pump();
    expect(
      tester
          .widget<TweenAnimationBuilder<double>>(
            find.byKey(const ValueKey('comic_about_size')),
          )
          .duration,
      Duration.zero,
    );
    expect(
      tester
          .widget<AnimatedRotation>(
            find.byKey(const ValueKey('comic_about_arrow')),
          )
          .duration,
      Duration.zero,
    );
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(const ValueKey('comic_about_fade')),
          )
          .duration,
      Duration.zero,
    );
    await mount(
      tester,
      const Scaffold(
        body: ComicDetailAboutSection(
          description: 'Short description',
          is_dark: false,
          is_cjk: false,
        ),
      ),
    );
    expect(find.byKey(const ValueKey('comic_about_toggle')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
