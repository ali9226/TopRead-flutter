// ignore_for_file: non_constant_identifier_names

import 'dart:ui' show DisplayFeature, DisplayFeatureType, DisplayFeatureState;
import 'package:app/components/window_content_layout/index.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/detail/logic.dart';
import 'package:app/pages/comics/detail/resume_record.dart';
import 'package:app/pages/comics/detail/widgets/chapter_catalog.dart';
import 'package:app/pages/comics/detail/widgets/chapter_list.dart';
import 'package:app/pages/comics/widgets/chapter_sheet/style.dart';
import 'package:app/components/positioning/index.dart';
import 'package:app/pages/comics/widgets/comic_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Logic extends ComicDetailLogic {
  _Logic({int count = 5, this.current = 2})
    : super(42, progress_changes: ChangeNotifier()) {
    loading = false;
    chapters = List.generate(
      count,
      (index) => ComicChapter(
        id: index + 1,
        title: 'Chapter ${index + 1}: A new beginning',
        page_count: 28,
        sort_order: index + 1,
        status: 'published',
        images: const [],
        update_time: index + 1 == current ? '2026-09-20T00:00:00.000Z' : '',
      ),
    );
  }
  final int current;
  late List<ComicChapter> chapters;
  int? opened;
  bool? resumed;
  @override
  List<ComicChapter> get readable_chapters => chapters;
  @override
  int get start_chapter_id => current;
  @override
  ComicResumeRecord get resume_record => ComicResumeRecord(
    chapter: chapters[current - 1],
    page_index: 7,
    record: const {},
  );
  @override
  void open_chapter(int chapter_id, {bool resume = false}) {
    opened = chapter_id;
    resumed = resume;
  }
}

