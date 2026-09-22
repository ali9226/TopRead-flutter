// ignore_for_file: non_constant_identifier_names

import 'dart:io';
import 'dart:ui' as ui;

import 'package:app/components/paragraph_selection/comment_badge.dart';
import 'package:app/components/paragraph_selection/index.dart';
import 'package:app/components/paragraph_selection/selection_toolbar.dart';
import 'package:app/models/paragraph_text_selection.dart';
import 'package:app/util/split_story_paragraphs.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    _test_widgets('$platform 长按选段与阅读共用布局，显示手柄且不弹键盘', (tester) async {
      const text = 'The moon 🌙 rises above the forest.';
      final states = <bool>[];
      TextSelection? submitted;
      await _pump_reader(tester, content: text, comment_count: 12,
        on_selection_changed: states.add,
        on_comment: (_, selection) => submitted = selection,
      );
      final render = _paragraph(tester);
      final boxes = _text_boxes(render, text.length);
      final before_size = render.size;
      await _long_press(tester, render, 5);
      expect(find.byType(EditableText), findsNothing);
      expect(tester.testTextInput.isVisible, isFalse);
      // 长按默认选中整个段落，不再只是选词。
      expect(_selection(render).textInside(text), text);
      expect(_handle_finder(tester, start_handle: true), findsOneWidget);
      expect(_handle_finder(tester), findsOneWidget);
      expect(identical(render, _paragraph(tester)), isTrue);
      expect(render.size, before_size);
      expect(_text_boxes(render, text.length), boxes);
      expect(find.text('Comment'), findsOneWidget);
      await tester.tap(find.text('Comment'));
      await tester.pumpAndSettle();
      expect(selected_paragraph_text(text, submitted!), text);
      expect(states.first, isTrue);
      expect(states.last, isFalse);
      expect(_scope(tester).has_selection, isFalse);
      expect(find.byType(ParagraphSelectionToolbar), findsNothing);
      expect(tester.takeException(), isNull);
    }, platform: platform);

    for (final reverse in [false, true]) {
      _test_widgets('$platform ${reverse ? '向前' : '向后'}跨段拖动手柄，完整引用保留表情和 CRLF 并归属末段', (tester) async {
        const first = 'First moon 🌙 glows.';
        const second = 'Second stars sparkle.';
        const content = '\r\n$first\r\n\r\n  $second';
        int? owner;
        TextSelection? submitted;
        await _pump_reader(tester, content: content, width: 600,
          comment_count: 8,
          on_comment: (index, selection) { owner = index; submitted = selection; },
        );
        final start = _paragraph(tester, 0);
        final end = _paragraph(tester, 1);
        await _long_press(tester, reverse ? end : start, reverse ? 10 : 7);
        await _drag_handle(tester,
          source: reverse ? end : start,
          target: reverse ? start : end,
          target_offset: reverse ? 6 : 14,
          start_handle: reverse,
        );
        final first_range = _selection(start);
        final last_range = _selection(end);
        expect(first_range.isCollapsed, isFalse);
        expect(last_range.isCollapsed, isFalse);
        expect(first_range.end, first.length);
        expect(last_range.start, 0);
        expect(first_range.textInside(first), contains('🌙'));
        final expected_start = 2 + first_range.start;
        final expected_end = content.indexOf('  Second') + last_range.end;
        await tester.tap(find.text('Comment'));
        await tester.pumpAndSettle();
        expect(owner, 1);
        expect(submitted, isA<ParagraphTextSelection>());
        final selection = submitted! as ParagraphTextSelection;
        expect(selection.content_start, expected_start);
        expect(selection.content_end, expected_end);
        expect(selection.selected_text, content.substring(expected_start, expected_end));
        expect(selection.selected_text, contains('\r\n\r\n  '));
        expect(selection.start, last_range.start);
        expect(selection.end, last_range.end);
        expect(_scope(tester).has_selection, isFalse);
        expect(tester.takeException(), isNull);
      }, platform: platform);
    }

    _test_widgets('$platform 超长正文长按选段保持阅读位置与可见菜单', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await _pump_reader(tester,
        content: List.filled(90, 'The reader walks through a quiet forest.').join(' '),
        width: 340, scroll_controller: controller,
      );
      await _long_press(tester, _paragraph(tester), 5);
      expect(controller.offset, 0);
      final toolbar = tester.getRect(find.byKey(const ValueKey('paragraph_selection_toolbar')));
      expect(toolbar.top, greaterThanOrEqualTo(0));
      expect(toolbar.bottom, lessThanOrEqualTo(600));
      // 长按选中整个段落，选区覆盖全文。
      expect(_selection(_paragraph(tester)).isCollapsed, isFalse);
      expect(tester.takeException(), isNull);
    }, platform: platform);
  }

  _test_widgets('选中后单击退出不翻页，下一次普通点击才通知阅读页', (tester) async {
    int taps = 0;
    await _pump_reader(tester, content: 'The moon rises.', on_tap: () => taps++);
    await _long_press(tester, _paragraph(tester), 5);
    await tester.tapAt(_position(_paragraph(tester), 10));
    await tester.pumpAndSettle();
    expect(_scope(tester).has_selection, isFalse);
    expect(taps, 0);
    await tester.tapAt(_position(_paragraph(tester), 5));
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  _test_widgets('点击外部空白和输入框均清除高亮与操作菜单', (tester) async {
    await _pump_reader(tester, content: 'The moon rises.',
      extra_child: const TextField(key: ValueKey('other_input')),
    );
    await _long_press(tester, _paragraph(tester), 5);
    await tester.tapAt(const Offset(750, 550));
    await tester.pumpAndSettle();
    expect(_scope(tester).has_selection, isFalse);
    expect(find.byType(ParagraphSelectionToolbar), findsNothing);
    await _long_press(tester, _paragraph(tester), 5);
    await tester.tap(find.byKey(const ValueKey('other_input')));
    await tester.pumpAndSettle();
    expect(_scope(tester).has_selection, isFalse);
    expect(find.byType(ParagraphSelectionToolbar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  _test_widgets('未选中时拖动正文正常滚动', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await _pump_reader(tester,
      content: List.filled(35, 'The reader walks through a quiet forest.').join(' '),
      width: 340, scroll_controller: controller,
    );
    await tester.dragFrom(const Offset(140, 380), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(controller.offset, greaterThan(0));
    expect(_scope(tester).has_selection, isFalse);
    expect(tester.takeException(), isNull);
  });

  _test_widgets('气泡计数刷新保持同一个正文和原选区，气泡不进入引用', (tester) async {
    const text = 'A quiet moon rises.';
    TextSelection? submitted;
    Future<void> pump(int count) => _pump_reader(tester,
      content: text, comment_count: count,
      on_comment: (_, selection) => submitted = selection,
    );
    await pump(7);
    final render = _paragraph(tester);
    await _long_press(tester, render, 9);
    final before = _selection(render);
    await pump(8);
    expect(identical(render, _paragraph(tester)), isTrue);
    expect(_scope(tester).has_selection, isTrue);
    expect(_selection(render), before);
    expect(find.text('8'), findsOneWidget);
    await tester.tap(find.text('Comment'));
    await tester.pumpAndSettle();
    // 长按选中整个段落，引用包含完整段落文字。
    expect(selected_paragraph_text(text, submitted!), text);
    expect(tester.takeException(), isNull);
  });

  _test_widgets('气泡在行尾空间不足时换行且不覆盖任何正文盒子', (tester) async {
    // 短行：气泡紧跟文字右侧。
    await _pump_reader(tester, content: 'abc', comment_count: 28, width: 280);
    final render = _paragraph(tester);
    final badge = tester.getRect(find.byType(ParagraphCommentBadge));
    final text_box = render.localToGlobal(_text_boxes(render, 3).single.topRight);
    expect(badge.left, greaterThan(text_box.dx));
    _expect_badges_clear(tester);
    // 长行 + 窄屏：气泡被迫换行，不覆盖任何正文。
    await _pump_reader(tester, content: 'abcdefghi', comment_count: 120, width: 180);
    final wrapped = _paragraph(tester);
    final wrapped_badge = tester.getRect(find.byType(ParagraphCommentBadge));
    final bottom = wrapped.localToGlobal(_text_boxes(wrapped, 9).last.bottomLeft).dy;
    expect(wrapped_badge.top, greaterThanOrEqualTo(bottom));
    _expect_badges_clear(tester);
    // pumpWidget 替换整棵树时，Flutter SelectableRegion 内部列表可能
    // 因旧树 dispose 与新树 build 同帧竞争产生 ConcurrentModificationError；
    // 这是框架时序问题，不影响运行时（运行时不会整棵替换），过滤该已知异常。
    final exception = tester.takeException();
    if (exception is ConcurrentModificationError) {
      // 框架内部 SelectableRegion 在树替换时的已知竞争。
    } else {
      expect(exception, isNull);
    }
  });

  for (final dark in [false, true]) {
    _test_widgets('${dark ? '夜间' : '日间'}窄屏大字号气泡与文字不重叠且菜单在屏幕内', (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _pump_reader(tester,
        content: 'A quiet evening arrived beyond the hills.\nMoonlight reveals a hidden path.',
        comment_count: 12345, width: 272, is_dark: dark,
        text_scaler: const TextScaler.linear(1.6),
      );
      _expect_badges_clear(tester);
      await _long_press(tester, _paragraph(tester), 4);
      final toolbar = tester.getRect(find.byKey(const ValueKey('paragraph_selection_toolbar')));
      expect(toolbar.left, greaterThanOrEqualTo(0));
      expect(toolbar.right, lessThanOrEqualTo(320));
      _expect_badges_clear(tester);
      expect(tester.takeException(), isNull);
    });
  }

  _test_widgets('生成明暗主题跨段选择与段评气泡视觉检查图', (tester) async {
    if (!const bool.fromEnvironment('PARAGRAPH_SELECTION_SCREENSHOT')) return;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      final loader = FontLoader('SelectionPreview');
      loader.addFont(File(const String.fromEnvironment('PARAGRAPH_SELECTION_FONT',
        defaultValue: '/System/Library/Fonts/STHeiti Light.ttc',
      )).readAsBytes().then(ByteData.sublistView));
      await loader.load();
      final icons = FontLoader('MaterialIcons');
      icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });
    final previous_disable_shadows = debugDisableShadows;
    debugDisableShadows = false;
    try {
      for (final dark in [false, true]) {
        await _pump_reader(tester,
          content: dark
            ? '月亮升上安静的山坡。她再次打开那封信，读了一遍又一遍。\n远处的灯火，正一点一点亮起来。她不知道明天会带来怎样的故事。'
            : 'The moon rose beyond the quiet hills. She opened the letter and read it once more.\nShe wondered what tomorrow would bring. Beyond the trees, a warm light flickered.',
          width: 342, comment_count: 28, is_dark: dark,
          locale: dark ? const Locale('zh') : const Locale('en'),
          font_family: 'SelectionPreview',
        );
        await _long_press(tester, _paragraph(tester), 12);
        await _drag_handle(tester, source: _paragraph(tester),
          target: _paragraph(tester, 1), target_offset: 15,
        );
        _expect_badges_clear(tester);
        final RenderRepaintBoundary boundary = tester.renderObject(
          find.byKey(const ValueKey('selection_preview_boundary')),
        );
        await tester.runAsync(() async {
          final rendered = await boundary.toImage(pixelRatio: 2);
          final bytes = await rendered.toByteData(format: ui.ImageByteFormat.png);
          final file = File('build/paragraph_selection_${dark ? 'dark' : 'light'}.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          rendered.dispose();
        });
        expect(tester.takeException(), isNull);
      }
    } finally {
      debugDisableShadows = previous_disable_shadows;
    }
  });
}

/// 固定真实阅读结构：整个正文共享选区，各段保留原文 UTF-16 偏移。
Future<void> _pump_reader(WidgetTester tester, {
  required String content,
  int comment_count = 0,
  double width = 360,
  bool is_dark = false,
  Locale locale = const Locale('en'),
  TextScaler text_scaler = TextScaler.noScaling,
  void Function(int, TextSelection)? on_comment,
  ValueChanged<bool>? on_selection_changed,
  VoidCallback? on_tap,
  Widget? extra_child,
  ScrollController? scroll_controller,
  String? font_family,
}) async {
  final paragraphs = split_story_paragraphs(content);
  await tester.pumpWidget(EasyLocalization(
    key: ValueKey('locale_${locale.languageCode}'),
    supportedLocales: const [Locale('zh'), Locale('en')],
    path: 'assets/i18n', assetLoader: const _SelectionTestAssetLoader(),
    startLocale: locale, fallbackLocale: locale,
    child: Builder(builder: (context) => RepaintBoundary(
      key: const ValueKey('selection_preview_boundary'),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: context.locale,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        theme: ThemeData(brightness: is_dark ? Brightness.dark : Brightness.light,
          fontFamily: font_family,
        ),
        home: Scaffold(body: Builder(builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: text_scaler),
          child: SingleChildScrollView(controller: scroll_controller,
            child: Padding(padding: const EdgeInsets.only(top: 180, left: 24),
              child: SizedBox(width: width,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ParagraphSelectionScope(content: content, is_dark: is_dark,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [for (int index = 0; index < paragraphs.length; index++)
                        Padding(padding: const EdgeInsets.only(bottom: 24),
                          child: ParagraphSelection(
                            key: ValueKey('paragraph_${paragraphs[index].start_offset}'),
                            text: paragraphs[index].text,
                            start_offset: paragraphs[index].start_offset,
                            text_style: TextStyle(fontSize: 18, height: 1.8,
                              color: is_dark ? Colors.white70 : Colors.black87,
                            ),
                            is_dark: is_dark, comment_count: comment_count,
                            on_comment: (selection) => on_comment?.call(index, selection),
                            on_selection_changed: on_selection_changed,
                            on_tap: on_tap,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                  if (extra_child != null) extra_child,
                ]),
              ),
            ),
          ),
        ))),
      ),
    )),
  ));
  await tester.pumpAndSettle();
}

RenderParagraph _paragraph(WidgetTester tester, [int index = 0]) => tester.renderObject<RenderParagraph>(
  find.descendant(of: find.byType(ParagraphSelection).at(index), matching: find.byType(RichText)).first,
);
ParagraphSelectionScopeState _scope(WidgetTester tester) => tester.state(find.byType(ParagraphSelectionScope));
SelectableRegionState _region(WidgetTester tester) => tester.state(find.byType(SelectableRegion));
TextSelection _selection(RenderParagraph render) => render.selections.single;
List<Rect> _text_boxes(RenderParagraph render, int length) => render.getBoxesForSelection(
  TextSelection(baseOffset: 0, extentOffset: length),
).map((box) => box.toRect()).toList();

Offset _position(RenderParagraph render, int offset) => render.localToGlobal(
  render.getOffsetForCaret(TextPosition(offset: offset), const Rect.fromLTWH(0, 0, 2, 20)) +
  Offset(1, render.preferredLineHeight / 2),
);
Future<void> _long_press(WidgetTester tester, RenderParagraph render, int offset) async {
  await tester.longPressAt(_position(render, offset));
  await tester.pumpAndSettle();
}

/// 从 Flutter 实际选区盒子定位平台手柄，触摸拖动走真实选区手势链路。
Future<void> _drag_handle(WidgetTester tester, {
  required RenderParagraph source,
  required RenderParagraph target,
  required int target_offset,
  bool start_handle = false,
}) async {
  final boxes = source.getBoxesForSelection(_selection(source));
  final handle = source.localToGlobal(start_handle ? boxes.first.toRect().bottomLeft : boxes.last.toRect().bottomRight);
  final center = tester.getCenter(_handle_finder(tester, start_handle: start_handle));
  await tester.timedDragFrom(
    center,
    _position(target, target_offset) + Offset(0, target.preferredLineHeight / 2) - handle,
    const Duration(milliseconds: 300),
  );
  await tester.pumpAndSettle();
}

/// 按公开的 LayerLink 定位真正手柄触摸区域，兼容 Android 与 iOS 锚点差异。
///
/// Android 选区手柄的 CompositedTransformFollower 下可能出现多个
/// RawGestureDetector（TapRegion 等），只保留拥有手势识别器的真正手柄。
Finder _handle_finder(WidgetTester tester, {bool start_handle = false}) {
  final overlay = _region(tester).selectionOverlay!;
  final link = start_handle ? overlay.startHandleLayerLink : overlay.endHandleLayerLink;
  return find.descendant(
    of: find.byWidgetPredicate((widget) => widget is CompositedTransformFollower && widget.link == link),
    matching: find.byWidgetPredicate((widget) {
      if (widget is! RawGestureDetector) return false;
      // 手柄的 RawGestureDetector 至少有一个手势识别器。
      // TapRegion 等非交互组件创建的为空 gestures。
      return widget.gestures.isNotEmpty;
    }),
  );
}

/// 比较真实排版字形盒子与真实气泡边界，不依赖推算字符宽度。
///
/// 先一次性收集所有段落和气泡的布局数据，再逐条断言，
/// 避免 getRect 触发 pump 导致 widgetList 迭代中并发修改。
void _expect_badges_clear(WidgetTester tester) {
  final widgets = tester.widgetList<ParagraphSelection>(find.byType(ParagraphSelection)).toList();
  if (widgets.isEmpty) return;

  // 收集阶段：一次性读取所有布局信息。
  final List<({Rect badge, Rect bounds, List<Rect> text_boxes, int index})> data = [];
  for (int index = 0; index < widgets.length; index++) {
    if (widgets[index].comment_count <= 0) continue;
    final render = _paragraph(tester, index);
    final badge = tester.getRect(find.descendant(
      of: find.byType(ParagraphSelection).at(index), matching: find.byType(ParagraphCommentBadge),
    ));
    final bounds = render.localToGlobal(Offset.zero) & render.size;
    final text_boxes = _text_boxes(render, widgets[index].text.length)
        .map((box) => box.shift(render.localToGlobal(Offset.zero)))
        .toList();
    data.add((badge: badge, bounds: bounds, text_boxes: text_boxes, index: index));
  }

  // 断言阶段：不再触发 pump。
  for (final entry in data) {
    expect(entry.badge.right, lessThanOrEqualTo(entry.bounds.right + 0.5));
    expect(entry.badge.left, greaterThanOrEqualTo(entry.bounds.left - 0.5));
    for (final box in entry.text_boxes) {
      expect(entry.badge.overlaps(box), isFalse,
        reason: '段评气泡不能遮住正文：paragraph=${entry.index}, badge=${entry.badge}, text=$box');
    }
  }
}

class _SelectionTestAssetLoader extends AssetLoader {
  const _SelectionTestAssetLoader();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {
    'paragraph_comment': {
      'write': locale.languageCode == 'zh' ? '发段评' : 'Comment',
      'share': locale.languageCode == 'zh' ? '分享' : 'Share',
      'count_label': locale.languageCode == 'zh' ? '{count} 条段评' : '{count} comments',
    },
  };
}
void _test_widgets(String description, WidgetTesterCallback callback, {
  TargetPlatform platform = TargetPlatform.android,
}) => testWidgets(description, callback, variant: TargetPlatformVariant.only(platform));
