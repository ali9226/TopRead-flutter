// ignore_for_file: non_constant_identifier_names

import 'package:app/components/paragraph_selection/comment_badge.dart';
import 'package:app/components/paragraph_selection/index.dart';
import 'package:app/models/paragraph_anchor.dart';
import 'package:app/pages/read/widgets/content/paragraph.dart';
import 'package:app/stores/novel_reading_store.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:app/models/paragraph_text_selection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (call) async => call.method == 'getAll' ? <String, Object>{} : true,
        );
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('长篇正文长按使用共用选区，等待单击完成才触发翻页', (tester) async {
    int turns = 0;
    TextSelection? submitted;
    final states = <bool>[];
    const text = '  A moon 🌙 above the forest.';
    await pump_paragraph(
      tester,
      ReaderParagraphItem(
        item: make_item(text),
        is_dark: false,
        body_font_size: 18,
        text_color: Colors.black,
        on_comment: (selection) => submitted = selection,
        on_selection_changed: states.add,
        on_tap_position: (_) => turns++,
      ),
    );
    await tester.longPressAt(paragraph_position(tester, 5));
    await tester.pumpAndSettle();
    expect(turns, 0);
    final render = paragraph_render(tester);
    final selected = render.selections.single.textInside(text);
    // 长按默认选中整个段落。
    expect(selected, text);
    expect(find.byType(EditableText), findsNothing);
    expect(tester.testTextInput.isVisible, isFalse);
    await tester.tap(find.text('Comment'));
    await tester.pumpAndSettle();
    expect(selected_paragraph_text(text, submitted!), selected);
    // 长按选词后扩展为整段，产生额外的选区变化通知。
    expect(states.first, isTrue);
    expect(states.last, isFalse);
    expect(turns, 0);
    await tester.tapAt(paragraph_position(tester, 5));
    await tester.pumpAndSettle();
    expect(turns, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('长篇气泡保持段落身份，更新数量且点击不翻页', (tester) async {
    int turns = 0;
    int opened = 0;
    Widget paragraph(int count) => ReaderParagraphItem(
      item: make_item('Same paragraph', count: count),
      is_dark: true,
      body_font_size: 18,
      text_color: Colors.white,
      on_comment: (_) {},
      on_comments: () => opened++,
      on_tap_position: (_) => turns++,
    );
    await pump_paragraph(tester, paragraph(3));
    await tester.tap(find.byType(ParagraphCommentBadge));
    await tester.pumpAndSettle();
    expect(opened, 1);
    expect(turns, 0);
    await pump_paragraph(tester, paragraph(4));
    final selection = tester.widget<ParagraphSelection>(
      find.byType(ParagraphSelection),
    );
    expect(selection.paragraph_id, '101');
    expect(selection.comment_count, 4);
    expect(tester.takeException(), isNull);
  });

  testWidgets('章节标题没有段评选区，移除选中正文时释放选择状态', (tester) async {
    final states = <bool>[];
    await pump_paragraph(
      tester,
      ReaderParagraphItem(
        item: make_item('Body paragraph'),
        is_dark: false,
        body_font_size: 18,
        text_color: Colors.black,
        on_comment: (_) {},
        on_selection_changed: states.add,
      ),
    );
    await tester.longPressAt(paragraph_position(tester, 5));
    await tester.pumpAndSettle();
    expect(states.last, isTrue);
    await pump_paragraph(
      tester,
      ReaderParagraphItem(
        item: make_item('Chapter title', is_title: true),
        is_dark: false,
        body_font_size: 18,
        text_color: Colors.black,
        on_comment: (_) {},
      ),
    );
    expect(find.byType(ParagraphSelection), findsNothing);
    expect(states.last, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('长篇共享选区排除章节标题，跨段评论保留正文偏移并归属末段', (tester) async {
    const first = 'First moon 🌙 rises.';
    const last = '  Second dawn arrives.';
    const content = '\r\n\r\n$first\r\n\r\n$last';
    final submitted = <(String, TextSelection)>[];
    await pump_paragraph(
      tester,
      ParagraphSelectionScope(
        content: content,
        is_dark: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReaderParagraphItem(
              item: make_item('Chapter title', is_title: true),
              is_dark: true,
              body_font_size: 18,
              text_color: Colors.white,
              on_comment: (selection) => submitted.add(('title', selection)),
            ),
            ReaderParagraphItem(
              item: make_item(first, count: 3),
              is_dark: true,
              body_font_size: 18,
              text_color: Colors.white,
              on_comment: (selection) => submitted.add(('101', selection)),
            ),
            ReaderParagraphItem(
              item: make_item(
                last,
                count: 7,
                id: '102',
                start_offset: content.indexOf(last),
              ),
              is_dark: true,
              body_font_size: 18,
              text_color: Colors.white,
              on_comment: (selection) => submitted.add(('102', selection)),
            ),
          ],
        ),
      ),
    );

    expect(find.byType(SelectionArea), findsOneWidget);
    await tester.longPressAt(paragraph_position(tester, 7));
    await tester.pumpAndSettle();
    final area = tester.state<SelectionAreaState>(find.byType(SelectionArea));
    area.selectableRegion.selectAll(SelectionChangedCause.toolbar);
    await tester.pumpAndSettle();

    final title_render = tester.renderObject<RenderParagraph>(
      find.descendant(
        of: find.text('Chapter title'),
        matching: find.byType(RichText),
      ),
    );
    expect(title_render.selections, isEmpty);
    await tester.tap(find.text('Comment'));
    await tester.pumpAndSettle();

    expect(submitted, hasLength(1));
    final (paragraph_id, range) = submitted.single;
    expect(paragraph_id, '102');
    expect(range, isA<ParagraphTextSelection>());
    final selection = range as ParagraphTextSelection;
    expect(selection.selected_text, content.substring(4));
    expect(selection.content_start, 4);
    expect(selection.content_end, content.length);
    expect(selection.start, 0);
    expect(selection.end, last.length);
    expect(
      selection.matches_paragraph(
        content: content,
        paragraph_start: content.indexOf(last),
        paragraph_end: content.length,
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}

ReadingContentItem make_item(
  String text, {
  int count = 0,
  bool is_title = false,
  String id = '101',
  int start_offset = 4,
}) => ReadingContentItem(
  text: text,
  is_title: is_title,
  chapter_no: 2,
  chapter_index: 1,
  chapter_id: '22',
  words_before_this_chapter: 100,
  chapter_total_words: 100,
  start_offset: start_offset,
  end_offset: start_offset + text.length,
  anchor: ParagraphAnchor(
    id: id,
    paragraph_no: 1,
    start_offset: start_offset,
    end_offset: start_offset + text.length,
    content_hash: '',
    comment_count: count,
  ),
);

Future<void> pump_paragraph(WidgetTester tester, Widget paragraph) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/i18n',
      assetLoader: const _Translations(),
      startLocale: const Locale('en'),
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          home: Scaffold(
            body: Padding(padding: const EdgeInsets.all(80), child: paragraph),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _Translations extends AssetLoader {
  const _Translations();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {
    'paragraph_comment': {
      'write': 'Comment',
      'share': 'Share',
      'count_label': '{count} comments',
    },
  };
}

RenderParagraph paragraph_render(WidgetTester tester) =>
    tester.renderObject<RenderParagraph>(
      find
          .descendant(
            of: find.byType(ParagraphSelection),
            matching: find.byType(RichText),
          )
          .first,
    );
Offset paragraph_position(WidgetTester tester, int offset) {
  final render = paragraph_render(tester);
  return render.localToGlobal(
    render.getOffsetForCaret(
          TextPosition(offset: offset),
          const Rect.fromLTWH(0, 0, 2, 20),
        ) +
        Offset(1, render.preferredLineHeight / 2),
  );
}
