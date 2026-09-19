// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:convert';

import 'package:app/api/get_novel_content.dart';
import 'package:app/api/paragraph_comment.dart';
import 'package:app/models/novel_info.dart';
import 'package:app/models/paragraph_anchor.dart';
import 'package:app/pages/read/logic.dart';
import 'package:app/pages/read/utils/chapter_cache.dart';
import 'package:app/stores/novel_reading_store.dart';
import 'package:app/util/split_story_paragraphs.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

String _hash(String content) => sha256.convert(utf8.encode(content)).toString();

NovelChapterInfo _chapter(String id, {String? revision, int number = 1}) =>
    NovelChapterInfo(
      id: id,
      novel_language_id: '1',
      chapter_no: number,
      title: '第 $number 章',
      sorting: number,
      word_count: 100,
      is_vip: 0,
      create_time: '',
      update_time: '',
      remove_status: 0,
      published_revision_id: revision,
    );

ParagraphMetadata _metadata(
  String content, {
  String revision = 'rev-1',
  String prefix = 'paragraph',
}) => ParagraphMetadata(
  body_id: 'body-$revision',
  published_revision_id: revision,
  content_hash: _hash(content),
  paragraphs: split_story_paragraphs(content).asMap().entries.map((entry) {
    final paragraph = entry.value;
    return ParagraphAnchor(
      id: '$prefix-${entry.key}',
      paragraph_no: entry.key + 1,
      start_offset: paragraph.start_offset,
      end_offset: paragraph.end_offset,
      content_hash: _hash(paragraph.text),
      comment_count: entry.key + 2,
    );
  }).toList(),
);

