import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/components/comment_list/models/comment_data.dart';
import 'package:app/components/comment_list/style.dart';
import 'package:app/components/comment_list/widgets/comment_input.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    const MethodChannel preferences_channel = MethodChannel(
      'plugins.flutter.io/shared_preferences',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(preferences_channel, (
          MethodCall method_call,
        ) async {
          if (method_call.method == 'getAll') {
            return <String, Object>{};
          }
          return true;
        });
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('父级重建、键盘下降和再次唤起均保持稳定', (WidgetTester tester) async {
    addTearDown(tester.view.resetViewInsets);
    StateSetter? rebuild_parent;
    CommentData? reply_target;

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const <Locale>[Locale('zh')],
        path: 'assets/i18n',
        assetLoader: const _CommentTestAssetLoader(),
        startLocale: const Locale('zh'),
        fallbackLocale: const Locale('zh'),
        child: MaterialApp(
          home: StatefulBuilder(
            builder: (BuildContext context, StateSetter set_state) {
              rebuild_parent = set_state;
              return Material(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: CommentInput(
                    is_dark: false,
                    reply_target: reply_target,
                    on_cancel_reply: () {
                      rebuild_parent?.call(() {
                        reply_target = null;
                      });
                    },
                    on_send: (_) async => true,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    rebuild_parent?.call(() {
      reply_target = const CommentData(
        id: 1,
        user_id: 1,
        avatar: '',
        nickname: '测试用户',
        content: '评论',
        time: '',
      );
    });
    await tester.pump();
    expect(tester.takeException(), isNull);

    final Finder preview = find.byKey(
      const ValueKey<String>('comment_input_preview'),
    );
    final double initial_preview_y = tester.getTopLeft(preview).dy;

    await tester.tap(preview);
    await tester.pump();

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump();
    expect(
      tester.getTopLeft(preview).dy,
      moreOrLessEquals(initial_preview_y, epsilon: 0.01),
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(reply_target, isNull);
    expect(find.byType(TextField), findsOneWidget);
    expect(
      tester.getTopLeft(preview).dy,
      moreOrLessEquals(initial_preview_y, epsilon: 0.01),
    );

    // 真机上用户可能在上一轮键盘动画还剩最后一个关闭帧时再次点击。这里模拟
    // 键盘已降到 40，点击后迟到的 0 高度事件才到达；它不能关闭新的编辑会话。
    tester.view.viewInsets = const FakeViewPadding(bottom: 40);
    await tester.pump();
    await tester.tap(preview);
    await tester.pump();
    TextField editor = tester.widget<TextField>(find.byType(TextField));
    expect(editor.focusNode?.hasFocus, isTrue);

    tester.view.resetViewInsets();
    await tester.pump();
    editor = tester.widget<TextField>(find.byType(TextField));
    expect(editor.focusNode?.hasFocus, isTrue);

    // 新一轮键盘开始上升并到达完整高度后，焦点仍应保持。
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump();

    editor = tester.widget<TextField>(find.byType(TextField));
    expect(editor.focusNode?.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('发送失败保留草稿，成功后才清空输入', (WidgetTester tester) async {
    int send_count = 0;

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const <Locale>[Locale('zh')],
        path: 'assets/i18n',
        assetLoader: const _CommentTestAssetLoader(),
        startLocale: const Locale('zh'),
        fallbackLocale: const Locale('zh'),
        child: MaterialApp(
          home: Material(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: CommentInput(
                is_dark: false,
                on_send: (String content) async {
                  send_count += 1;
                  expect(content, '保留这段草稿');
                  return send_count > 1;
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('comment_input_preview')),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), '保留这段草稿');
    await tester.pump();

    final Finder send_button = find.byKey(
      const ValueKey<String>('comment_send_button_editor'),
    );
    await tester.tap(send_button);
    await tester.pumpAndSettle();
    TextField editor = tester.widget<TextField>(find.byType(TextField));
    expect(editor.controller?.text, '保留这段草稿');

    await tester.tap(send_button);
    await tester.pumpAndSettle();
    editor = tester.widget<TextField>(find.byType(TextField));
    expect(editor.controller?.text, isEmpty);
    expect(send_count, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('夜间表情面板与弹窗同色且可流畅切回键盘', (WidgetTester tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const <Locale>[Locale('zh')],
        path: 'assets/i18n',
        assetLoader: const _CommentTestAssetLoader(),
        startLocale: const Locale('zh'),
        fallbackLocale: const Locale('zh'),
        child: MaterialApp(
          home: Material(
            color: CommentListStyle.sheet_dark_bg,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: CommentInput(is_dark: true, on_send: (_) async => true),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('comment_emoji_button_preview')),
    );
    await tester.pumpAndSettle();

    final Finder emoji_panel = find.byKey(
      const ValueKey<String>('comment_emoji_panel'),
    );
    expect(emoji_panel, findsOneWidget);
    final Material emoji_panel_material = tester.widget<Material>(emoji_panel);
    expect(emoji_panel_material.color, CommentListStyle.sheet_dark_bg);

    final IgnorePointer fixed_composer_gate = tester.widget<IgnorePointer>(
      find.byKey(const ValueKey<String>('comment_fixed_composer_gate')),
    );
    expect(fixed_composer_gate.ignoring, isTrue);

    await tester.tap(
      find.byKey(const ValueKey<String>('comment_emoji_button_editor')),
    );
    await tester.pumpAndSettle();

    expect(emoji_panel, findsNothing);
    final TextField editor = tester.widget<TextField>(find.byType(TextField));
    expect(editor.focusNode?.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });
}

class _CommentTestAssetLoader extends AssetLoader {
  const _CommentTestAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    return <String, dynamic>{
      'comment': <String, dynamic>{
        'input_hint': '说点什么…',
        'reply_to': '回复',
        'send': '发送',
      },
    };
  }
}
