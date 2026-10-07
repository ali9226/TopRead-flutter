// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/short_story_read/utils/calculate_current_story_scroll_extent.dart';
import 'package:app/pages/short_story_read/widgets/story_scroll_metrics_observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 使用真实滚动视口和篇末标记，下一篇预览始终位于标记之后。
class _ReaderLayout extends StatefulWidget {
  const _ReaderLayout({super.key});

  @override
  State<_ReaderLayout> createState() => _ReaderLayoutState();
}

class _ReaderLayoutState extends State<_ReaderLayout> {
  final scroll_controller = ScrollController();
  final story_end_key = GlobalKey();
  double viewport_height = 400;
  double story_height = 1200;
  double preview_height = 600;
  double? cached_extent;
  int scroll_events = 0;
  int extent_updates = 0;

  @override
  void initState() {
    super.initState();
    scroll_controller.addListener(() => scroll_events++);
  }

  @override
  void dispose() {
    scroll_controller.dispose();
    super.dispose();
  }

  void resize({double? viewport, double? story, double? preview}) {
    setState(() {
      viewport_height = viewport ?? viewport_height;
      story_height = story ?? story_height;
      preview_height = preview ?? preview_height;
    });
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 400,
          height: viewport_height,
          child: StoryScrollMetricsObserver(
            scroll_controller: scroll_controller,
            story_end_key: story_end_key,
            on_layout_pending: () => cached_extent = null,
            on_extent_changed: (extent) {
              cached_extent = extent;
              extent_updates++;
            },
            child: SingleChildScrollView(
              controller: scroll_controller,
              child: Column(
                children: [
                  SizedBox(height: story_height),
                  SizedBox(key: story_end_key, height: 0),
                  SizedBox(height: preview_height),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('旋转或分屏改变视口后刷新正文范围，尺寸通知不产生用户滚动', (tester) async {
    final reader_key = GlobalKey<_ReaderLayoutState>();
    await tester.pumpWidget(_ReaderLayout(key: reader_key));
    await tester.pumpAndSettle();
    final reader = reader_key.currentState!;
    expect(reader.cached_extent, 800);

    reader.scroll_controller.jumpTo(400);
    await tester.pumpAndSettle();
    final scroll_events_before_resize = reader.scroll_events;
    reader.resize(viewport: 550);
    await tester.pumpAndSettle();

    expect(reader.cached_extent, 650);
    expect(reader.scroll_controller.offset, 400);
    expect(reader.scroll_events, scroll_events_before_resize);
    expect(tester.takeException(), isNull);
  });

  testWidgets('解锁或广告改变正文高度后无需继续滑动也能刷新范围', (tester) async {
    final reader_key = GlobalKey<_ReaderLayoutState>();
    await tester.pumpWidget(_ReaderLayout(key: reader_key));
    await tester.pumpAndSettle();
    final reader = reader_key.currentState!;
    expect(reader.cached_extent, 800);

    reader.resize(story: 1500);
    await tester.pumpAndSettle();

    expect(reader.cached_extent, 1100);
    expect(reader.scroll_controller.offset, 0);
    expect(reader.scroll_events, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('下一篇预览变化不计入进度，缓存失效时仍以本篇末尾为准', (tester) async {
    final reader_key = GlobalKey<_ReaderLayoutState>();
    await tester.pumpWidget(_ReaderLayout(key: reader_key));
    await tester.pumpAndSettle();
    final reader = reader_key.currentState!;
    expect(reader.cached_extent, 800);
    expect(reader.scroll_controller.position.maxScrollExtent, 1424);

    reader.resize(preview: 1600);
    await tester.pumpAndSettle();
    expect(reader.cached_extent, 800);
    expect(reader.scroll_controller.position.maxScrollExtent, 2424);

    reader.cached_extent = null;
    final progress_target =
        reader.cached_extent ??
        calculate_current_story_scroll_extent(
          scroll_controller: reader.scroll_controller,
          story_end_key: reader.story_end_key,
        );
    reader.scroll_controller.jumpTo(progress_target);
    await tester.pumpAndSettle();
    expect(reader.scroll_controller.offset, 800);
    expect(
      tester.getTopLeft(find.byKey(reader.story_end_key)).dy,
      closeTo(reader.viewport_height, 0.01),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('嵌套滚动控件的尺寸变化不会失效正文范围', (tester) async {
    final controller = ScrollController();
    final nested_controller = ScrollController();
    addTearDown(controller.dispose);
    addTearDown(nested_controller.dispose);
    final marker_key = GlobalKey();
    late StateSetter set_nested_state;
    int nested_item_count = 10;
    int extent_updates = 0;
    int invalidations = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StoryScrollMetricsObserver(
            scroll_controller: controller,
            story_end_key: marker_key,
            on_layout_pending: () => invalidations++,
            on_extent_changed: (_) => extent_updates++,
            child: SingleChildScrollView(
              controller: controller,
              child: Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: StatefulBuilder(
                      builder: (context, set_state) {
                        set_nested_state = set_state;
                        return ListView.builder(
                          controller: nested_controller,
                          itemCount: nested_item_count,
                          itemExtent: 80,
                          itemBuilder: (_, index) => Text('Nested $index'),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 1200),
                  SizedBox(key: marker_key, height: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final updates_before = extent_updates;
    final invalidations_before = invalidations;

    set_nested_state(() => nested_item_count = 20);
    await tester.pumpAndSettle();
    expect(extent_updates, updates_before);
    expect(invalidations, invalidations_before);
    expect(tester.takeException(), isNull);
  });
}
