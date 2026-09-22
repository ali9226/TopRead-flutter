// ignore_for_file: non_constant_identifier_names

import 'package:app/models/paragraph_text_selection.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const content = '首段😀\r\n\r\n末段文字';
  const paragraph_start = 8;
  const paragraph_end = 12;

  bool matches(ParagraphTextSelection selection) => selection.matches_paragraph(
    content: content,
    paragraph_start: paragraph_start,
    paragraph_end: paragraph_end,
  );

  test('跨段引用保留 UTF-16 字符及原始空行，局部选区属于末段', () {
    const selection = ParagraphTextSelection(
      baseOffset: 0,
      extentOffset: 2,
      selected_text: '😀\r\n\r\n末段',
      content_start: 2,
      content_end: 10,
    );
    expect(matches(selection), isTrue);
    expect(selected_paragraph_text('末段文字', selection), selection.selected_text);
    expect(selection.textInside('末段文字'), '末段');
  });

  test('反向拖动仍按正文顺序引用并归属最后一段', () {
    const selection = ParagraphTextSelection(
      baseOffset: 2,
      extentOffset: 0,
      selected_text: '😀\r\n\r\n末段',
      content_start: 2,
      content_end: 10,
    );
    expect(matches(selection), isTrue);
  });

  test('跨段选区 content_end 超出 paragraph_end 时仍通过校验', () {
    // 用户从首段拖到末段，content_end 覆盖到末段之后的字符。
    const selection = ParagraphTextSelection(
      baseOffset: 0,
      extentOffset: 4,
      selected_text: '😀\r\n\r\n末段文字',
      content_start: 2,
      content_end: 12,
    );
    expect(matches(selection), isTrue);
  });

  test('普通 TextSelection 沿用段内引用', () {
    expect(
      selected_paragraph_text(
        '末段文字',
        const TextSelection(baseOffset: 3, extentOffset: 1),
      ),
      '段文',
    );
  });

  test('正文变化、末段错位、越界与局部偏移不一致均不可提交', () {
    for (final selection in [
      const ParagraphTextSelection(
        baseOffset: 0,
        extentOffset: 2,
        selected_text: '过期引用',
        content_start: 2,
        content_end: 10,
      ),
      const ParagraphTextSelection(
        baseOffset: 0,
        extentOffset: 2,
        selected_text: '',
        content_start: -1,
        content_end: 10,
      ),
      const ParagraphTextSelection(
        baseOffset: 0,
        extentOffset: 2,
        selected_text: '',
        content_start: 10,
        content_end: 10,
      ),
      const ParagraphTextSelection(
        baseOffset: 0,
        extentOffset: 2,
        selected_text: '',
        content_start: 2,
        content_end: 8,
      ),
      const ParagraphTextSelection(
        baseOffset: 0,
        extentOffset: 5,
        selected_text: '',
        content_start: 2,
        content_end: 13,
      ),
      const ParagraphTextSelection(
        baseOffset: 1,
        extentOffset: 2,
        selected_text: '😀\r\n\r\n末段',
        content_start: 2,
        content_end: 10,
      ),
    ]) {
      expect(matches(selection), isFalse);
    }
  });
}
