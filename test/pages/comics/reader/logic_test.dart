// ignore_for_file: non_constant_identifier_names
import 'dart:async';
import 'dart:convert';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/reader/logic.dart';
import 'package:app/services/comics_progress/service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

ComicReading reading(
  int id, {
  Map<String, dynamic> read_record = const <String, dynamic>{},
}) => ComicReading(
  comic: const ComicItem(
    id: 7,
    title: 'Comic',
    cover_url: '',
    author_id: 3,
    author_name: 'Author',
    categories: <Map<String, dynamic>>[],
    chapter_count: 2,
    language_count: 1,
    status: 'published',
  ),
  language: const ComicLanguage(
    id: 8,
    language: 'en',
    title: 'Comic',
    description: '',
    cover_url: '',
  ),
  chapter: ComicChapter(
    id: id,
    title: 'Chapter $id',
    page_count: 3,
    sort_order: 1,
    status: 'published',
    images: const <ComicImageData>[],
  ),
  images: const <ComicImageData>[
    ComicImageData(
      image_url: 'https://example.com/1.webp',
      width: 400,
      height: 1200,
    ),
    ComicImageData(image_url: 'https://example.com/2.webp'),
    ComicImageData(image_url: 'https://example.com/3.webp'),
  ],
  previous_chapter_id: id == 20 ? 10 : 0,
  next_chapter_id: id == 10 ? 20 : 0,
  read_record: read_record,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('进入章节就记第0页，切章保留旧章再将新章第0页作为最新记录', () async {
    final stored = <String, String>{};
    final progress = ComicsProgressService(
      account_id: () => 0,
      read_storage: (key) async => stored[key],
      write_storage: (key, value) async {
        stored[key] = value;
      },
    );
    final logic = ComicReaderLogic(
      progress: progress,
      read_chapter: (id) async => reading(id),
    );
    await logic.load(10);
    await progress.flush(comic_id: 7);
    expect((await progress.read_record(7))['chapter_id'], 10);
    expect((await progress.read_record(7))['page_index'], 0);
    logic.page_index = 2;
    await logic.load(20, initial_page: 0);
    await progress.flush(comic_id: 7);
    expect((await progress.read_record(7))['chapter_id'], 20);
    expect((await progress.read_record(7))['page_index'], 0);
    logic.dispose();
    await progress.flush(comic_id: 7);
    progress.dispose();
  });
  test('旧章节网络响应晚到不会覆盖新章', () async {
    final progress = ComicsProgressService(
      account_id: () => 0,
      read_storage: (_) async => null,
      write_storage: (_, _) async {},
    );
    final first = Completer<ComicReading>(), second = Completer<ComicReading>();
    final logic = ComicReaderLogic(
      progress: progress,
      read_chapter: (id) => id == 10 ? first.future : second.future,
    );
    final a = logic.load(10), b = logic.load(20);
    second.complete(reading(20));
    await b;
    first.complete(reading(10));
    await a;
    expect(logic.reading!.chapter.id, 20);
    expect((await progress.read_record(7))['chapter_id'], 20);
    logic.dispose();
    await progress.flush(comic_id: 7);
    progress.dispose();
  });
  test('关闭页面时仍落盘，无需滚动；旧章比例回调被丢弃', () async {
    final stored = <String, String>{};
    final progress = ComicsProgressService(
      account_id: () => 0,
      read_storage: (key) async => stored[key],
      write_storage: (key, value) async {
        stored[key] = value;
      },
    );
    final logic = ComicReaderLogic(
      progress: progress,
      read_chapter: (id) async => reading(id),
    );
    await logic.load(20);
    logic.report_ratio(0, .1, chapter_id: 10);
    expect(logic.measured_ratios, isEmpty);
    logic.dispose();
    await progress.flush(comic_id: 7);
    expect((await progress.read_record(7))['chapter_title'], 'Chapter 20');
    expect(stored.length, 1);
    progress.dispose();
  });
  for (final kind in <String>['confirmed', 'legacy', 'dirty', 'explicit']) {
    test('续读服务端与本地择新规则 $kind', () async {
      final cache = jsonEncode(<String, dynamic>{
        'comic_id': 7,
        'chapter_id': 10,
        'page_index': 2,
        'updated_at': kind == 'confirmed'
            ? '2026-10-15T01:00:00Z'
            : '2099-01-01T00:00:00Z',
        'server_confirmed': kind == 'confirmed',
        'pending_sync': kind == 'dirty',
      });
      final progress = ComicsProgressService(
        account_id: () => 1,
        read_storage: (_) async => cache,
        write_storage: (_, _) async {},
        send_remote: (_, _) async => <String, dynamic>{
          'update_time': '2026-10-15T02:00:00Z',
        },
      );
      final logic = ComicReaderLogic(
        progress: progress,
        read_chapter: (id) async => reading(
          id,
          read_record: <String, dynamic>{
            'comic_id': 7,
            'chapter_id': 10,
            'page_index': 1,
            'update_time': '2026-10-15T02:00:00Z',
          },
        ),
      );
      await logic.load(10, initial_page: kind == 'explicit' ? 0 : null);
      expect(
        logic.page_index,
        kind == 'dirty'
            ? 2
            : kind == 'explicit'
            ? 0
            : 1,
      );
      logic.dispose();
      await progress.flush(comic_id: 7);
      progress.dispose();
    });
  }
  test('加载期间账号变更拒绝旧身份响应', () async {
    var account = 1;
    final request = Completer<ComicReading>();
    final progress = ComicsProgressService(
      account_id: () => account,
      read_storage: (_) async => null,
      write_storage: (_, _) async {},
    );
    final logic = ComicReaderLogic(
      progress: progress,
      read_chapter: (_) => request.future,
    );
    final pending = logic.load(10);
    account = 2;
    request.complete(reading(10));
    await pending;
    expect(logic.reading, isNull);
    expect(logic.loading, false);
    expect(logic.error, isNotNull);
    logic.dispose();
    progress.dispose();
  });
  testWidgets('未知图片尺寸同帧更新维持页内锚点，滚动控件卸载后退出也保留比例', (tester) async {
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
    await logic.load(10, initial_page: 1);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedBuilder(
            animation: logic,
            builder: (context, _) => CustomScrollView(
              controller: logic.scroll,
              slivers: <Widget>[
                SliverVariedExtentList.builder(
                  itemCount: 3,
                  itemExtentBuilder: (index, _) => logic.image_height(index),
                  itemBuilder: (_, index) => ColoredBox(
                    color: index.isEven ? Colors.white : Colors.grey,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 400)),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    logic.scroll.jumpTo(logic.image_height(0) + logic.image_height(1) * .5);
    logic.report_ratio(0, .1);
    logic.report_ratio(1, .2);
    await tester.pump();
    expect(logic.page_index, 1);
    expect(logic.scroll.offset, closeTo(5000, .1));
    await logic.flush();
    expect((await progress.read_record(7))['page_fraction'], closeTo(.5, .001));
    await tester.pumpWidget(const SizedBox.shrink());
    logic.dispose();
    await progress.flush(comic_id: 7);
    expect((await progress.read_record(7))['page_fraction'], closeTo(.5, .001));
    progress.dispose();
  });
}
