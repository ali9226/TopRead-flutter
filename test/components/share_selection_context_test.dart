import 'dart:io';
import 'dart:ui' as ui;

import 'package:app/components/share_sheet/fit_share_excerpt.dart';
import 'package:app/components/share_sheet/share_work_url.dart';
import 'package:app/components/share_sheet/style.dart';
import 'package:app/components/share_sheet/widgets/text_selection_poster_card.dart';
import 'package:app/components/share_sheet/widgets/text_selection_preview_sheet.dart';
import 'package:app/models/paragraph_text_selection.dart';
import 'package:app/models/share_excerpt.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _preview_dir = String.fromEnvironment('SELECTION_POSTER_PREVIEW_DIR');

ShareExcerpt _excerpt(
  String source,
  String paragraph,
  int start,
  int end,
) => ShareExcerpt.from_selection(
  paragraph_text: paragraph,
  paragraph_start: source.indexOf(paragraph),
  selection: ParagraphTextSelection(
    baseOffset: (start - source.indexOf(paragraph)).clamp(0, paragraph.length),
    extentOffset: (end - source.indexOf(paragraph)).clamp(0, paragraph.length),
    selected_text: source.substring(start, end),
    content_start: start,
    content_end: end,
    source_content: source,
  ),
)!;

FittedShareExcerpt _fit(ShareExcerpt excerpt, {double height = 260}) =>
    fit_share_excerpt(
      excerpt: excerpt,
      style: const TextStyle(fontSize: 16, height: 1.5),
      selected_color: Colors.black,
      context_color: Colors.grey,
      width: 280,
      height: height,
      direction: ui.TextDirection.ltr,
      scaler: TextScaler.noScaling,
      locale: const Locale('en'),
      truncation_reserve: 18,
    );

