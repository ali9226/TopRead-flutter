// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';

import 'package:app/models/paragraph_anchor.dart';
import 'package:app/models/paragraph_text_selection.dart';
import 'package:app/pages/short_story_read/logic.dart';
import 'package:app/stores/short_story_catalog_store.dart';
import 'package:app/util/split_story_paragraphs.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// 原文包含缩进、代理对、CRLF、空行及重复段落，防止按可见字符猜测偏移。
const _content = '\r\n  第一段😀\r\n\n重复\n重复';
const _story_id = 42;
const _selection_start = 4;

String _hash(String text) => sha256.convert(utf8.encode(text)).toString();

/// 每个重复段落保留独立的数据库 ID 及初始计数。
List<ParagraphAnchor> _anchors() => split_story_paragraphs(_content)
    .asMap()
    .entries
    .map(
      (entry) => ParagraphAnchor(
        id: '${101 + entry.key}',
        paragraph_no: entry.key + 1,
        start_offset: entry.value.start_offset,
        end_offset: entry.value.end_offset,
        content_hash: _hash(entry.value.text),
        comment_count: entry.key + 2,
      ),
    )
    .toList();

/// 完整引用结束于第三段首字；局部偏移始终属于第三段，包括反向拖选。
ParagraphTextSelection _selection(
  ParagraphAnchor anchor, {
  bool reversed = false,
}) {
  final end = anchor.start_offset + 1;
  return ParagraphTextSelection(
    baseOffset: reversed ? 1 : 0,
    extentOffset: reversed ? 0 : 1,
    selected_text: _content.substring(_selection_start, end),
    content_start: _selection_start,
    content_end: end,
  );
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storage_directory;

  setUpAll(() async {
    storage_directory = Directory.systemTemp.createTempSync(
      'short_story_paragraph_comment_test_',
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => storage_directory.path,
    );
    await GetStorage('GetStorage', storage_directory.path).initStorage;
  });

  setUp(() {
    Get.testMode = true;
    Get.put(ShortStoryCatalogStore());
  });

  tearDown(() => Get.reset());
  tearDownAll(() async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    await storage_directory.delete(recursive: true);
  });

  /// 构造实际短篇逻辑，仅替换网络发送器；正文、校验及计数更新均执行生产代码。
  Future<ShortStoryReadLogic> create_logic(
    WidgetTester tester,
    List<Map<String, Object>> requests,
  ) async {
    const context_key = ValueKey('short_story_comment_context');
    await tester.pumpWidget(const SizedBox(key: context_key));
    final logic = ShortStoryReadLogic(
      context: tester.element(find.byKey(context_key)),
      story_id: _story_id,
      paragraph_comment_sender:
          ({
            required novel_id,
            required comment_content,
            required paragraph_id,
            required selection_start,
            required selection_end,
          }) async {
            requests.add({
              'novel_id': novel_id,
              'comment_content': comment_content,
              'paragraph_id': paragraph_id,
              'selection_start': selection_start,
              'selection_end': selection_end,
            });
            return {'id': 99, 'comment_count': 19};
          },
    );
    logic.content.value = _content;
    logic.paragraph_anchors.assignAll(_anchors());
    addTearDown(logic.dispose);
    return logic;
  }

  for (final reversed in [false, true]) {
    testWidgets('短篇${reversed ? '反向' : '正向'}跨段选区提交全局 UTF-16 偏移并只更新末段', (
      tester,
    ) async {
      final requests = <Map<String, Object>>[];
      final logic = await create_logic(tester, requests);
      final anchor = logic.paragraph_anchors.last;
      final selection = _selection(anchor, reversed: reversed);

      expect(
        await logic.send_paragraph_comment(
          anchor: anchor,
          selection: selection,
          comment_content: '跨段评论',
          images: [],
        ),
        isTrue,
      );

      expect(requests, [
        {
          'novel_id': _story_id,
          'comment_content': '跨段评论',
          'paragraph_id': 103,
          'selection_start': _selection_start,
          'selection_end': anchor.start_offset + 1,
        },
      ]);
      expect(selection.selected_text, '第一段😀\r\n\n重复\n重');
      expect(logic.paragraph_anchors.map((item) => item.comment_count), [
        2,
        3,
        19,
      ]);
    });
  }

  testWidgets('正文变化使跨段引用或末段摘要过期时拒绝发送', (tester) async {
    final requests = <Map<String, Object>>[];
    final logic = await create_logic(tester, requests);
    final anchor = logic.paragraph_anchors.last;
    final selection = _selection(anchor);

    for (final changed_content in [
      // 末段仍相同，但之前选中的第一段已经变化。
      _content.replaceFirst('第一段', '新一段'),
      // 完整引用仍相同，但末段未选中的尾字已经变化。
      '${_content.substring(0, _content.length - 1)}新',
      // 正文缩短后旧偏移越界，应返回失败而非抛出 substring 异常。
      '新正文',
    ]) {
      logic.content.value = changed_content;
      expect(
        await logic.send_paragraph_comment(
          anchor: anchor,
          selection: selection,
          comment_content: '过期引用',
          images: [],
        ),
        isFalse,
      );
    }

    expect(requests, isEmpty);
    expect(logic.paragraph_anchors.map((item) => item.comment_count), [
      2,
      3,
      4,
    ]);
  });

  testWidgets('末段锚点 ID、偏移或摘要变化后拒绝使用旧锚点提交', (tester) async {
    final requests = <Map<String, Object>>[];
    final logic = await create_logic(tester, requests);
    final original_anchors = logic.paragraph_anchors.toList();
    final anchor = original_anchors.last;
    final selection = _selection(anchor);

    for (final changed_anchor in [
      ParagraphAnchor(
        id: '203',
        paragraph_no: anchor.paragraph_no,
        start_offset: anchor.start_offset,
        end_offset: anchor.end_offset,
        content_hash: anchor.content_hash,
        comment_count: anchor.comment_count,
      ),
      ParagraphAnchor(
        id: anchor.id,
        paragraph_no: anchor.paragraph_no,
        start_offset: anchor.start_offset - 1,
        end_offset: anchor.end_offset,
        content_hash: anchor.content_hash,
        comment_count: anchor.comment_count,
      ),
      ParagraphAnchor(
        id: anchor.id,
        paragraph_no: anchor.paragraph_no,
        start_offset: anchor.start_offset,
        end_offset: anchor.end_offset,
        content_hash: _hash('新段落'),
        comment_count: anchor.comment_count,
      ),
    ]) {
      logic.paragraph_anchors.assignAll([
        ...original_anchors.take(original_anchors.length - 1),
        changed_anchor,
      ]);
      expect(
        await logic.send_paragraph_comment(
          anchor: anchor,
          selection: selection,
          comment_content: '过期锚点',
          images: [],
        ),
        isFalse,
      );
    }

    expect(requests, isEmpty);
    expect(logic.paragraph_anchors.map((item) => item.comment_count), [
      2,
      3,
      4,
    ]);
  });
}
