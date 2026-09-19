// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:app/components/paragraph_selection/comment_badge.dart';
import 'package:app/models/paragraph_anchor.dart';
import 'package:app/pages/short_story_read/models/story_paragraph.dart';
import 'package:app/pages/short_story_read/widgets/paragraph_selection/index.dart';
import 'package:app/pages/short_story_read/widgets/story_content.dart';
import 'package:app/pages/short_story_read/widgets/story_unlock_gate/index.dart';
import 'package:crypto/crypto.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (method_call) async =>
              method_call.method == 'getAll' ? <String, Object>{} : true,
        );
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('锁定预览保留首段缩进，引用 emoji 与段评气泡对应原始偏移', (tester) async {
    const first = '  A moon 🌙 rises.';
    final content =
        '\r\n$first\r\n${List.filled(150, 'The story continues.').join(' ')}';
    StoryParagraph? selected;
    TextSelection? selection;
    await pump_reader(
      tester,
      StoryUnlockGate(
        content: content,
        is_dark: false,
        is_loading: false,
        is_unlocked: false,
        is_unlocking: false,
        font_size: 18,
        on_unlock: () {},
        paragraph_anchors: [make_anchor('1', first, 2, 5)],
        on_paragraph_comment: (paragraph, range) {
          selected = paragraph;
          selection = range;
        },
      ),
    );

    final paragraph = tester
        .widgetList<ParagraphSelection>(find.byType(ParagraphSelection))
        .first;
    expect(paragraph.text, first);
    expect(paragraph.comment_count, 5);
    final moon_start = first.indexOf('🌙');
    paragraph.on_comment(
      TextSelection(
        baseOffset: moon_start,
        extentOffset: moon_start + '🌙'.length,
      ),
    );
    expect(selected?.anchor?.id, '1');
    expect(selected?.start_offset, 2);
    expect(
      content.substring(
        selected!.start_offset + selection!.start,
        selected!.start_offset + selection!.end,
      ),
      '🌙',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('发送结果只刷新对应段落的数量，相同文字的其他段落保持独立', (tester) async {
    const text = 'Repeated paragraph.';
    Widget build_content(int first_count) => StoryContent(
      content: '$text\n$text',
      is_dark: true,
      paragraph_anchors: [
        make_anchor('1', text, 0, first_count),
        make_anchor('2', text, text.length + 1, 7),
      ],
      on_paragraph_comment: (_, _) {},
    );

    await pump_reader(tester, build_content(3));
    expect(
      tester
          .widgetList<ParagraphSelection>(find.byType(ParagraphSelection))
          .map((paragraph) => paragraph.comment_count),
      [3, 7],
    );
    await pump_reader(tester, build_content(4));
    expect(
      tester
          .widgetList<ParagraphSelection>(find.byType(ParagraphSelection))
          .map((paragraph) => paragraph.comment_count),
      [4, 7],
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('短篇解锁组件把实际段落身份传给共用详情入口，气泡不触发阅读点击', (
    tester,
  ) async {
    const text = 'Repeated paragraph.';
    final opened = <(String, int, String?)>[];
    int reading_taps = 0;

    await pump_reader(
      tester,
      StoryUnlockGate(
        content: '$text\n$text',
        is_dark: true,
        is_loading: false,
        is_unlocked: true,
        is_unlocking: false,
        font_size: 18,
        on_unlock: () {},
        paragraph_anchors: [
          make_anchor('11', text, 0, 3),
          make_anchor('12', text, text.length + 1, 7),
        ],
        on_paragraph_comment: (_, _) {},
        on_content_tap: () => reading_taps++,
        on_comment_count_tap: (text, count, id) => opened.add((text, count, id)),
      ),
    );

    await tester.tap(find.byType(ParagraphCommentBadge).last);
    await tester.pumpAndSettle();
    expect(opened, [(text, 7, '12')]);
    expect(reading_taps, 0);
    expect(tester.takeException(), isNull);
  });
}

ParagraphAnchor make_anchor(String id, String text, int start, int count) =>
    ParagraphAnchor(
      id: id,
      paragraph_no: int.parse(id),
      start_offset: start,
      end_offset: start + text.length,
      content_hash: sha256.convert(utf8.encode(text)).toString(),
      comment_count: count,
    );

Future<void> pump_reader(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/i18n',
      assetLoader: const _ReaderAssetLoader(),
      startLocale: const Locale('en'),
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(padding: const EdgeInsets.all(24), child: child),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _ReaderAssetLoader extends AssetLoader {
  const _ReaderAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {
    'short_story_read': {
      'locked_remaining_words': '{count} words remaining',
      'watch_ad_to_continue': 'Watch ad to continue',
    },
    'paragraph_comment': {'count_label': '{count} comments'},
  };
}