Iterable<TextSpan> _leaves(InlineSpan span) sync* {
  if (span is! TextSpan) return;
  if (span.text?.isNotEmpty == true) yield span;
  for (final child in span.children ?? <InlineSpan>[]) {
    yield* _leaves(child);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (_) async => <String, Object>{},
        );
    await EasyLocalization.ensureInitialized();
    if (_preview_dir.isNotEmpty) {
      final font = File('/System/Library/Fonts/Supplemental/Arial Unicode.ttf');
      if (font.existsSync()) {
        await (FontLoader('Roboto')..addFont(
              Future.value(ByteData.sublistView(font.readAsBytesSync())),
            ))
            .load();
      }
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
  });

  test('重复词仅高亮准确选区，完整所在段及前后可见段保留为语境', () {
    const paragraph = '重要的不是次数，而是这一次重要的选择。';
    const source = '前一段为故事铺垫。\r\n\r\n$paragraph\r\n\r\n后一段接着讲述。';
    final start = source.lastIndexOf('重要');
    final excerpt = _excerpt(source, paragraph, start, start + 2);
    expect(excerpt.selected_text, '重要');
    expect(excerpt.before_text, '重要的不是次数，而是这一次');
    expect(excerpt.after_text, '的选择。');
    expect(excerpt.previous_paragraph, '前一段为故事铺垫。');
    expect(excerpt.next_paragraph, '后一段接着讲述。');
    final fitted = _fit(excerpt, height: 400);
    expect(fitted.span.toPlainText(), contains(paragraph));
    expect(
      _leaves(fitted.span)
          .where((span) => span.style?.color == Colors.black)
          .map((span) => span.text)
          .join(),
      '重要',
    );
    expect(
      _leaves(fitted.span)
          .where((span) => span.style?.color == Colors.grey)
          .map((span) => span.text)
          .join(),
      contains('重要的不是次数'),
    );
  });

  test('整段优先完整显示，空间不足先舍邻段而非选中内容', () {
    const chosen = 'The chosen paragraph stays readable and complete.';
    final excerpt = ShareExcerpt(
      selected_text: chosen,
      previous_paragraph: List.filled(100, 'Before context.').join(' '),
      next_paragraph: List.filled(100, 'After context.').join(' '),
    );
    final fitted = _fit(excerpt, height: 100);
    expect(fitted.selection_truncated, false);
    expect(fitted.span.toPlainText(), contains(chosen));
    expect(fitted.span.toPlainText().length, lessThan(350));
    expect(
      _leaves(fitted.span)
          .where((span) => span.style?.color == Colors.black)
          .map((span) => span.text)
          .join(),
      chosen,
    );
  });

  test('很长同段以选区为中心裁语境，不会把末尾选择用普通ellipsis吞掉', () {
    final excerpt = ShareExcerpt(
      selected_text: 'KEEP THIS',
      before_text: List.filled(300, 'prefix').join(' '),
      after_text: List.filled(300, 'suffix').join(' '),
    );
    final fitted = _fit(excerpt, height: 100);
    expect(fitted.selection_truncated, false);
    expect(fitted.span.toPlainText(), contains('KEEP THIS'));
    expect(fitted.span.toPlainText(), contains('…'));
  });

  test('跨段UTF16、组合字符和表情边界准确，锁定预览不能补未解锁内容', () {
    const source = '第一段😀文字。\n\n第二段保留 e\u0301 和👨‍👩‍👧‍👦。\n\n第三段。';
    const last = '第二段保留 e\u0301 和👨‍👩‍👧‍👦。';
    final start = source.indexOf('😀');
    final end = source.indexOf('👨') + '👨‍👩‍👧‍👦'.length;
    final excerpt = _excerpt(source, last, start, end);
    expect(excerpt.selected_text, source.substring(start, end));
    expect(excerpt.before_text, '第一段');
    expect(excerpt.after_text, '。');
    const visible = '只显示这一段。';
    final preview = _excerpt(visible, visible, 3, 5);
    expect(preview.previous_paragraph, isEmpty);
    expect(preview.next_paragraph, isEmpty);
    expect(
      '${preview.before_text}${preview.selected_text}${preview.after_text}',
      visible,
    );
    const emoji = '甲👨‍👩‍👧‍👦乙';
    expect(_excerpt(emoji, emoji, 2, 3).selected_text, '👨‍👩‍👧‍👦');
  });

  test('无源快照的旧选区只分享真实选文，不用搜词伪造上下文', () {
    final excerpt = ShareExcerpt.from_selection(
      paragraph_text: '相同词相同词',
      paragraph_start: 0,
      selection: const ParagraphTextSelection(
        baseOffset: 0,
        extentOffset: 3,
        selected_text: '旧的真实选文',
        content_start: 300,
        content_end: 307,
      ),
    );
    expect(excerpt!.selected_text, '旧的真实选文');
    expect(excerpt.before_text, isEmpty);
    expect(excerpt.next_paragraph, isEmpty);
  });

  test('极长选文明确保留头尾并标记省略，组合字符不被截断', () {
    final chosen =
        'START ${List.filled(1500, '👨‍👩‍👧‍👦 e\u0301').join(' ')} END';
    final fitted = _fit(ShareExcerpt.selected_only(chosen), height: 180);
    final text = fitted.span.toPlainText();
    expect(fitted.selection_truncated, true);
    expect(text, startsWith('START'));
    expect(text, endsWith('END'));
    expect(text, contains('…'));
    expect(text.contains('\uFFFD'), false);
  });

  for (final scenario in <(String, bool, double)>[
    ('zh', false, 1),
    ('en', true, 1),
    ('zh', false, 2),
  ]) {
    testWidgets('选区与浅色语境海报 ${scenario.$1}/${scenario.$2}/${scenario.$3} 无溢出可导出', (
      tester,
    ) async {
      const source = '前一段讲述路途的起点。\n\n我在漫长的旅途中，终于发现值得珍藏的光。\n\n后一段还有新的故事。';
      const paragraph = '我在漫长的旅途中，终于发现值得珍藏的光。';
      final start = source.indexOf('值得珍藏');
      final excerpt = _excerpt(source, paragraph, start, start + 4);
      final boundary = GlobalKey();
      await _mount(
        tester,
        TextSelectionPosterCard(
          novel_id: 42,
          novel_title: '长夜里的微光',
          novel_author: '林川',
          novel_cover_url: '',
          share_text: excerpt.selected_text,
          excerpt: excerpt,
          work_kind: WorkShareKind.short_story,
          user_avatar_url: '',
          user_nickname: '小满',
          date_text: '2026.10.26',
          fallback_avatar_index: 3,
          canvas_colors:
              ShareSheetStyle.card_gradient_colors[scenario.$2 ? 1 : 0],
          accent_color: ShareSheetStyle.card_accent_colors[scenario.$2 ? 1 : 0],
          footer_color: ShareSheetStyle.card_footer_colors[scenario.$2 ? 1 : 0],
          use_dark_palette: scenario.$2,
        ),
        boundary: boundary,
        language: scenario.$1,
        scale: scenario.$3,
      );
      final rich = tester.widget<RichText>(
        find.byKey(const ValueKey('selection_share_excerpt')),
      );
      expect(rich.text.toPlainText(), contains('值得珍藏'));
      if (scenario.$3 == 1) {
        expect(rich.text.toPlainText(), contains(paragraph));
      }
      expect(
        _leaves(
          rich.text,
        ).where((span) => span.text == '值得珍藏').single.style?.color,
        scenario.$2
            ? ShareSheetStyle.poster_primary_text_color_dark
            : ShareSheetStyle.poster_primary_text_color,
      );
      expect(tester.takeException(), isNull);
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await render.toImage();
      expect(image.width, ShareSheetStyle.poster_design_width.toInt());
      if (_preview_dir.isNotEmpty) {
        await tester.runAsync(() async {
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(_preview_dir).create(recursive: true);
          await File(
            '$_preview_dir/selection_${scenario.$1}_${scenario.$2}_${scenario.$3}.png',
          ).writeAsBytes(data!.buffer.asUint8List());
        });
      }
      image.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('长选文扩成完整长图，预览按宽度展示并可纵向查看', (tester) async {
    final text = List.filled(12, '这是一段较长的选文，文字应完整保留在导出的长图中。').join();
    final excerpt = ShareExcerpt.selected_only(text);
    await _mount(
      tester,
      TextSelectionPreviewSheet(
        novel_id: 42,
        novel_title: 'A long story',
        novel_cover_url: '',
        share_text: text,
        excerpt: excerpt,
        is_dark: false,
      ),
      size: const Size(390, 844),
    );
    final card = find.byType(TextSelectionPosterCard).first;
    expect(
      tester.getSize(card).height,
      greaterThan(ShareSheetStyle.poster_design_height),
    );
    final scroll = find.byKey(const ValueKey('selection_poster_scroll_0'));
    expect(scroll, findsOneWidget);
    final rich = tester.widget<RichText>(
      find.byKey(const ValueKey('selection_share_excerpt')).first,
    );
    expect(rich.text.toPlainText(), contains(text));
    expect(
      find.byKey(const ValueKey('selection_share_truncation')),
      findsNothing,
    );
    await tester.drag(scroll, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final screen in <(Size, bool)>[
    (const Size(390, 844), false),
    (const Size(844, 390), true),
    (const Size(466, 678), false),
    (const Size(390, 1200), false),
  ]) {
    testWidgets('真实选词分享弹窗背景贴底且保留平台图标 $screen', (tester) async {
      tester.view.padding = const FakeViewPadding(bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(bottom: 34);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      await _mount(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showTextSelectionPreviewSheet(
              context: context,
              novel_id: 42,
              novel_title: 'A story',
              novel_cover_url: '',
              share_text: 'A chosen passage.',
              is_dark: screen.$2,
            ),
            child: const Text('Open share'),
          ),
        ),
        size: screen.$1,
        language: 'en',
      );
      await tester.tap(find.text('Open share'));
      await tester.pumpAndSettle();
      expect(
        tester.getBottomLeft(find.byType(TextSelectionPreviewSheet)).dy,
        closeTo(screen.$1.height, 0.1),
      );
      if (screen.$1.height == 1200) {
        expect(
          tester.getSize(find.byType(TextSelectionPreviewSheet)).height,
          lessThan(screen.$1.height * 0.9),
          reason: '内容较少时按内容收拢，不强制占满屏幕九成高度',
        );
      }
      for (final platform in ['whatsapp', 'x', 'telegram']) {
        expect(find.byKey(ValueKey('share_channel_$platform')), findsOneWidget);
      }
      await tester.ensureVisible(find.text('Save image'));
      await tester.pumpAndSettle();
      expect(
        tester.getBottomLeft(find.text('Save image')).dy,
        lessThanOrEqualTo(screen.$1.height - 34),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final screen in <(Size, double, bool)>[
    (const Size(720, 390), 2, true),
    (const Size(466, 678), 1.5, false),
  ]) {
    testWidgets('选词分享预览横屏与Duo大字可滚到保存入口 $screen', (tester) async {
      final excerpt = ShareExcerpt(
        selected_text: 'An exact chosen passage.',
        before_text: 'A little readable context before ',
        after_text: ' and context afterwards.',
      );
      await _mount(
        tester,
        TextSelectionPreviewSheet(
          novel_id: 42,
          novel_title: 'A very long title for a wonderful story',
          novel_cover_url: '',
          share_text: excerpt.selected_text,
          excerpt: excerpt,
          is_dark: screen.$3,
        ),
        size: screen.$1,
        scale: screen.$2,
        language: 'en',
      );
      await tester.ensureVisible(find.text('Save image'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Save image'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}

Future<void> _mount(
  WidgetTester tester,
  Widget child, {
  GlobalKey? boundary,
  String language = 'zh',
  double scale = 1,
  Size size = const Size(390, 900),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('zh'), Locale('en')],
      startLocale: Locale(language),
      fallbackLocale: const Locale('zh'),
      path: 'assets/i18n',
      saveLocale: false,
      assetLoader: const _Assets(),
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(scale),
            ),
            child: Scaffold(
              body: Center(
                child: boundary == null
                    ? child
                    : RepaintBoundary(key: boundary, child: child),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

class _Assets extends AssetLoader {
  const _Assets();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {
    'share_sheet': {
      'default_reader': 'Reader',
      'card_preview_title': 'Preview',
      'save_to_album': 'Save image',
      'excerpt_by': '{name} · Excerpt',
      'read_together': 'Read with {app}',
      'qr_semantics': 'Work link',
      'copy_link': 'Copy link',
      'excerpt_truncated': 'Long excerpt shortened; … marks omitted text.',
    },
  };
}
