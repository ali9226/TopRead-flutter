// ignore_for_file: non_constant_identifier_names

import 'dart:ui'
    show
        DisplayFeature,
        DisplayFeatureState,
        DisplayFeatureType,
        ImageByteFormat;

import 'package:app/models/comics.dart';
import 'package:app/pages/comics/detail/logic.dart';
import 'package:app/pages/comics/detail/widgets/detail_sheets.dart';
import 'package:app/pages/comics/widgets/chapter_sheet/index.dart';
import 'package:app/pages/comics/widgets/chapter_sheet/chapter_tile.dart';
import 'package:app/pages/comics/widgets/chapter_sheet/style.dart';
import 'package:app/components/positioning/index.dart';
import 'package:app/pages/comics/widgets/comic_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/config/color_config.dart';

class _Detail extends ComicDetailLogic {
  _Detail(int count) : super(42, progress_changes: ChangeNotifier()) {
    loading = false;
    detail = ComicDetail.from_json({
      'comic': {'id': 42, 'title': 'A comic', 'author_name': 'Author'},
      'languages': [
        {'id': 1, 'language': 'en', 'title': 'A comic'},
      ],
      'selected_language_id': 1,
      'chapters': List.generate(
        count,
        (index) => {
          'id': index + 1,
          'title': 'Chapter ${index + 1}',
          'page_count': 28,
          'status': 'published',
          'update_time': '2026-09-20T00:00:00.000Z',
        },
      ),
    });
  }
}

