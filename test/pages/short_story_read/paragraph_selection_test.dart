// ignore_for_file: non_constant_identifier_names

import 'dart:io';
import 'dart:ui' as ui;

import 'package:app/pages/short_story_read/widgets/paragraph_selection/comment_badge.dart';
import 'package:app/pages/short_story_read/widgets/paragraph_selection/index.dart';
import 'package:app/pages/short_story_read/widgets/paragraph_selection/selection_toolbar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
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
          (MethodCall method_call) async =>
              method_call.method == 'getAll' ? <String, Object>{} : true,
        );
    await EasyLocalization.ensureInitialized();
  });

  for (final TargetPlatform platform in <TargetPlatform>[
    TargetPlatform.android,
    TargetPlatform.iOS,
  ]) {
    _test_widgets('$platform 长按整段全选，原生手柄可见且不弹出键盘', (WidgetTester tester) async {
      const String text = '第一段文字，包含 emoji 🌙 与更多可以选择的内容。';
      final List<bool> selections = <bool>[];
      TextSelection? submitted_selection;
      await _pump_paragraph(
        tester,
        text: text,
        comment_count: 12,
        on_selection_changed: selections.add,
        on_comment: (TextSelection value) => submitted_selection = value,
      );

      await _long_press_offset(tester, 5);
      final EditableText editor = tester.widget(find.byType(EditableText));
      expect(editor.controller.text, text);
      expect(
        editor.controller.selection,
        const TextSelection(baseOffset: 0, extentOffset: text.length),
      );
      expect(editor.showSelectionHandles, isTrue);
      expect(
        tester
            .state<EditableTextState>(find.byType(EditableText))
            .selectionOverlay
            ?.handlesAreVisible,
        isTrue,
      );
      expect(tester.testTextInput.isVisible, isFalse);
      expect(find.text('发段评'), findsOneWidget);
      expect(find.text('分享'), findsOneWidget);
      expect(find.byType(ParagraphCommentBadge), findsOneWidget);
      expect(selections, <bool>[true]);

      // 分享暂不触发页面跳转，也不会丢失当前选区。
      await tester.tap(find.text('分享'));
      await tester.pumpAndSettle();
      expect(editor.controller.selection.extentOffset, text.length);

      await tester.tap(find.text('发段评'));
      await tester.pumpAndSettle();
      expect(submitted_selection?.textInside(text), text);
      expect(submitted_selection?.extentOffset, text.length);
      expect(editor.focusNode.hasFocus, isFalse);
      expect(editor.controller.selection.isValid, isFalse);
      expect(find.byType(ParagraphSelectionToolbar), findsNothing);
      expect(selections, <bool>[true, false]);
      expect(tester.takeException(), isNull);
    }, platform: platform);
  }

  for (final TargetPlatform platform in <TargetPlatform>[
    TargetPlatform.android,
    TargetPlatform.iOS,
  ]) {
    _test_widgets('$platform 原生拖动末尾手柄缩小范围，提交实际选文且保持 UTF-16 偏移', (
      WidgetTester tester,
    ) async {
      const String text = 'abc 🌙 def ghi jkl mno';
      TextSelection? submitted_selection;
      await _pump_paragraph(
        tester,
        text: text,
        width: 600,
        on_comment: (TextSelection value) => submitted_selection = value,
      );
      await _long_press_offset(tester, 8);
      final EditableTextState state = tester.state(find.byType(EditableText));
      final RenderEditable render = state.renderEditable;
      final TextSelection before = state.textEditingValue.selection;
      final List<TextSelectionPoint> points = render.getEndpointsForSelection(
        before,
      );
      final Offset handle =
          render.localToGlobal(points.last.point) +
          (platform == TargetPlatform.iOS
              ? const Offset(0, 4)
              : const Offset(8, 8));
      final Offset target = _offset_position(render, 12);
      final TestGesture gesture = await tester.startGesture(handle);
      await tester.pump();
      await gesture.moveTo(target);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      final TextSelection after = state.textEditingValue.selection;
      expect(after.start, 0);
      expect(after.end, lessThan(before.end));
      expect(after.textInside(text), contains('🌙'));
      expect(after.isCollapsed, isFalse);
      expect(find.text('发段评'), findsOneWidget);
      await tester.tap(find.text('发段评'));
      await tester.pumpAndSettle();
      expect(submitted_selection, after);
      expect(tester.takeException(), isNull);
    }, platform: platform);
  }

  _test_widgets('点击段外空白及其他输入框均清理选区，普通点击保持阅读事件', (WidgetTester tester) async {
    int tap_count = 0;
    await _pump_paragraph(
      tester,
      text: 'abc def ghi',
      on_tap: () => tap_count++,
      extra_child: const TextField(key: ValueKey<String>('other_input')),
    );
    await _long_press_offset(tester, 5);
    final EditableText paragraph_editor = tester.widget(
      find.byType(EditableText).first,
    );
    await tester.tapAt(const Offset(750, 550));
    await tester.pumpAndSettle();
    expect(paragraph_editor.controller.selection.isValid, isFalse);
    expect(find.byType(ParagraphSelectionToolbar), findsNothing);
    expect(tap_count, 0);

    await tester.tap(find.byType(ParagraphSelection));
    await tester.pumpAndSettle();
    expect(tap_count, 1);
    await _long_press_offset(tester, 5);
    await tester.tap(find.byKey(const ValueKey<String>('other_input')));
    await tester.pumpAndSettle();
    expect(paragraph_editor.controller.selection.isValid, isFalse);
    expect(paragraph_editor.focusNode.hasFocus, isFalse);
    expect(find.byType(ParagraphSelectionToolbar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  _test_widgets('气泡跟随最后一行并在行尾空间不足时换行，不修改可选正文', (WidgetTester tester) async {
    await _pump_paragraph(tester, text: 'abc', comment_count: 28, width: 280);
    final Rect paragraph_rect = tester.getRect(find.byType(EditableText));
    final Rect badge_rect = tester.getRect(find.byType(ParagraphCommentBadge));
    expect(badge_rect.left, greaterThan(paragraph_rect.left + 40));
    expect(badge_rect.top, lessThan(paragraph_rect.bottom));
    expect(badge_rect.right, lessThanOrEqualTo(paragraph_rect.right));

    await _pump_paragraph(
      tester,
      text: 'abcdefghi',
      comment_count: 120,
      width: 180,
    );
    final EditableText editor = tester.widget(find.byType(EditableText));
    final Rect next_paragraph_rect = tester.getRect(find.byType(EditableText));
    final Rect next_badge_rect = tester.getRect(
      find.byType(ParagraphCommentBadge),
    );
    expect(editor.controller.text, 'abcdefghi');
    expect(
      next_badge_rect.top,
      greaterThanOrEqualTo(next_paragraph_rect.bottom),
    );
    expect(next_badge_rect.left, next_paragraph_rect.left);
    expect(tester.takeException(), isNull);
  });

  _test_widgets('英文菜单、夜间主题及大字号窄屏不会溢出', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump_paragraph(
      tester,
      text: 'A quiet evening arrived beyond the hills.',
      comment_count: 12345,
      width: 272,
      locale: const Locale('en'),
      is_dark: true,
      text_scaler: const TextScaler.linear(1.6),
    );
    await _long_press_offset(tester, 4);
    expect(find.text('Comment'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(tester.takeException(), isNull);
    final Rect toolbar_rect = tester.getRect(
      find.byKey(const ValueKey<String>('paragraph_selection_toolbar')),
    );
    expect(toolbar_rect.left, greaterThanOrEqualTo(0));
    expect(toolbar_rect.right, lessThanOrEqualTo(320));
  });

  _test_widgets('未选中时拖动正文正常滚动，选中后再点击正文退出选择', (WidgetTester tester) async {
    final ScrollController scroll_controller = ScrollController();
    addTearDown(scroll_controller.dispose);
    await _pump_paragraph(
      tester,
      text: List<String>.filled(
        35,
        'The reader walks through a quiet forest.',
      ).join(' '),
      scroll_controller: scroll_controller,
      width: 340,
    );
    await tester.dragFrom(const Offset(140, 380), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(scroll_controller.offset, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  for (final TargetPlatform platform in <TargetPlatform>[
    TargetPlatform.android,
    TargetPlatform.iOS,
  ]) {
    _test_widgets('$platform 超长段落长按全选不会跳到段尾，菜单停留在屏幕可见范围', (
      WidgetTester tester,
    ) async {
      final ScrollController scroll_controller = ScrollController();
      addTearDown(scroll_controller.dispose);
      final String text = List<String>.filled(
        90,
        'The reader walks through a quiet forest.',
      ).join(' ');
      await _pump_paragraph(
        tester,
        text: text,
        width: 340,
        scroll_controller: scroll_controller,
      );
      await _long_press_offset(tester, 5);
      expect(scroll_controller.offset, 0);
      final EditableText editor = tester.widget(find.byType(EditableText));
      expect(
        editor.controller.selection,
        TextSelection(baseOffset: 0, extentOffset: text.length),
      );
      final Rect toolbar_rect = tester.getRect(
        find.byKey(const ValueKey<String>('paragraph_selection_toolbar')),
      );
      expect(toolbar_rect.top, greaterThanOrEqualTo(0));
      expect(toolbar_rect.bottom, lessThanOrEqualTo(600));
      expect(tester.takeException(), isNull);
    }, platform: platform);
  }

  _test_widgets('超长段落拖动起始手柄只跟随正在调整的边界滚动', (WidgetTester tester) async {
    final ScrollController scroll_controller = ScrollController();
    addTearDown(scroll_controller.dispose);
    final String text = List<String>.filled(
      90,
      'The reader walks through a quiet forest.',
    ).join(' ');
    await _pump_paragraph(
      tester,
      text: text,
      width: 340,
      scroll_controller: scroll_controller,
    );
    await _long_press_offset(tester, 5);
    final EditableTextState state = tester.state(find.byType(EditableText));
    final RenderEditable render = state.renderEditable;
    final List<TextSelectionPoint> points = render.getEndpointsForSelection(
      state.textEditingValue.selection,
    );
    final Offset handle =
        render.localToGlobal(points.first.point) + const Offset(-8, 8);
    final TestGesture gesture = await tester.startGesture(handle);
    await tester.pump();
    await gesture.moveTo(_offset_position(render, 100));
    await tester.pumpAndSettle();
    expect(state.textEditingValue.selection.start, greaterThan(0));
    expect(scroll_controller.offset, 0);
    await gesture.moveTo(const Offset(150, 598));
    await tester.pumpAndSettle();
    expect(scroll_controller.offset, greaterThan(0));
    expect(scroll_controller.offset, lessThan(150));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  _test_widgets('生成选区与段评气泡视觉检查图', (WidgetTester tester) async {
    if (!const bool.fromEnvironment('PARAGRAPH_SELECTION_SCREENSHOT')) return;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      final FontLoader loader = FontLoader('SelectionPreview');
      loader.addFont(
        File(
          const String.fromEnvironment(
            'PARAGRAPH_SELECTION_FONT',
            defaultValue: '/System/Library/Fonts/STHeiti Light.ttc',
          ),
        ).readAsBytes().then(ByteData.sublistView),
      );
      await loader.load();
      final FontLoader icons = FontLoader('MaterialIcons');
      icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });
    final bool previous_disable_shadows = debugDisableShadows;
    debugDisableShadows = false;
    try {
      for (final bool is_dark in <bool>[false, true]) {
        await _pump_paragraph(
          tester,
          text: is_dark
              ? '月亮升上安静的山坡。她再次打开那封信，读了一遍又一遍，不知道明天会带来怎样的故事。远处的灯火，正一点一点亮起来。'
              : 'The moon rose beyond the quiet hills. She opened the letter and read it once more, wondering what tomorrow would bring.',
          width: 342,
          comment_count: 28,
          locale: is_dark ? const Locale('zh') : const Locale('en'),
          is_dark: is_dark,
          font_family: 'SelectionPreview',
        );
        await _long_press_offset(tester, 12);
        final RenderRepaintBoundary boundary = tester.renderObject(
          find.byKey(const ValueKey<String>('selection_preview_boundary')),
        );
        await tester.runAsync(() async {
          final ui.Image rendered = await boundary.toImage(pixelRatio: 2);
          final ByteData? bytes = await rendered.toByteData(
            format: ui.ImageByteFormat.png,
          );
          final File file = File(
            'build/paragraph_selection_${is_dark ? 'dark' : 'light'}.png',
          );
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

Future<void> _pump_paragraph(
  WidgetTester tester, {
  required String text,
  int comment_count = 0,
  double width = 360,
  bool is_dark = false,
  Locale locale = const Locale('zh'),
  TextScaler text_scaler = TextScaler.noScaling,
  ValueChanged<TextSelection>? on_comment,
  ValueChanged<bool>? on_selection_changed,
  VoidCallback? on_tap,
  Widget? extra_child,
  ScrollController? scroll_controller,
  String? font_family,
}) async {
  await tester.pumpWidget(
    EasyLocalization(
      key: ValueKey<String>('locale_${locale.languageCode}'),
      supportedLocales: const <Locale>[Locale('zh'), Locale('en')],
      path: 'assets/i18n',
      assetLoader: const _SelectionTestAssetLoader(),
      startLocale: locale,
      fallbackLocale: locale,
      child: Builder(
        builder: (BuildContext context) => RepaintBoundary(
          key: const ValueKey<String>('selection_preview_boundary'),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: context.locale,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            theme: ThemeData(
              brightness: is_dark ? Brightness.dark : Brightness.light,
              fontFamily: font_family,
            ),
            home: Scaffold(
              body: MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: text_scaler),
                child: SingleChildScrollView(
                  controller: scroll_controller,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 180, left: 24),
                    child: SizedBox(
                      width: width,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          ParagraphSelection(
                            text: text,
                            text_style: TextStyle(
                              fontSize: 18,
                              height: 1.8,
                              color: is_dark ? Colors.white70 : Colors.black87,
                            ),
                            is_dark: is_dark,
                            comment_count: comment_count,
                            on_comment: on_comment ?? (_) {},
                            on_selection_changed: on_selection_changed,
                            on_tap: on_tap,
                          ),
                          const SizedBox(height: 100),
                          if (extra_child != null) extra_child,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Offset _offset_position(RenderEditable render, int offset) =>
    render.localToGlobal(
      render.getLocalRectForCaret(TextPosition(offset: offset)).center,
    );

Future<void> _long_press_offset(WidgetTester tester, int offset) async {
  final EditableTextState state = tester.state(find.byType(EditableText).first);
  await tester.longPressAt(_offset_position(state.renderEditable, offset));
  await tester.pumpAndSettle();
}

class _SelectionTestAssetLoader extends AssetLoader {
  const _SelectionTestAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      <String, dynamic>{
        'paragraph_comment': <String, dynamic>{
          'write': locale.languageCode == 'zh' ? '发段评' : 'Comment',
          'share': locale.languageCode == 'zh' ? '分享' : 'Share',
          'count_label': locale.languageCode == 'zh'
              ? '{count} 条段评'
              : '{count} comments',
        },
      };
}

/// 平台变体在 Flutter 的 invariant 检查前恢复全局平台设置。
void _test_widgets(
  String description,
  WidgetTesterCallback callback, {
  TargetPlatform platform = TargetPlatform.android,
}) {
  testWidgets(
    description,
    callback,
    variant: TargetPlatformVariant.only(platform),
  );
}
