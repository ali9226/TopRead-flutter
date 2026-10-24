// ignore_for_file: non_constant_identifier_names

import 'dart:ui';
import 'package:app/components/window_content_layout/index.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/detail/widgets/chapter_preview/chapter_card.dart';
import 'package:app/pages/comics/detail/widgets/chapter_preview/index.dart';
import 'package:app/pages/comics/widgets/chapter_location_button/index.dart';
import 'package:app/pages/comics/widgets/comic_image.dart';
import 'package:app/pages/comics/widgets/comic_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

List<ComicChapter> _chapters(int count) => List.generate(
  count,
  (index) => ComicChapter(
    id: index + 1,
    title: 'The journey beyond the stars · 遥远世界的旅途 ${index + 1}',
    page_count: 32,
    sort_order: index,
    status: 'published',
    update_time: '2026-09-20T00:00:00.000Z',
    images: const [],
  ),
);

Future<void> _mount(
  WidgetTester tester, {
  required List<ComicChapter> chapters,
  Size size = const Size(390, 844),
  double scale = 1,
  bool dark = false,
  bool cutout = false,
  bool completed = false,
  int? current_chapter_id = 1,
  double horizontal_padding = 0,
  VoidCallback? on_chapters,
  ValueChanged<ComicChapter>? on_open,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(scale),
          padding: EdgeInsets.only(right: cutout ? 84 : 0, bottom: 34),
          viewPadding: EdgeInsets.only(right: cutout ? 84 : 0, bottom: 34),
          displayFeatures: cutout
              ? [
                  DisplayFeature(
                    bounds: Rect.fromLTWH(size.width - 84, 0, 84, size.height),
                    type: DisplayFeatureType.cutout,
                    state: DisplayFeatureState.unknown,
                  ),
                ]
              : [],
        ),
        child: Scaffold(
          body: WindowContentLayout(
            max_width: 600,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ComicChapterPreview(
                  chapters: chapters,
                  completed: completed,
                  current_chapter_id: current_chapter_id,
                  horizontal_padding: horizontal_padding,
                  on_chapters: on_chapters ?? () {},
                  on_open: on_open ?? (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _rail => find.byKey(const ValueKey('comic_chapter_previews'));
Finder get _location =>
    find.byKey(const ValueKey('comic_chapter_preview_location'));

double _offset(WidgetTester tester) =>
    tester.widget<ListView>(_rail).controller!.offset;

void _expect_current_visible(WidgetTester tester, int chapter_id) {
  final viewport = tester.getRect(_rail);
  final current = tester.getRect(
    find.byKey(ValueKey('comic_chapter_preview_$chapter_id')),
  );
  expect(current.left, greaterThanOrEqualTo(viewport.left - 0.5));
  expect(current.right, lessThanOrEqualTo(viewport.right + 0.5));
}

void main() {
  for (final current in [4, 700]) {
    testWidgets('千章横向目录打开时直接定位第 $current 章且保持懒加载', (tester) async {
      await _mount(
        tester,
        chapters: _chapters(1000),
        current_chapter_id: current,
        horizontal_padding: 16,
      );
      _expect_current_visible(tester, current);
      expect(_offset(tester), greaterThan(0));
      final surface = find.byKey(ValueKey('comic_chapter_surface_$current'));
      expect(tester.widget<ComicSurface>(surface).selected, isTrue);
      final title = find.descendant(of: surface, matching: find.byType(Text));
      expect(title, findsOneWidget);
      expect(tester.getRect(surface).contains(tester.getCenter(title)), isTrue);
      expect(tester.widget<Text>(title).maxLines, 1);
      expect(tester.widget<Text>(title).overflow, TextOverflow.ellipsis);
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: title, matching: find.byType(RichText)),
      );
      expect(paragraph.didExceedMaxLines, isTrue);
      final image = tester.getRect(
        find.descendant(of: surface, matching: find.byType(ComicImage)),
      );
      final card = tester.getRect(surface);
      // 图片占据卡片的主要高度，标题只留一行与上下内边距。
      expect(image.height, greaterThan(card.height * 0.7));
      expect(image.height, greaterThan(image.width * 0.7));
      expect(card.bottom - tester.getRect(title).bottom, closeTo(10, 0.1));
      expect(
        tester
            .widget<ComicChapterPreviewCard>(
              find.byKey(ValueKey('comic_chapter_preview_$current')),
            )
            .selected,
        isTrue,
      );
      expect(
        find.byType(ComicChapterPreviewCard).evaluate().length,
        lessThan(12),
      );
      expect(
        tester.widget<ComicChapterLocationButton>(_location).show,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('离开当前章平滑显示定位入口，点击平滑返回并隐藏', (tester) async {
    await _mount(tester, chapters: _chapters(1000), current_chapter_id: 4);
    final initial_offset = _offset(tester);
    tester.widget<ListView>(_rail).controller!.jumpTo(initial_offset + 800);
    await tester.pump();
    expect(tester.widget<ComicChapterLocationButton>(_location).show, isTrue);
    await tester.pump(const Duration(milliseconds: 80));
    final opacity = find.descendant(
      of: _location,
      matching: find.byType(FadeTransition),
    );
    final scale = find.descendant(
      of: _location,
      matching: find.byType(ScaleTransition),
    );
    expect(tester.getSize(_location).width, greaterThan(0));
    expect(tester.getSize(_location).width, lessThan(44));
    expect(
      tester.widget<FadeTransition>(opacity).opacity.value,
      inExclusiveRange(0, 1),
    );
    expect(
      tester.widget<ScaleTransition>(scale).scale.value,
      inExclusiveRange(0.7, 1),
    );
    await tester.pumpAndSettle();
    final far_offset = _offset(tester);
    await tester.tap(_location);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(_offset(tester), lessThan(far_offset));
    expect(_offset(tester), greaterThan(initial_offset));
    expect(tester.widget<ComicChapterLocationButton>(_location).show, isFalse);
    expect(tester.getSize(_location).width, greaterThan(0));
    expect(tester.getSize(_location).width, lessThan(44));
    await tester.pumpAndSettle();
    expect(_offset(tester), closeTo(initial_offset, 0.5));
    expect(tester.getSize(_location).width, 0);
    _expect_current_visible(tester, 4);
    expect(tester.takeException(), isNull);
  });

  testWidgets('普通重建保留手动横滑位置，延迟读取进度与阅读章节变化才重新定位', (tester) async {
    final chapters = _chapters(1000);
    await _mount(tester, chapters: chapters, current_chapter_id: null);
    expect(_offset(tester), 0);
    await _mount(tester, chapters: chapters, current_chapter_id: 4);
    _expect_current_visible(tester, 4);
    await tester.drag(_rail, const Offset(-800, 0));
    await tester.pumpAndSettle();
    final user_offset = _offset(tester);
    await _mount(
      tester,
      chapters: _chapters(1000),
      current_chapter_id: 4,
      dark: true,
    );
    expect(_offset(tester), closeTo(user_offset, 0.5));
    expect(tester.widget<ComicChapterLocationButton>(_location).show, isTrue);
    await _mount(tester, chapters: chapters, current_chapter_id: 700);
    _expect_current_visible(tester, 700);
    expect(tester.widget<ComicChapterLocationButton>(_location).show, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('空目录后加载章节可定位，动画中切换目标与卸载不会回写旧位置', (tester) async {
    await _mount(tester, chapters: [], current_chapter_id: 4);
    await _mount(tester, chapters: _chapters(1000), current_chapter_id: 4);
    _expect_current_visible(tester, 4);
    await tester.drag(_rail, const Offset(-800, 0));
    await tester.pumpAndSettle();
    await tester.tap(_location);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    await _mount(tester, chapters: _chapters(1000), current_chapter_id: 700);
    _expect_current_visible(tester, 700);
    await tester.drag(_rail, const Offset(-800, 0));
    await tester.pumpAndSettle();
    await tester.tap(_location);
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Duo 窗口宽度变化后重新定位当前章并收起已显示的按钮，大字保持懒加载', (tester) async {
    final chapters = _chapters(1000);
    for (final size in const [Size(466, 678), Size(951, 669), Size(669, 951)]) {
      await _mount(
        tester,
        chapters: chapters,
        current_chapter_id: 700,
        size: size,
        scale: 2.5,
        cutout: true,
        horizontal_padding: 16,
      );
      _expect_current_visible(tester, 700);
      expect(
        tester.widget<ComicChapterLocationButton>(_location).show,
        isFalse,
      );
      expect(tester.getSize(_location).width, 0);
      await tester.drag(_rail, const Offset(-800, 0));
      await tester.pumpAndSettle();
      expect(tester.widget<ComicChapterLocationButton>(_location).show, isTrue);
      expect(tester.getRect(_location).width, greaterThanOrEqualTo(44));
      expect(
        find.byType(ComicChapterPreviewCard).evaluate().length,
        lessThan(15),
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('章节带横向懒加载，点击章节与完整目录各自触发', (tester) async {
    int? opened;
    var catalogs = 0;
    await _mount(
      tester,
      chapters: _chapters(1000),
      on_chapters: () => catalogs++,
      on_open: (chapter) => opened = chapter.id,
    );
    expect(
      find.byType(ComicChapterPreviewCard).evaluate().length,
      lessThan(10),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('comic_detail_chapters'))).right,
      closeTo(378, 0.1),
    );
    await tester.tap(find.byKey(const ValueKey('comic_chapter_preview_1')));
    expect(opened, 1);
    expect(find.textContaining('2026'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('comic_detail_chapters')));
    expect(catalogs, 1);
    await tester.drag(
      find.byKey(const ValueKey('comic_chapter_previews')),
      const Offset(-700, 0),
    );
    await tester.pumpAndSettle();
    final visible = tester
        .widgetList<ComicChapterPreviewCard>(
          find.byType(ComicChapterPreviewCard),
        )
        .toList();
    expect(visible.last.chapter.id, greaterThan(5));
    expect(
      find.byType(ComicChapterPreviewCard).evaluate().length,
      lessThan(15),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('空目录保留状态和完整目录入口', (tester) async {
    await _mount(tester, chapters: [], completed: true);
    expect(
      find.byKey(const ValueKey('comic_serialization_status')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('comic_detail_chapters')), findsOneWidget);
    expect(find.byType(ComicChapterPreviewCard), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final size in const [
    Size(320, 900),
    Size(466, 678),
    Size(951, 669),
    Size(669, 951),
  ]) {
    for (final dark in [false, true]) {
      testWidgets('章节预览 $size 日夜=$dark 大字和 Duo 安全区内可用', (tester) async {
        int? opened;
        await _mount(
          tester,
          chapters: _chapters(5),
          size: size,
          scale: 2.5,
          dark: dark,
          cutout: size.width > 320,
          on_open: (chapter) => opened = chapter.id,
        );
        await tester.tap(find.byKey(const ValueKey('comic_chapter_preview_1')));
        expect(opened, 1);
        final first = tester.getRect(
          find.byKey(const ValueKey('comic_chapter_preview_1')),
        );
        expect(
          first.right,
          lessThanOrEqualTo(size.width - (size.width > 320 ? 84 : 0)),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
