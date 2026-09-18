// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:app/components/paragraph_comment_composer/index.dart';
import 'package:app/components/paragraph_comment_composer/logic.dart';
import 'package:app/components/paragraph_comment_composer/style.dart';
import 'package:app/components/paragraph_comment_composer/widgets/composer_body.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final Finder _composer = find.byKey(
  const ValueKey<String>('paragraph_comment_composer'),
);
final Finder _input = find.byKey(
  const ValueKey<String>('paragraph_comment_input'),
);
final Finder _send = find.byKey(
  const ValueKey<String>('paragraph_comment_send'),
);
final Finder _toggle = find.byKey(
  const ValueKey<String>('paragraph_comment_toggle_emoji'),
);
final Finder _emoji_panel = find.byKey(
  const ValueKey<String>('comment_emoji_panel'),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (MethodCall call) async =>
              call.method == 'getAll' ? <String, Object>{} : true,
        );
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('键盘存在时完整 Material 延伸到屏幕底部，覆盖键盘顶角后方', (WidgetTester tester) async {
    _configure_view(tester, const Size(390, 844));
    await _open_composer(tester);
    await _set_keyboard_height(tester, 280);

    final Material surface = tester.widget<Material>(_composer);
    final Rect surface_rect = tester.getRect(_composer);
    expect(surface.color?.a, 1);
    expect(surface_rect.bottom, closeTo(844, 0.5));
    expect(surface_rect.left, closeTo(0, 0.5));
    expect(surface_rect.right, closeTo(390, 0.5));
    expect(surface_rect.top, lessThan(tester.getRect(_input).top));
    expect(tester.getRect(_send).bottom, lessThanOrEqualTo(844 - 280));
    expect(tester.takeException(), isNull);
  });

  testWidgets('平板键盘两侧圆角后方覆盖实体底色，编辑内容保持限宽', (tester) async {
    const Size view_size = Size(1024, 768);
    _configure_view(tester, view_size);
    // 同时覆盖顶部状态栏、左右挖孔避让和底部手势区域；底色仍需延伸到两侧。
    const FakeViewPadding safe_area = FakeViewPadding(
      top: 24,
      left: 44,
      right: 44,
      bottom: 20,
    );
    tester.view.viewPadding = safe_area;
    tester.view.padding = safe_area;
    addTearDown(tester.view.resetViewPadding);
    addTearDown(tester.view.resetPadding);
    await _open_composer(tester, is_dark: true);
    await _set_keyboard_height(tester, 300);

    final Rect surface_rect = tester.getRect(_composer);
    expect(surface_rect.left, 0);
    expect(surface_rect.right, view_size.width);
    expect(surface_rect.bottom, view_size.height);
    final Rect body_rect = tester.getRect(
      find.byType(ParagraphCommentComposerBody),
    );
    expect(body_rect.width, ParagraphCommentComposerStyle.max_width);
    expect(body_rect.center.dx, view_size.width / 2);

    final _ComposerGeometry initial_geometry = _read_geometry(tester);
    await tester.tap(_toggle);
    await tester.pump();
    for (final double height in <double>[200, 100, 0]) {
      await _set_keyboard_height(tester, height, settle: false);
      _expect_geometry(tester, initial_geometry, '平板键盘收起至 $height');
    }
    // 顶部安全区只能限制最大高度，不能在弹窗上方产生拦截遮罩点击的透明区域。
    await tester.tapAt(Offset(surface_rect.center.dx, surface_rect.top - 12));
    await tester.pumpAndSettle();
    expect(_composer, findsNothing);
    expect(tester.testTextInput.isVisible, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('完整弹窗图片行空白保留草稿和焦点，带图切表情保持位置', (tester) async {
    _configure_view(tester, const Size(390, 844));
    await _open_composer(tester);
    await _set_keyboard_height(tester, 280);

    // 使用真实弹窗的逻辑填入上传完成后的图片；网络重试由 logic_test 覆盖。
    final ParagraphCommentComposerLogic logic = tester
        .widget<ParagraphCommentComposerBody>(
          find.byType(ParagraphCommentComposerBody),
        )
        .logic;
    logic.images.add(
      ParagraphCommentImage(
        bytes: base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a3ioAAAAASUVORK5CYII=',
        ),
        filename: 'uploaded.png',
      )..url = 'https://example.test/uploaded.png',
    );
    logic.controller.text = '图片和文字都要保留';
    await tester.pumpAndSettle();
    final Rect strip_rect = tester.getRect(
      find.byKey(const ValueKey<String>('paragraph_comment_image_strip')),
    );
    await tester.tapAt(Offset(strip_rect.right - 8, strip_rect.center.dy));
    await tester.pump();
    expect(_composer, findsOneWidget);
    expect(logic.focus_node.hasFocus, isTrue);
    expect(logic.controller.text, '图片和文字都要保留');
    expect(logic.images, hasLength(1));

    final _ComposerGeometry initial_geometry = _read_geometry(tester);
    await tester.tap(_toggle);
    await tester.pump();
    for (final double height in <double>[210, 100, 0]) {
      await _set_keyboard_height(tester, height, settle: false);
      _expect_geometry(tester, initial_geometry, '带图键盘收起至 $height');
    }
    await tester.tapAt(Offset(strip_rect.right - 8, strip_rect.center.dy));
    await tester.pump();
    expect(_composer, findsOneWidget);
    expect(_emoji_panel, findsOneWidget);
    expect(logic.images, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    '键盘与表情双向动画每帧保持输入框、发送按钮和弹窗几何位置，支持重复切换',
    (WidgetTester tester) async {
      _configure_view(tester, const Size(390, 844));
      await _open_composer(tester);
      await tester.enterText(_input, '保留段评草稿 🌙');
      await _set_keyboard_height(tester, 280);
      final _ComposerGeometry initial_geometry = _read_geometry(tester);

      // 连续两轮覆盖已缓存键盘高度之后的后续切换，防止首轮通过但再次跳动。
      for (int cycle = 0; cycle < 2; cycle++) {
        await tester.tap(_toggle);
        await tester.pump();
        // OS 键盘仍处于 280px 高度时，表情应已布局到其后方。
        expect(_emoji_panel, findsOneWidget);
        _expect_geometry(tester, initial_geometry, '第 $cycle 轮，点击表情');

        for (final double height in <double>[210, 100, 0]) {
          await _set_keyboard_height(tester, height, settle: false);
          _expect_geometry(
            tester,
            initial_geometry,
            '第 $cycle 轮，键盘收起至 $height',
          );
          expect(_emoji_panel, findsOneWidget);
        }
        await tester.pumpAndSettle();
        _expect_geometry(tester, initial_geometry, '第 $cycle 轮，表情已展开');

        await tester.tap(_toggle);
        await tester.pump();
        expect(tester.widget<TextField>(_input).focusNode!.hasFocus, isTrue);
        _expect_geometry(tester, initial_geometry, '第 $cycle 轮，点击键盘');

        for (final double height in <double>[100, 210, 280]) {
          await _set_keyboard_height(tester, height, settle: false);
          _expect_geometry(
            tester,
            initial_geometry,
            '第 $cycle 轮，键盘展开至 $height',
          );
        }
        await tester.pumpAndSettle();
        _expect_geometry(tester, initial_geometry, '第 $cycle 轮，键盘已展开');
        expect(tester.widget<TextField>(_input).controller!.text, '保留段评草稿 🌙');
      }
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant(<TargetPlatform>{
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );

  testWidgets('小屏横屏在键盘与表情动画各阶段不会布局溢出', (WidgetTester tester) async {
    _configure_view(tester, const Size(568, 320));
    await _open_composer(tester, is_dark: true);
    await _set_keyboard_height(tester, 160);
    _expect_surface_in_view(tester, const Size(568, 320));

    // 横屏内容允许滚动；先将工具栏滚入视口，再模拟真实用户切换。
    await tester.ensureVisible(_toggle);
    await tester.pumpAndSettle();
    await tester.tap(_toggle);
    await tester.pump();
    expect(_emoji_panel, findsOneWidget);
    for (final double height in <double>[120, 60, 0]) {
      await _set_keyboard_height(tester, height, settle: false);
      _expect_surface_in_view(tester, const Size(568, 320));
    }
    await tester.pumpAndSettle();
    await tester.ensureVisible(_toggle);
    await tester.pumpAndSettle();
    await tester.tap(_toggle);
    await tester.pump();
    for (final double height in <double>[60, 120, 160]) {
      await _set_keyboard_height(tester, height, settle: false);
      _expect_surface_in_view(tester, const Size(568, 320));
    }
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(_input).focusNode!.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });
}

/// 测试设备使用逻辑像素，确保 FakeViewPadding 与组件实际读取高度一致。
void _configure_view(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
}

Future<void> _open_composer(WidgetTester tester, {bool is_dark = false}) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const <Locale>[Locale('zh')],
      path: 'assets/i18n',
      assetLoader: const _KeyboardTransitionAssetLoader(),
      startLocale: const Locale('zh'),
      fallbackLocale: const Locale('zh'),
      child: Builder(
        builder: (BuildContext context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) => TextButton(
                onPressed: () => show_paragraph_comment_composer(
                  context,
                  quote: '月光落在窗台上，她再次打开那封信。\n远处灯火亮起，故事仍在继续。',
                  is_dark: is_dark,
                  on_send: (_, _) async => false,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// 不自动跳过动画中间帧，避免仅测收起/展开终点时漏掉闪跳。
Future<void> _set_keyboard_height(
  WidgetTester tester,
  double height, {
  bool settle = true,
}) async {
  tester.view.viewInsets = FakeViewPadding(bottom: height);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

_ComposerGeometry _read_geometry(WidgetTester tester) => _ComposerGeometry(
  surface: tester.getRect(_composer),
  input: tester.getRect(_input),
  send: tester.getRect(_send),
);

void _expect_geometry(
  WidgetTester tester,
  _ComposerGeometry expected,
  String phase,
) {
  final _ComposerGeometry actual = _read_geometry(tester);
  expect(actual.surface.top, closeTo(expected.surface.top, 0.5), reason: phase);
  expect(
    actual.surface.height,
    closeTo(expected.surface.height, 0.5),
    reason: phase,
  );
  expect(
    actual.surface.bottom,
    closeTo(expected.surface.bottom, 0.5),
    reason: phase,
  );
  expect(actual.input.top, closeTo(expected.input.top, 0.5), reason: phase);
  expect(
    actual.input.bottom,
    closeTo(expected.input.bottom, 0.5),
    reason: phase,
  );
  expect(actual.send.top, closeTo(expected.send.top, 0.5), reason: phase);
  expect(actual.send.bottom, closeTo(expected.send.bottom, 0.5), reason: phase);
  expect(tester.takeException(), isNull, reason: phase);
}

void _expect_surface_in_view(WidgetTester tester, Size view_size) {
  final Rect surface = tester.getRect(_composer);
  expect(surface.top, greaterThanOrEqualTo(0));
  expect(surface.bottom, closeTo(view_size.height, 0.5));
  expect(surface.left, greaterThanOrEqualTo(0));
  expect(surface.right, lessThanOrEqualTo(view_size.width));
  expect(tester.takeException(), isNull);
}

class _ComposerGeometry {
  const _ComposerGeometry({
    required this.surface,
    required this.input,
    required this.send,
  });

  final Rect surface;
  final Rect input;
  final Rect send;
}

class _KeyboardTransitionAssetLoader extends AssetLoader {
  const _KeyboardTransitionAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      <String, dynamic>{
        'paragraph_comment': <String, dynamic>{
          'quote': '选择的文字',
          'input_hint': '说说你的想法',
          'send': '发送',
          'add_image': '选择图片',
          'remove_image': '删除图片',
          'emoji': '表情',
          'keyboard': '键盘',
          'send_failed': '发送失败，请重试',
        },
      };
}
