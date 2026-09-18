// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/components/paragraph_comment_composer/index.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    const MethodChannel preferences = MethodChannel(
      'plugins.flutter.io/shared_preferences',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(preferences, (MethodCall call) async {
          if (call.method == 'getAll') return <String, Object>{};
          return true;
        });
    await EasyLocalization.ensureInitialized();
  });

  Future<void> open_composer(
    WidgetTester tester, {
    bool is_dark = false,
    Locale locale = const Locale('zh'),
    required Future<bool> Function(String, List<String>) on_send,
  }) async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: <Locale>[locale],
        path: 'assets/i18n',
        assetLoader: const _ComposerAssetLoader(),
        startLocale: locale,
        fallbackLocale: locale,
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
                    quote: '第一行\n第二行\n第三行\n第四行\n第五行',
                    is_dark: is_dark,
                    on_send: on_send,
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

  testWidgets('自动聚焦、引用三行，失败保留草稿而成功关闭', (tester) async {
    int calls = 0;
    await open_composer(tester, on_send: (_, _) async => ++calls > 1);
    final Finder input = find.byKey(
      const ValueKey<String>('paragraph_comment_input'),
    );
    TextField field = tester.widget<TextField>(input);
    expect(field.focusNode!.hasFocus, isTrue);
    final Text quote = tester.widget<Text>(
      find.text('第一行\n第二行\n第三行\n第四行\n第五行'),
    );
    expect(quote.maxLines, 3);
    expect(quote.overflow, TextOverflow.ellipsis);
    await tester.enterText(input, '我的段评');
    await tester.pump();
    final Finder send = find.byKey(
      const ValueKey<String>('paragraph_comment_send'),
    );
    await tester.tap(send);
    await tester.pumpAndSettle();
    field = tester.widget<TextField>(input);
    expect(field.controller!.text, '我的段评');
    expect(field.focusNode!.hasFocus, isTrue);
    await tester.tap(send);
    await tester.pumpAndSettle();
    expect(input, findsNothing);
    expect(tester.testTextInput.isVisible, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('小屏夜间英文键盘与表情切换不关闭，空白区域关闭键盘弹窗', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await open_composer(
      tester,
      is_dark: true,
      locale: const Locale('en'),
      on_send: (_, _) async => false,
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    final Finder toggle = find.byKey(
      const ValueKey<String>('paragraph_comment_toggle_emoji'),
    );
    await tester.tap(toggle);
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('comment_emoji_panel')),
      findsOneWidget,
    );
    await tester.tap(find.text('😀'));
    await tester.pump();
    final Finder input = find.byKey(
      const ValueKey<String>('paragraph_comment_input'),
    );
    expect(tester.widget<TextField>(input).controller!.text, '😀');
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(input).focusNode!.hasFocus, isTrue);
    // 引用仅展示所选文字，属于非交互空白，按要求关闭弹窗。
    await tester.tap(
      find.byKey(const ValueKey<String>('paragraph_comment_quote')),
    );
    await tester.pumpAndSettle();
    expect(input, findsNothing);
    expect(tester.testTextInput.isVisible, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('点击遮罩关闭弹窗和键盘', (tester) async {
    await open_composer(tester, on_send: (_, _) async => true);
    await tester.tapAt(const Offset(400, 40));
    await tester.pumpAndSettle();
    expect(find.byType(ParagraphCommentComposer), findsNothing);
    expect(tester.testTextInput.isVisible, isFalse);
    expect(tester.takeException(), isNull);
  });
}

class _ComposerAssetLoader extends AssetLoader {
  const _ComposerAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      <String, dynamic>{
        'paragraph_comment': <String, dynamic>{
          'quote': 'Selected passage',
          'input_hint': 'Share your thoughts',
          'send': 'Send',
          'add_image': 'Add photos',
          'remove_image': 'Remove photo',
          'emoji': 'Emoji',
          'keyboard': 'Keyboard',
          'send_failed': 'Could not send. Please try again.',
        },
      };
}