void main() {
  Future<void> mount(
    WidgetTester tester,
    Widget Function(BuildContext) builder, {
    bool dark = false,
    Size size = const Size(390, 844),
    double scale = 1,
    List<DisplayFeature> display_features = const [],
    bool constrained_theme = false,
    double? caller_width,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('catalog_surface_capture'),
        child: MaterialApp(
          theme: ThemeData(
            brightness: dark ? Brightness.dark : Brightness.light,
            bottomSheetTheme: constrained_theme
                ? const BottomSheetThemeData(
                    constraints: BoxConstraints(maxWidth: 320),
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(32)),
                    ),
                  )
                : null,
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              displayFeatures: display_features,
              padding: const EdgeInsets.only(bottom: 34),
              viewPadding: const EdgeInsets.only(bottom: 34),
            ),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => caller_width == null
                  ? builder(context)
                  : MediaQuery(
                      data: MediaQuery.of(
                        context,
                      ).copyWith(size: Size(caller_width, size.height)),
                      child: Builder(builder: builder),
                    ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  for (final count in [4, 100]) {
    testWidgets('$count章目录自然高度或受最大高度限制，底部安全区有背景', (tester) async {
      final logic = _Detail(count);
      addTearDown(logic.dispose);
      await mount(
        tester,
        (context) => TextButton(
          onPressed: () => show_comic_chapter_sheet(
            context,
            comic_id: 42,
            controller: logic,
          ),
          child: const Text('open'),
        ),
      );
      final rect = tester.getRect(
        find.byKey(const ValueKey('comic_chapter_sheet_surface')),
      );
      expect(rect.bottom, closeTo(844, 0.1));
      if (count == 4) {
        expect(rect.height, lessThan(844 * 0.85));
      } else {
        expect(
          rect.height,
          lessThanOrEqualTo(844 * ComicChapterSheetStyle.height_ratio + 0.1),
        );
      }
      expect(find.byType(ComicSurface), findsWidgets);
      expect(find.textContaining('2026-09-20'), findsNothing);
      expect(find.text('1'), findsNothing);
      final first_tile = find.byType(ComicDetailChapterTile).first;
      final arrow = find.descendant(
        of: first_tile,
        matching: find.byIcon(Icons.chevron_right_rounded),
      );
      expect(
        tester.getRect(arrow).right,
        closeTo(
          tester.getRect(first_tile).right -
              ComicChapterCatalogStyle.card_padding,
          0.1,
        ),
      );
      expect(
        tester
            .widget<Material>(
              find.byKey(const ValueKey('comic_chapter_sheet_surface')),
            )
            .color,
        ColorConstants.whiteColor,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final config in [
    (size: const Size(390, 844), scale: 1.0, current: 700),
    (size: const Size(320, 844), scale: 2.5, current: 1000),
    (size: const Size(466, 678), scale: 1.5, current: 700),
    (size: const Size(951, 669), scale: 1.5, current: 700),
  ]) {
    testWidgets('真实弹窗千章首开定位、排序和底部安全区 ${config.size}', (tester) async {
      final logic = _Detail(1000);
      addTearDown(logic.dispose);
      await mount(
        tester,
        (context) => TextButton(
          onPressed: () => show_comic_chapter_sheet(
            context,
            comic_id: 42,
            controller: logic,
            current_chapter_id: config.current,
          ),
          child: const Text('open'),
        ),
        size: config.size,
        scale: config.scale,
        display_features: config.size.width == 466 || config.size.width == 951
            ? [
                DisplayFeature(
                  bounds: Rect.fromLTWH(config.size.width - 84, 0, 84, 48),
                  type: DisplayFeatureType.cutout,
                  state: DisplayFeatureState.unknown,
                ),
              ]
            : [],
      );
      final surface = tester.getRect(
        find.byKey(const ValueKey('comic_chapter_sheet_surface')),
      );
      expect(surface.bottom, closeTo(config.size.height, 0.1));
      expect(
        surface.height,
        lessThanOrEqualTo(
          config.size.height * ComicChapterSheetStyle.height_ratio + 0.1,
        ),
      );
      final current = find.byKey(ValueKey(config.current));
      expect(current.hitTestable(), findsOneWidget);
      expect(tester.widget<ComicDetailChapterTile>(current).selected, isTrue);
      expect(tester.getRect(current).bottom, lessThan(config.size.height - 34));
      expect(
        find.byType(ComicDetailChapterTile).evaluate().length,
        lessThan(40),
      );
      final scroll = tester
          .widget<CustomScrollView>(
            find.byKey(const PageStorageKey('comic_chapters_scroll')),
          )
          .controller!;
      scroll.jumpTo(0);
      await tester.pumpAndSettle();
      final button = find.byType(PositioningButton);
      expect(tester.widget<PositioningButton>(button).show, isTrue);
      final region = tester.getRect(
        find.byKey(const ValueKey('comic_chapter_sheet_list_region')),
      );
      final button_rect = tester.getRect(button);
      expect(
        button_rect.right,
        closeTo(region.right - ComicChapterCatalogStyle.location_inset, 0.1),
      );
      expect(
        button_rect.bottom,
        closeTo(region.bottom - ComicChapterCatalogStyle.location_inset, 0.1),
      );
      await tester.tap(
        find.byKey(const ValueKey('comic_chapter_sheet_location')),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(scroll.position.isScrollingNotifier.value, isTrue);
      await tester.pumpAndSettle();
      expect(current.hitTestable(), findsOneWidget);
      expect(tester.widget<PositioningButton>(button).show, isFalse);
      await tester.tap(find.byTooltip('comics.sort_descending'));
      await tester.pumpAndSettle();
      expect(current.hitTestable(), findsOneWidget);
      expect(tester.widget<PositioningButton>(button).show, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final size in const [Size(390, 844), Size(951, 669)]) {
    for (final dark in [false, true]) {
      for (final count in [1, 100]) {
        testWidgets('真实弹窗覆盖局部限宽并绘制安全区像素 $size dark=$dark count=$count', (
          tester,
        ) async {
          final logic = _Detail(count);
          addTearDown(logic.dispose);
          await mount(
            tester,
            (context) => TextButton(
              onPressed: () => show_comic_chapter_sheet(
                context,
                comic_id: 42,
                controller: logic,
              ),
              child: const Text('open'),
            ),
            size: size,
            dark: dark,
            constrained_theme: true,
            caller_width: size.width > 600 ? 600 : null,
            display_features: size.width > 600
                ? [
                    DisplayFeature(
                      bounds: Rect.fromLTWH(size.width - 84, 0, 84, 48),
                      type: DisplayFeatureType.cutout,
                      state: DisplayFeatureState.unknown,
                    ),
                  ]
                : [],
          );
          final surface = tester.getRect(
            find.byKey(const ValueKey('comic_chapter_sheet_surface')),
          );
          expect(surface.left, 0);
          expect(surface.right, size.width);
          expect(surface.bottom, size.height);
          final bottom_sheet = tester.widget<BottomSheet>(
            find.byType(BottomSheet),
          );
          expect(
            bottom_sheet.backgroundColor,
            ComicChapterSheetStyle.background(dark),
          );
          expect(bottom_sheet.constraints!.minWidth, size.width);
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('catalog_surface_capture')),
          );
          final pixels = await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 1);
            final bytes = await image.toByteData(
              format: ImageByteFormat.rawRgba,
            );
            final result = <int>[];
            for (final x in [
              1,
              size.width.toInt() ~/ 2,
              size.width.toInt() - 2,
            ]) {
              final offset = ((size.height.toInt() - 2) * image.width + x) * 4;
              result.addAll(bytes!.buffer.asUint8List(offset, 4));
            }
            image.dispose();
            return result;
          });
          final expected = ComicChapterSheetStyle.background(dark);
          final expected_pixel = [
            (expected.r * 255).round(),
            (expected.g * 255).round(),
            (expected.b * 255).round(),
            255,
          ];
          expect(pixels, [
            ...expected_pixel,
            ...expected_pixel,
            ...expected_pixel,
          ]);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
    }
  }

  testWidgets('紧约束布局仍然把章节弹窗背景锚定窗口底部', (tester) async {
    final logic = _Detail(1);
    addTearDown(logic.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            padding: EdgeInsets.only(bottom: 34),
            viewPadding: EdgeInsets.only(bottom: 34),
          ),
          child: SizedBox.expand(
            child: ComicChapterSheet(comic_id: 42, controller: logic),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final surface = tester.getRect(
      find.byKey(const ValueKey('comic_chapter_sheet_surface')),
    );
    expect(surface.bottom, closeTo(844, 0.1));
    expect(surface.height, lessThan(844 * ComicChapterSheetStyle.height_ratio));
    expect(
      tester.getRect(find.byType(ComicDetailChapterTile)).bottom,
      lessThan(810),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('推荐查看全部使用目录卡片并正确打开作品，夜间安全区有背景', (tester) async {
    final comic = ComicItem.from_json({
      'id': 19,
      'title': 'A long comic title',
      'description': 'A complete description for this comic.',
      'author_name': 'Artist',
    });
    int? opened;
    await mount(
      tester,
      (context) => TextButton(
        onPressed: () =>
            show_comic_recommendations(context, [comic], (id) => opened = id),
        child: const Text('open'),
      ),
      dark: true,
    );
    final rect = tester.getRect(
      find.byKey(const ValueKey('comic_detail_sheet_surface')),
    );
    expect(rect.bottom, closeTo(844, 0.1));
    expect(find.byType(ComicSurface), findsOneWidget);
    await tester.tap(find.text(comic.title));
    await tester.pumpAndSettle();
    expect(opened, 19);
    expect(tester.takeException(), isNull);
  });
}