Future<void> _mount(
  WidgetTester tester,
  _Logic logic, {
  double scale = 1,
  double width = 390,
  ScrollController? scroll,
  MediaQueryData? window_media,
  bool settle = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = window_media?.size ?? Size(width, 844);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data:
            window_media ??
            MediaQueryData(
              size: Size(width, 844),
              textScaler: TextScaler.linear(scale),
            ),
        child: Scaffold(
          body: PrimaryScrollController(
            controller: scroll ?? ScrollController(),
            child: window_media == null
                ? ComicChapterCatalog(logic: logic)
                : WindowContentLayout(
                    max_width: 600,
                    child: ComicChapterCatalog(logic: logic),
                  ),
          ),
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

void main() {
  test('章节解析保留真实更新时间，旧响应仍然兼容', () {
    expect(
      ComicChapter.from_json({
        'id': 2,
        'update_time': '2026-09-20',
      }).update_time,
      '2026-09-20',
    );
    expect(ComicChapter.from_json({'id': 2}).update_time, isEmpty);
  });

  testWidgets('目录不显示更新时间和裸编号，当前章节续读，其余章节从头开始', (tester) async {
    final logic = _Logic();
    addTearDown(logic.dispose);
    await _mount(tester, logic);
    expect(find.textContaining('2026-09-20'), findsNothing);
    expect(find.text('2'), findsNothing);
    expect(find.text('comics.image_count'), findsWidgets);
    final current_tile = find.byKey(const ValueKey(2));
    final arrow = find.descendant(
      of: current_tile,
      matching: find.byIcon(Icons.chevron_right_rounded),
    );
    expect(
      tester.getRect(arrow).right,
      closeTo(
        tester.getRect(current_tile).right -
            ComicChapterCatalogStyle.card_padding,
        0.1,
      ),
    );
    await tester.tap(find.byKey(const ValueKey(2)));
    expect(logic.opened, 2);
    expect(logic.resumed, isTrue);
    await tester.tap(find.byKey(const ValueKey(1)));
    expect(logic.opened, 1);
    expect(logic.resumed, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('目录横幅读取该章节的首张图片元数据', (tester) async {
    final logic = _Logic();
    addTearDown(logic.dispose);
    logic.chapters[0] = ComicChapter.from_json({
      'id': 1,
      'title': 'Chapter preview',
      'first_image': {'image_url': 'https://example.com/chapter-first.webp'},
    });
    await _mount(tester, logic, settle: false);
    final preview = tester.widget<ComicImage>(
      find.byKey(const ValueKey('comic_chapter_preview_1')),
    );
    expect(preview.url, 'https://example.com/chapter-first.webp');
    expect(preview.fit, BoxFit.cover);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('分段倒序保留原始编号', (tester) async {
    final logic = _Logic();
    addTearDown(logic.dispose);
    await _mount(tester, logic);
    await tester.tap(find.byTooltip('comics.sort_descending'));
    await tester.pumpAndSettle();
    final tiles = tester
        .widgetList<ComicDetailChapterTile>(find.byType(ComicDetailChapterTile))
        .toList();
    expect(tiles.first.chapter.id, 5);
    expect(tiles.first.number, 5);
    expect(tiles.last.chapter.id, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('千章目录首次定位且保持懒加载，离开后可动画定位返回', (tester) async {
    final logic = _Logic(count: 1000, current: 700);
    final scroll = ScrollController();
    addTearDown(logic.dispose);
    addTearDown(scroll.dispose);
    await _mount(tester, logic, scroll: scroll);
    expect(find.byType(ComicDetailChapterTile).evaluate().length, lessThan(40));
    expect(find.byKey(const ValueKey(700)).hitTestable(), findsOneWidget);
    final target_offset = scroll.offset;
    final toolbar_top = tester.getTopLeft(
      find.byKey(const ValueKey('comic_chapter_sheet_toolbar')),
    );
    final button = find.byType(PositioningButton);
    expect(tester.widget<PositioningButton>(button).show, isFalse);
    scroll.jumpTo(0);
    await tester.pump();
    expect(tester.widget<PositioningButton>(button).show, isTrue);
    final fade = find.descendant(
      of: button,
      matching: find.byType(FadeTransition),
    );
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.widget<FadeTransition>(fade).opacity.value, greaterThan(0));
    expect(tester.widget<FadeTransition>(fade).opacity.value, lessThan(1));
    await tester.pumpAndSettle();
    final region_rect = tester.getRect(
      find.byKey(const ValueKey('comic_chapter_sheet_list_region')),
    );
    final button_rect = tester.getRect(button);
    expect(
      button_rect.right,
      closeTo(region_rect.right - ComicChapterCatalogStyle.location_inset, 0.1),
    );
    expect(
      button_rect.bottom,
      closeTo(
        region_rect.bottom - ComicChapterCatalogStyle.location_inset,
        0.1,
      ),
    );
    expect(
      tester.getTopLeft(
        find.byKey(const ValueKey('comic_chapter_sheet_toolbar')),
      ),
      toolbar_top,
    );
    await tester.tap(
      find.byKey(const ValueKey('comic_chapter_sheet_location')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(scroll.offset, greaterThan(0));
    expect(scroll.offset, lessThan(target_offset));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey(700)).hitTestable(), findsOneWidget);
    expect(tester.widget<PositioningButton>(button).show, isFalse);
    await tester.tap(find.byTooltip('comics.sort_descending'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey(700)).hitTestable(), findsOneWidget);
    expect(tester.widget<PositioningButton>(button).show, isFalse);
    scroll.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('comic_chapter_sheet_location')),
    );
    await tester.pump(const Duration(milliseconds: 75));
    await tester.tap(find.byTooltip('comics.sort_ascending'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey(700)).hitTestable(), findsOneWidget);
    expect(tester.widget<PositioningButton>(button).show, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('大字号章节卡片无溢出', (tester) async {
    final logic = _Logic();
    addTearDown(logic.dispose);
    await _mount(tester, logic, scale: 2.5);
    expect(tester.takeException(), isNull);
  });

  testWidgets('目录章节卡片之间保留16像素独立留白', (tester) async {
    final logic = _Logic();
    addTearDown(logic.dispose);
    await _mount(tester, logic);
    final first = tester.getRect(find.byKey(const ValueKey(1)));
    final next = tester.getRect(find.byKey(const ValueKey(2)));
    expect(next.top - first.bottom, ComicChapterCatalogStyle.card_gap);
    expect(ComicChapterCatalogStyle.card_gap, greaterThanOrEqualTo(14));
    expect(tester.takeException(), isNull);
  });

  testWidgets('窄屏大字号定位千章保留内部序号且不展示裸编号', (tester) async {
    final logic = _Logic(count: 1000, current: 1000);
    final scroll = ScrollController();
    addTearDown(logic.dispose);
    addTearDown(scroll.dispose);
    await _mount(tester, logic, scale: 2.5, width: 320, scroll: scroll);
    expect(find.byKey(const ValueKey(1000)).hitTestable(), findsOneWidget);
    scroll.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('comic_chapter_sheet_location')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey(1000)).hitTestable(), findsOneWidget);
    expect(
      tester
          .widget<ComicDetailChapterTile>(find.byKey(const ValueKey(1000)))
          .number,
      1000,
    );
    expect(find.text('1000'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  for (final size in const [Size(466, 678), Size(951, 669), Size(669, 951)]) {
    testWidgets('Duo 目录折叠展开与横屏 $size 安全区不溢出', (tester) async {
      final logic = _Logic();
      addTearDown(logic.dispose);
      await _mount(
        tester,
        logic,
        window_media: MediaQueryData(
          size: size,
          padding: const EdgeInsets.only(right: 84, bottom: 34),
          viewPadding: const EdgeInsets.only(right: 84, bottom: 34),
          textScaler: const TextScaler.linear(1.5),
          displayFeatures: [
            DisplayFeature(
              bounds: Rect.fromLTWH(size.width - 84, 0, 84, size.height),
              type: DisplayFeatureType.cutout,
              state: DisplayFeatureState.unknown,
            ),
          ],
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('comics.sort_descending'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey(2)));
      expect(logic.opened, 2);
      expect(logic.resumed, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
}