Future<int?> _unused_sender({
  required String paragraph_id,
  required String content,
  required List<String> images,
  required int selection_start,
  required int selection_end,
}) async => null;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NovelReadingStore store;
  late String chapter_id;
  late Logic logic;

  void initialize({
    required ChapterParagraphMetadataLoader metadata_loader,
    ChapterVersionedContentLoader? content_loader,
    ParagraphCommentSender sender = _unused_sender,
    String? directory_revision,
  }) {
    store = NovelReadingStore();
    chapter_id = 'paragraph-test-${DateTime.now().microsecondsSinceEpoch}';
    logic = Logic(
      story_id: 1,
      story_title: '测试长篇',
      reading_store: store,
      initial_body_font_size: 18,
      initial_auto_read_speed: 0.2,
      chapter_paragraph_metadata_loader: metadata_loader,
      chapter_content_with_version_loader:
          content_loader ?? (_) async => const NovelContentResult(content: ''),
      paragraph_comment_sender: sender,
    );
    store.set_chapter_list([
      _chapter(chapter_id, revision: directory_revision),
    ]);
    addTearDown(() async {
      logic.onClose();
      await ChapterCache.clear(chapter_id);
    });
  }

  ReadingContentItem body_item([int index = 0]) =>
      store.reading_items.where((item) => !item.is_title).elementAt(index);

  Future<void> show_chapter() async {
    final generation = await logic.jump_to_chapter(0);
    expect(generation, isNotNull);
    logic.complete_chapter_jump(generation!);
  }

  test('旧内存正文与新段落摘要不符时重新读取实际公开版本', () async {
    const fresh_content = '\r\n  新正文😀\r\n\n第二段';
    final metadata = _metadata(fresh_content, revision: 'rev-new');
    int content_requests = 0;
    initialize(
      directory_revision: 'rev-old',
      metadata_loader: (id) async {
        expect(id, chapter_id);
        return metadata;
      },
      content_loader: (_) async {
        content_requests++;
        return NovelContentResult(
          content: fresh_content,
          published_revision_id: 'rev-new',
          body_id: metadata.body_id,
        );
      },
    );
    store.cache_chapter_content(0, '旧正文', published_revision_id: 'rev-old');

    await show_chapter();

    expect(content_requests, 1);
    expect(store.get_cached_chapter_revision(0), 'rev-new');
    expect(body_item().text, '  新正文😀');
    expect(body_item().start_offset, 2);
    expect(body_item().anchor?.id, 'paragraph-0');
    expect(await logic.resolve_paragraph_anchor(body_item()), isNotNull);
  });

  test('旧磁盘缓存无版本字段时仍按完整正文摘要重新获取内容', () async {
    const fresh_content = '新磁盘正文';
    final metadata = _metadata(fresh_content);
    int content_requests = 0;
    initialize(
      metadata_loader: (_) async => metadata,
      content_loader: (_) async {
        content_requests++;
        return NovelContentResult(
          content: fresh_content,
          published_revision_id: metadata.published_revision_id,
          body_id: metadata.body_id,
        );
      },
    );
    await ChapterCache.write(chapter_id, '旧磁盘正文');

    await show_chapter();

    expect(content_requests, 1);
    expect(body_item().text, fresh_content);
    expect(body_item().anchor?.id, 'paragraph-0');
  });

  test('公开版本不同但文本相同时也不能误挂新版本的锚点', () async {
    const content = '相同正文';
    final old_metadata = _metadata(content, revision: 'rev-old');
    final new_metadata = _metadata(content, revision: 'rev-new');
    initialize(
      metadata_loader: (_) async => new_metadata,
      content_loader: (_) async => NovelContentResult(
        content: content,
        published_revision_id: old_metadata.published_revision_id,
        body_id: old_metadata.body_id,
      ),
    );

    await show_chapter();

    expect(body_item().text, content);
    expect(body_item().anchor, isNull);
    expect(await logic.resolve_paragraph_anchor(body_item()), isNull);
  });

  test('元数据与正文查询之间发生发布时重取元数据完成同版绑定', () async {
    const content = '发布后的正文';
    final metadata = _metadata(content, revision: 'rev-new');
    int metadata_requests = 0;
    initialize(
      metadata_loader: (_) async {
        metadata_requests++;
        return metadata_requests == 1 ? _metadata('发布前的正文') : metadata;
      },
      content_loader: (_) async => NovelContentResult(
        content: content,
        published_revision_id: metadata.published_revision_id,
        body_id: metadata.body_id,
      ),
    );

    await show_chapter();

    expect(metadata_requests, 2);
    expect(body_item().anchor?.id, 'paragraph-0');
  });

  test('临时元数据失败可阅读，交互重试后提交真实 UTF-16 偏移和服务端计数', () async {
    const content = '\r\n  第一段😀\r\n\n重复\n重复';
    final metadata = _metadata(content);
    int metadata_requests = 0;
    Map<String, Object>? submitted;
    initialize(
      metadata_loader: (_) async {
        metadata_requests++;
        if (metadata_requests == 1) throw StateError('暂时离线');
        return metadata;
      },
      content_loader: (_) async => NovelContentResult(
        content: content,
        published_revision_id: metadata.published_revision_id,
        body_id: metadata.body_id,
      ),
      sender:
          ({
            required paragraph_id,
            required content,
            required images,
            required selection_start,
            required selection_end,
          }) async {
            submitted = {
              'paragraph_id': paragraph_id,
              'content': content,
              'images': images,
              'start': selection_start,
              'end': selection_end,
            };
            return 17;
          },
    );

    await show_chapter();
    final item = body_item();
    expect(item.anchor, isNull);
    final anchor = await logic.resolve_paragraph_anchor(item);
    expect(anchor?.id, 'paragraph-0');
    expect(body_item().anchor?.comment_count, 2);
    final sent = await logic.send_paragraph_comment(
      item: item,
      anchor: anchor!,
      selection: const TextSelection(baseOffset: 2, extentOffset: 7),
      text: '测试段评',
      images: const ['image-key'],
    );

    expect(sent, isTrue);
    expect(submitted, {
      'paragraph_id': 'paragraph-0',
      'content': '测试段评',
      'images': ['image-key'],
      'start': 4,
      'end': 9,
    });
    expect(body_item().anchor?.comment_count, 17);
    expect(body_item(1).anchor?.comment_count, 3);
    expect(body_item(2).anchor?.comment_count, 4);

    final repeated_item = body_item(2);
    logic.update_paragraph_comment_count(
      item: repeated_item,
      paragraph_id: repeated_item.anchor!.id,
      count: 25,
    );
    expect(body_item(1).anchor?.comment_count, 3);
    expect(body_item(2).anchor?.comment_count, 25);
  });

  test('无效选区、其他段落锚点和正文刷新后的旧回调不会发请求', () async {
    const content = '第一段\n第二段';
    final metadata = _metadata(content);
    int submissions = 0;
    initialize(
      metadata_loader: (_) async => metadata,
      content_loader: (_) async => NovelContentResult(
        content: content,
        published_revision_id: metadata.published_revision_id,
        body_id: metadata.body_id,
      ),
      sender:
          ({
            required paragraph_id,
            required content,
            required images,
            required selection_start,
            required selection_end,
          }) async {
            submissions++;
            return 50;
          },
    );
    await show_chapter();
    final item = body_item();
    for (final selection in [
      const TextSelection.collapsed(offset: 0),
      const TextSelection(baseOffset: -1, extentOffset: 1),
      const TextSelection(baseOffset: 0, extentOffset: 99),
    ]) {
      expect(
        await logic.send_paragraph_comment(
          item: item,
          anchor: item.anchor!,
          selection: selection,
          text: '评论',
          images: [],
        ),
        isFalse,
      );
    }
    expect(
      await logic.send_paragraph_comment(
        item: item,
        anchor: body_item(1).anchor!,
        selection: const TextSelection(baseOffset: 0, extentOffset: 2),
        text: '评论',
        images: [],
      ),
      isFalse,
    );

    store.cache_chapter_content(0, '更新后的正文', published_revision_id: 'rev-2');
    store.rebuild_reading_items_from_cache(0, 0, store.chapter_list);
    expect(await logic.resolve_paragraph_anchor(item), isNull);
    expect(
      await logic.send_paragraph_comment(
        item: item,
        anchor: item.anchor!,
        selection: const TextSelection(baseOffset: 0, extentOffset: 2),
        text: '评论',
        images: [],
      ),
      isFalse,
    );
    logic.update_paragraph_comment_count(
      item: item,
      paragraph_id: item.anchor!.id,
      count: 100,
    );
    expect(body_item().anchor, isNull);
    expect(submissions, 0);
  });

  test('失败提交不增加段评数，移出窗口的段落不能提交或更新气泡', () async {
    const content = '测试正文';
    final metadata = _metadata(content);
    initialize(
      metadata_loader: (_) async => metadata,
      content_loader: (_) async => NovelContentResult(
        content: content,
        published_revision_id: metadata.published_revision_id,
        body_id: metadata.body_id,
      ),
    );
    await show_chapter();
    final item = body_item();
    expect(
      await logic.send_paragraph_comment(
        item: item,
        anchor: item.anchor!,
        selection: const TextSelection(baseOffset: 0, extentOffset: 2),
        text: '评论',
        images: [],
      ),
      isFalse,
    );
    expect(body_item().anchor?.comment_count, 2);
    store.reading_items.clear();
    expect(await logic.resolve_paragraph_anchor(item), isNull);
  });

  test('关闭阅读页后迟到的元数据不会写回已销毁页面', () async {
    const content = '测试正文';
    final pending = Completer<ParagraphMetadata?>();
    initialize(metadata_loader: (_) => pending.future);
    store.cache_chapter_content(0, content);
    store.set_initial_content('第一章', 1, 0, 0, 100, content);
    final resolving = logic.resolve_paragraph_anchor(body_item());
    logic.close_paragraph_state();
    pending.complete(_metadata(content));

    expect(await resolving, isNull);
    expect(store.get_chapter_paragraph_metadata(0), isNull);
  });
}
