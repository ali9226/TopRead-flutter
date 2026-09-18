import 'dart:convert';

import 'package:app/models/paragraph_anchor.dart';
import 'package:app/pages/short_story_read/utils/split_story_paragraphs.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

ParagraphAnchor anchor(String id, String text, int start, {int count = 0}) =>
    ParagraphAnchor(
      id: id,
      paragraph_no: 1,
      start_offset: start,
      end_offset: start + text.length,
      content_hash: sha256.convert(utf8.encode(text)).toString(),
      comment_count: count,
    );

void main() {
  test('空行、CRLF、缩进和代理对保留正文 UTF-16 偏移', () {
    const content = '\r\n  第一段😀\r\n\n \n第二段\r末段';
    final paragraphs = split_story_paragraphs(content);
    expect(paragraphs.map((item) => item.text), ['  第一段😀', '第二段', '末段']);
    for (final paragraph in paragraphs) {
      expect(
        content.substring(paragraph.start_offset, paragraph.end_offset),
        paragraph.text,
      );
    }
    expect(paragraphs.first.start_offset, 2);
    expect(paragraphs.first.end_offset, 9);
    expect(paragraphs[1].start_offset, 14);
  });

  test('相同文字的不同段落分别绑定自己的评论计数', () {
    final paragraphs = split_story_paragraphs(
      '重复\n重复',
      anchors: [
        anchor('11', '重复', 0, count: 3),
        anchor('12', '重复', 3, count: 7),
      ],
    );
    expect(paragraphs.map((item) => item.anchor?.id), ['11', '12']);
    expect(paragraphs.map((item) => item.anchor?.comment_count), [3, 7]);
  });

  test('偏移相同但文字已更新时不绑定旧段评', () {
    final paragraphs = split_story_paragraphs(
      '新版',
      anchors: [anchor('11', '旧版', 0, count: 3)],
    );
    expect(paragraphs.single.anchor, isNull);
  });

  test('预览恢复前置空白偏移，截断段落不冒充完整段落', () {
    final paragraphs = split_story_paragraphs(
      '开头\n结',
      content_offset: 3,
      anchors: [anchor('11', '开头', 3), anchor('12', '结尾', 6)],
    );
    expect(paragraphs.first.anchor?.id, '11');
    expect(paragraphs.last.start_offset, 6);
    expect(paragraphs.last.anchor, isNull);
  });

  test('无段落元数据时仍保留正文，空白正文不生成段落', () {
    expect(split_story_paragraphs('正文').single.text, '正文');
    expect(split_story_paragraphs(' \r\n\t\n'), isEmpty);
  });
}
