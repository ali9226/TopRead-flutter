// ignore_for_file: non_constant_identifier_names

import 'dart:io';
import 'dart:ui' as ui;

import 'package:app/components/content_category_tag/index.dart';
import 'package:app/components/work_detail_skeleton/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/layout_config.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/detail/index.dart';
import 'package:app/pages/comics/detail/logic.dart';
import 'package:app/pages/comics/detail/style.dart';
import 'package:app/pages/comics/reader/image_page.dart';
import 'package:app/pages/comics/reader/index.dart';
import 'package:app/pages/comics/reader/logic.dart';
import 'package:app/pages/comics/style.dart';
import 'package:app/pages/comics/widgets/empty_state.dart';
import 'package:app/pages/comics/widgets/comic_card.dart';
import 'package:app/pages/comics/widgets/grid_skeleton.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Assets extends AssetLoader {
  const _Assets();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {
    'comics': {
      'loading': 'Loading',
      'unavailable': 'Unavailable',
      'retry': 'Retry',
      'read': 'Read',
      'retry_image': 'Retry image',
      'reader_page': 'Page {page}',
      'chapters': 'Chapters',
      'comments_tab': 'Comments',
      'about': 'About',
      'ongoing': 'Ongoing',
      'chapter_count': '{count} chapters',
      'collect': 'Save',
      'share': 'Share',
    },
  };
}

class _LoadingDetail extends ComicDetailLogic {
  _LoadingDetail() : super(42);
  int calls = 0;

  @override
  Future<void> load({String? language}) async {
    calls++;
  }

  @override
  Future<void> load_similar() async {}
}

