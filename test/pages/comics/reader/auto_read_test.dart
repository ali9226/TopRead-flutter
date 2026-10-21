// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'package:app/pages/comics/reader/auto_read.dart';
import 'package:app/pages/comics/reader/logic.dart';
import 'package:app/services/comics_progress/service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'logic_test.dart' show reading;

/// TODO 固定图片视口与额外章末区，所有进度仅落内存，不访问服务器或设备存储。
Future<(ComicReaderLogic, ComicsProgressService)> _mount_reader(
  WidgetTester tester,
) async {
  final progress = ComicsProgressService(
    account_id: () => 0,
    read_storage: (_) async => null,
    write_storage: (_, _) async {},
  );
  final logic = ComicReaderLogic(
    progress: progress,
    read_chapter: (id) async => reading(id),
  );
  logic.set_width(400);
  await logic.load(10, initial_page: 0);
  final image_height = logic.page_heights.fold<double>(
    0,
    (sum, height) => sum + height,
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 400,
            height: 500,
            child: CustomScrollView(
              controller: logic.scroll,
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: image_height)),
                const SliverToBoxAdapter(child: SizedBox(height: 400)),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (logic, progress);
}

Future<void> _dispose_reader(
  WidgetTester tester,
  ComicReaderLogic logic,
  ComicsProgressService progress,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  logic.dispose();
  await progress.flush(comic_id: 7);
  progress.dispose();
}

void main() {
  testWidgets('逐帧阅读实时使用速度，暂停恢复不补算暂停时间，停止后不再移动', (tester) async {
    final (logic, progress) = await _mount_reader(tester);
    var speed = 0.0;
    final auto = ComicAutoRead(
      vsync: tester,
      logic: logic,
      speed: () => speed,
      on_next: () async => false,
    );
    auto.start();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(auto.running, isTrue);
    expect(logic.scroll.offset, closeTo(2, 0.01));
    speed = 1;
    await tester.pump(const Duration(milliseconds: 100));
    expect(logic.scroll.offset, closeTo(32, 0.01));
    auto.pause();
    await tester.pump(const Duration(seconds: 2));
    expect(auto.running, isTrue);
    expect(logic.scroll.offset, closeTo(32, 0.01));
    auto.resume();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(logic.scroll.offset, closeTo(62, 0.01));
    auto.stop();
    await tester.pump(const Duration(milliseconds: 100));
    expect(auto.running, isFalse);
    expect(logic.scroll.offset, closeTo(62, 0.01));
    auto.dispose();
    await _dispose_reader(tester, logic, progress);
  });

  testWidgets('跨章等待期间停止，迟到的成功响应不会重新开始自动阅读', (tester) async {
    final (logic, progress) = await _mount_reader(tester);
    final pending = Completer<bool>();
    var next_requests = 0;
    final auto = ComicAutoRead(
      vsync: tester,
      logic: logic,
      speed: () => 1,
      on_next: () {
        next_requests++;
        return pending.future;
      },
    );
    logic.scroll.jumpTo(logic.chapter_scroll_extent - 1);
    auto.start();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(next_requests, 1);
    expect(logic.scroll.offset, closeTo(logic.chapter_scroll_extent, 0.01));
    await tester.pump(const Duration(milliseconds: 100));
    expect(next_requests, 1, reason: '等待跨章期间不能重复请求下一章');
    auto.stop();
    pending.complete(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(auto.running, isFalse);
    expect(next_requests, 1);
    expect(logic.scroll.offset, closeTo(logic.chapter_scroll_extent, 0.01));
    auto.dispose();
    await _dispose_reader(tester, logic, progress);
  });

  testWidgets('连续进度跳转只覆盖漫画图片，章末操作区不计入百分比', (tester) async {
    final (logic, progress) = await _mount_reader(tester);
    final images_height = logic.page_heights.fold<double>(
      0,
      (sum, height) => sum + height,
    );
    expect(logic.chapter_scroll_extent, closeTo(images_height - 500, 0.01));
    expect(
      logic.scroll.position.maxScrollExtent - logic.chapter_scroll_extent,
      closeTo(400, 0.01),
    );
    logic.jump_to_progress(0.5);
    expect(logic.scroll.offset, closeTo((images_height - 500) / 2, 0.01));
    expect(logic.chapter_progress, closeTo(0.5, 0.0001));
    logic.jump_to_progress(1);
    expect(logic.scroll.offset, closeTo(logic.chapter_scroll_extent, 0.01));
    expect(
      logic.scroll.offset,
      lessThan(logic.scroll.position.maxScrollExtent),
    );
    expect(logic.chapter_progress, 1);
    logic.scroll.jumpTo(logic.scroll.position.maxScrollExtent);
    expect(logic.chapter_progress, 1, reason: '滚入章末区域后仍保持100%');
    logic.jump_to_progress(-1);
    expect(logic.scroll.offset, 0);
    logic.jump_to_progress(double.nan);
    expect(logic.scroll.offset, 0);
    await _dispose_reader(tester, logic, progress);
  });
}
