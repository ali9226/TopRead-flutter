// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:app/api/paragraph_comment.dart';
import 'package:app/models/novel_info.dart';
import 'package:app/models/paragraph_anchor.dart';
import 'package:app/stores/novel_reading_store.dart';
import 'package:app/util/split_story_paragraphs.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

NovelChapterInfo chapter(String id, int number, {String revision = '1'}) =>
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

void main() {
  test('初始、追加、前插、重建都保留原文 UTF-16 坐标和独立段落锚点', () {
    final store = NovelReadingStore();
    store.set_chapter_list([
      chapter('11', 1),
      chapter('12', 2),
      chapter('13', 3),
    ]);
    const content = '\r\n  重复😀\r\n\n \n重复😀\r末段';
    final paragraphs = split_story_paragraphs(content);
    for (int chapter_index = 0; chapter_index < 3; chapter_index++) {
      store.cache_chapter_content(chapter_index, content);
      expect(
        store.set_chapter_paragraph_metadata(
          chapter_index,
          ParagraphMetadata(
            body_id: 'body-$chapter_index',
            published_revision_id: '1',
            content_hash: sha256.convert(utf8.encode(content)).toString(),
            paragraphs: paragraphs
                .asMap()
                .entries
                .map(
                  (entry) => ParagraphAnchor(
                    id: '$chapter_index-${entry.key}',
                    paragraph_no: entry.key + 1,
                    start_offset: entry.value.start_offset,
                    end_offset: entry.value.end_offset,
                    content_hash: sha256
                        .convert(utf8.encode(entry.value.text))
                        .toString(),
                    comment_count: entry.key,
                  ),
                )
                .toList(),
          ),
        ),
        isTrue,
      );
    }
    store.set_initial_content('第二章', 2, 1, 100, 100, content);
    store.append_chapter_content('第三章', 3, 2, 200, 100, content);
    store.prepend_chapter_content('第一章', 1, 0, 0, 100, content);

    void verify() {
      expect(store.reading_items.length, 12);
      for (final item in store.reading_items) {
        if (item.is_title) {
          expect(item.start_offset, -1);
          expect(item.anchor, isNull);
          continue;
        }
        expect(
          content.substring(item.start_offset, item.end_offset),
          item.text,
        );
        expect(item.anchor?.start_offset, item.start_offset);
        expect(item.anchor?.id.startsWith('${item.chapter_index}-'), isTrue);
        expect(item.paragraph.anchor?.id, item.anchor?.id);
        expect(item.chapter_id, '${11 + item.chapter_index}');
      }
      expect(store.reading_items[1].text, '  重复😀');
      expect(store.reading_items[1].start_offset, 2);
    }

    verify();
    store.rebuild_reading_items_from_cache(0, 2, store.chapter_list);
    verify();
  });

  test('目录章节重排或公开修订更新时旧缓存与元数据一起失效', () {
    final store = NovelReadingStore();
    store.set_chapter_list([chapter('11', 1), chapter('12', 2)]);
    store.cache_chapter_content(0, '第一章');
    store.cache_chapter_content(1, '第二章');
    store.set_chapter_list([chapter('12', 1), chapter('11', 2)]);
    expect(store.is_chapter_cached(0), isFalse);
    expect(store.is_chapter_cached(1), isFalse);

    store.cache_chapter_content(0, '第一章');
    store.set_chapter_list([chapter('12', 1, revision: '2'), chapter('11', 2)]);
    expect(store.is_chapter_cached(0), isFalse);
  });
}
