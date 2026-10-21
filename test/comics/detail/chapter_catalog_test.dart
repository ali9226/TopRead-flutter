// ignore_for_file: non_constant_identifier_names

import 'dart:ui' show DisplayFeature, DisplayFeatureType, DisplayFeatureState;
import 'package:app/components/window_content_layout/index.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/detail/logic.dart';
import 'package:app/pages/comics/detail/resume_record.dart';
import 'package:app/pages/comics/detail/widgets/chapter_catalog.dart';
import 'package:app/pages/comics/detail/widgets/chapter_list.dart';
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
  ScrollController? scroll,
  MediaQueryData? window_media,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = window_media?.size ?? const Size(390, 844);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data:
            window_media ??
            MediaQueryData(
              size: const Size(390, 844),
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
  await tester.pumpAndSettle();
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

  testWidgets('当前章节续读，其余章节从头开始', (tester) async {
    final logic = _Logic();
    addTearDown(logic.dispose);
    await _mount(tester, logic);
    expect(find.textContaining('2026-09-20'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey(2)));
    expect(logic.opened, 2);
    expect(logic.resumed, isTrue);
    await tester.tap(find.byKey(const ValueKey(1)));
    expect(logic.opened, 1);
    expect(logic.resumed, isFalse);
    expect(tester.takeException(), isNull);
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

  testWidgets('千章目录懒加载，定位当前章节无需构建全部章节', (tester) async {
    final logic = _Logic(count: 1000, current: 700);
    final scroll = ScrollController();
    addTearDown(logic.dispose);
    addTearDown(scroll.dispose);
    await _mount(tester, logic, scroll: scroll);
    expect(find.byType(ComicDetailChapterTile).evaluate().length, lessThan(40));
    await tester.tap(find.byTooltip('comics.jump_to_current'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey(700)).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('大字号章节卡片无溢出', (tester) async {
    final logic = _Logic();
    addTearDown(logic.dispose);
    await _mount(tester, logic, scale: 2.5);
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
