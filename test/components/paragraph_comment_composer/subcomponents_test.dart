// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:ui' show PointerDeviceKind;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/components/paragraph_comment_composer/logic.dart';
import 'package:app/components/paragraph_comment_composer/style.dart';
import 'package:app/components/paragraph_comment_composer/widgets/composer_actions.dart';
import 'package:app/components/paragraph_comment_composer/widgets/composer_input.dart';
import 'package:app/components/paragraph_comment_composer/widgets/image_strip.dart';
import 'package:app/components/paragraph_comment_composer/widgets/quote_preview.dart';

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

  testWidgets('发送贴右、输入区底色，图片及整行空白保留焦点且不关闭弹窗', (WidgetTester tester) async {
    int close_count = 0;
    final ParagraphCommentComposerLogic logic = ParagraphCommentComposerLogic(
      on_send: (_, _) async => false,
      on_close: () => close_count += 1,
    );
    addTearDown(logic.dispose);
    logic.controller.text = '段评';
    logic.images.add(
      ParagraphCommentImage(
        bytes: base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a3ioAAAAASUVORK5CYII=',
        ),
        filename: 'preview.png',
      )..url = 'https://example.test/preview.png',
    );
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const <Locale>[Locale('zh')],
        path: 'assets/i18n',
        assetLoader: const _SubcomponentAssetLoader(),
        startLocale: const Locale('zh'),
        child: Builder(
          builder: (BuildContext context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: Scaffold(
              body: Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: logic.close,
                  child: SizedBox(
                    width: 284,
                    child: ListenableBuilder(
                      listenable: logic,
                      builder: (_, _) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const ParagraphQuotePreview(
                            quote: '被引用的原文',
                            is_dark: false,
                          ),
                          ParagraphCommentComposerInput(
                            logic: logic,
                            is_dark: false,
                          ),
                          ParagraphCommentImageStrip(
                            logic: logic,
                            is_dark: false,
                          ),
                          ParagraphCommentComposerActions(
                            key: const ValueKey<String>('actions'),
                            logic: logic,
                            is_dark: false,
                          ),
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
    );
    await tester.pumpAndSettle();
    logic.focus_node.requestFocus();
    await tester.pump();
    final TextField input = tester.widget<TextField>(
      find.byKey(const ValueKey<String>('paragraph_comment_input')),
    );
    expect(input.decoration!.filled, isTrue);
    expect(
      input.decoration!.fillColor,
      ParagraphCommentComposerStyle.quote_background(false),
    );
    final Container quote = tester.widget<Container>(
      find.byKey(const ValueKey<String>('paragraph_comment_quote')),
    );
    final BoxDecoration quote_decoration = quote.decoration! as BoxDecoration;
    expect(quote_decoration.color, isNull);
    expect(quote_decoration.borderRadius, isNull);
    expect(
      tester
          .getRect(find.byKey(const ValueKey<String>('paragraph_comment_send')))
          .right,
      tester.getRect(find.byKey(const ValueKey<String>('actions'))).right,
    );
    final Rect strip_rect = tester.getRect(
      find.byKey(const ValueKey<String>('paragraph_comment_image_strip')),
    );
    // 鼠标触发外部点击的失焦规则更严格，覆盖网页及桌面的图片区域。
    await tester.tapAt(
      Offset(strip_rect.right - 8, strip_rect.center.dy),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    expect(close_count, 0);
    expect(logic.focus_node.hasFocus, isTrue);
    await tester.tapAt(
      Offset(strip_rect.left + 20, strip_rect.center.dy),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    expect(close_count, 0);
    expect(logic.focus_node.hasFocus, isTrue);
    await tester.tap(find.byTooltip('移除图片'));
    await tester.pump();
    expect(logic.images, isEmpty);
    expect(close_count, 0);
    expect(logic.focus_node.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });
}

class _SubcomponentAssetLoader extends AssetLoader {
  const _SubcomponentAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      <String, dynamic>{
        'paragraph_comment': <String, dynamic>{
          'quote': '引用原文',
          'input_hint': '写下段评',
          'send': '发送',
          'add_image': '添加图片',
          'emoji': '表情',
          'keyboard': '键盘',
          'remove_image': '移除图片',
        },
      };
}