class _LoadingReader extends ComicReaderLogic {
  @override
  Future<void> load(int chapter_id, {int? initial_page}) async {}
  @override
  Future<void> flush() async {}
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
    if (Platform.environment['COMIC_SKELETON_CAPTURE'] == '1') {
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      final font = File('/System/Library/Fonts/Supplemental/Arial.ttf');
      if (font.existsSync()) {
        await (FontLoader('Roboto')..addFont(
              Future.value(ByteData.sublistView(font.readAsBytesSync())),
            ))
            .load();
      }
    }
  });
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  Future<void> mount(
    WidgetTester tester,
    Widget child, {
    double width = 390,
    bool dark = false,
    String language = 'en',
    double text_scale = 1,
    bool reduce_motion = true,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      EasyLocalization(
        key: ValueKey('$dark-$language-$width-$text_scale-$reduce_motion'),
        supportedLocales: const [Locale('en'), Locale('zh')],
        path: 'unused',
        assetLoader: const _Assets(),
        startLocale: Locale(language),
        fallbackLocale: const Locale('en'),
        saveLocale: false,
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            theme: ThemeData(
              brightness: dark ? Brightness.dark : Brightness.light,
            ),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(text_scale),
                disableAnimations: reduce_motion,
              ),
              child: child!,
            ),
            home: child,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  for (final dark in [false, true]) {
    testWidgets('漫画详情加载使用完整几何且失败可重试 $dark', (tester) async {
      final logic = _LoadingDetail();
      addTearDown(logic.dispose);
      await mount(
        tester,
        ComicDetailPage(comic_id: 42, controller: logic),
        width: 840,
        dark: dark,
      );
      expect(find.byType(WorkDetailSkeleton), findsOneWidget);
      final skeleton = tester.widget<WorkDetailSkeleton>(
        find.byType(WorkDetailSkeleton),
      );
      expect(skeleton.kind, WorkDetailSkeletonKind.comic);
      expect(skeleton.on_back, isNotNull);
      expect(
        tester.getSize(find.byType(WorkDetailSkeleton)).width,
        ComicDetailStyle.page_max_width,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);

      logic.loading = false;
      logic.error = 'Connection interrupted';
      logic.emit();
      await tester.pump();
      expect(find.byType(WorkDetailSkeleton), findsNothing);
      expect(find.byType(ComicsEmptyState), findsOneWidget);
      expect(find.text('Connection interrupted'), findsOneWidget);
      final initial_calls = logic.calls;
      await tester.tap(find.text('Retry'));
      expect(logic.calls, initial_calls + 1);
    });

    testWidgets('漫画章节首屏占满实际阅读视口 $dark', (tester) async {
      final logic = _LoadingReader();
      addTearDown(logic.dispose);
      await mount(
        tester,
        ComicReaderPage(chapter_id: 1, controller: logic),
        dark: dark,
      );
      expect(find.byType(ComicReaderSkeleton), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        tester.getSize(
          find.byKey(const ValueKey('comic_reader_skeleton_canvas')),
        ),
        const Size(390, 844),
      );
      expect(tester.takeException(), isNull);
      // 页面销毁先释放 auto-read 与 brightness 会话，再销毁外部控制器。
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final language in ['en', 'zh']) {
    for (final text_scale in [1.0, 1.5]) {
      testWidgets('瀑布流三列等宽并跟随真实行盒 $language $text_scale', (tester) async {
        final expected_width =
            (600 - ComicCardStyle.grid_column_spacing * 2) / 3;
        await mount(
          tester,
          Scaffold(
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: expected_width,
                    child: ComicCard(
                      key: const ValueKey('loaded_comic_card'),
                      comic: ComicItem.from_json({
                        'id': 42,
                        'title': 'First\nSecond',
                        'description': 'Alpha\nBravo',
                        'categories': [
                          {'name': 'One'},
                          {'name': 'Two'},
                        ],
                      }),
                    ),
                  ),
                  const ComicsGridSkeleton(is_dark: false),
                ],
              ),
            ),
          ),
          width: 600,
          language: language,
          text_scale: text_scale,
        );
        for (var index = 0; index < 3; index++) {
          final cover = tester.getRect(
            find.byKey(ValueKey('comic_grid_skeleton_cover_$index')),
          );
          expect(cover.width, closeTo(expected_width, 0.01));
          expect(
            cover.height,
            closeTo(expected_width / ComicsStyle.cover_ratio, 0.01),
          );
          expect(
            cover.left,
            closeTo(
              index * (expected_width + ComicCardStyle.grid_column_spacing),
              0.01,
            ),
          );
        }
        final real_tag = tester.getSize(find.byType(ContentCategoryTag).first);
        final tag = tester.getSize(
          find.byKey(const ValueKey('comic_grid_skeleton_tag_0_0')),
        );
        expect(tag.height, closeTo(real_tag.height, 0.01));
        // 与真正渲染的两行标题/简介卡片比较，避免两套版式分别退化。
        expect(
          tester
              .getSize(find.byKey(const ValueKey('comic_grid_skeleton_card_0')))
              .height,
          closeTo(
            tester
                .getSize(find.byKey(const ValueKey('loaded_comic_card')))
                .height,
            0.1,
          ),
        );
        expect(tester.takeException(), isNull);
        // 减少动画开启后没有持续请求下一帧。
        await tester.pumpAndSettle();
        expect(tester.binding.hasScheduledFrame, isFalse);
      });
    }
  }

  testWidgets('窄屏大字标签自然换行且动画不改变几何', (tester) async {
    await mount(
      tester,
      const Scaffold(
        body: SingleChildScrollView(child: ComicsGridSkeleton(is_dark: true)),
      ),
      width: 220,
      dark: true,
      text_scale: 1.8,
      reduce_motion: false,
    );
    final card = find.byKey(const ValueKey('comic_grid_skeleton_card_0'));
    final initial = tester.getRect(card);
    final first_tag = tester.getRect(
      find.byKey(const ValueKey('comic_grid_skeleton_tag_0_0')),
    );
    final second_tag = tester.getRect(
      find.byKey(const ValueKey('comic_grid_skeleton_tag_0_1')),
    );
    expect(second_tag.top, greaterThan(first_tag.top));
    await tester.pump(const Duration(milliseconds: 450));
    expect(tester.getRect(card), initial);
    expect(tester.takeException(), isNull);
  });

  testWidgets('单张长图加载预留原始比例', (tester) async {
    await mount(
      tester,
      const Scaffold(
        body: SingleChildScrollView(
          child: ComicReaderImage(
            image: ComicImageData(
              image_url: 'https://example.test/comic-loading.jpg',
              width: 390,
              height: 1600,
            ),
            page_index: 0,
            width: 390,
            on_ratio: _ignore_ratio,
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(ComicReaderImage)),
      const Size(390, 1600),
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  // 只在人工复核时导出首屏，不改变产品页面或普通测试流程。
  if (Platform.environment['COMIC_SKELETON_CAPTURE'] == '1') {
    testWidgets('导出漫画网格与阅读加载预览', (tester) async {
      Future<void> capture(GlobalKey key, String name) async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('/tmp/novel_ui_review/$name.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      final grid_key = GlobalKey();
      await mount(
        tester,
        RepaintBoundary(
          key: grid_key,
          child: Scaffold(
            backgroundColor: ColorConstants.lightBackgroundColor,
            body: const SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: LayoutConfig.page_horizontal_padding,
                ),
                child: ComicsGridSkeleton(is_dark: false),
              ),
            ),
          ),
        ),
        width: 600,
        reduce_motion: false,
      );
      await tester.pump(const Duration(milliseconds: 450));
      await capture(grid_key, 'comic_grid_skeleton');

      final reader_key = GlobalKey();
      final reader = _LoadingReader();
      addTearDown(reader.dispose);
      await mount(
        tester,
        RepaintBoundary(
          key: reader_key,
          child: ComicReaderPage(chapter_id: 1, controller: reader),
        ),
        dark: true,
        reduce_motion: false,
      );
      await tester.pump(const Duration(milliseconds: 450));
      await capture(reader_key, 'comic_reader_skeleton');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}

void _ignore_ratio(double ratio) {}
