// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/work_editor/_shared/style.dart';
import 'package:app/pages/work_editor/_shared/widgets/editor_keyboard_layout.dart';
import 'package:app/pages/work_editor/_shared/widgets/steps/step_content/widgets/short_content_editor.dart';
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
          (call) async => call.method == 'getAll' ? <String, Object>{} : true,
        );
    await EasyLocalization.ensureInitialized();
  });

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    for (final is_dark in [false, true]) {
      testWidgets(
        '$platform / ${is_dark ? '夜间' : '日间'}：短篇先收起导航再弹键盘，恢复时保留正文',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(390, 844);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetViewInsets);
          final content = TextEditingController(text: '尚未完成的短篇正文');
          addTearDown(content.dispose);
          var content_changes = 0;
          await tester.pumpWidget(
            EasyLocalization(
              supportedLocales: const [Locale('zh')],
              startLocale: const Locale('zh'),
              path: 'assets/i18n',
              assetLoader: const _ShortEditorAssetLoader(),
              child: Builder(
                builder: (context) => MaterialApp(
                  locale: context.locale,
                  supportedLocales: context.supportedLocales,
                  localizationsDelegates: context.localizationDelegates,
                  theme: ThemeData(
                    brightness: is_dark ? Brightness.dark : Brightness.light,
                  ),
                  home: Scaffold(
                    resizeToAvoidBottomInset: false,
                    body: EditorKeyboardLayout(
                      header: const SizedBox(height: 100, child: Text('步骤')),
                      footer: const SizedBox(
                        height: 80,
                        child: Text('上一步 / 下一步'),
                      ),
                      content: SingleChildScrollView(
                        child: ShortContentEditor(
                          is_dark: is_dark,
                          content_controller: content,
                          word_count: content.text.length,
                          on_content_changed: () => content_changes++,
                          on_file_upload: () {},
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final input = find.byKey(const ValueKey('short_content_input'));
          final editable = find.descendant(
            of: input,
            matching: find.byType(EditableText),
          );
          final original_state = tester.state<EditableTextState>(editable);
          final half_animation = Duration(
            microseconds:
                WorkEditorStyle.keyboard_chrome_duration.inMicroseconds ~/ 2,
          );

          // 检查真实短篇组件的首次点击及系统收起后再次点击的输入时序。
          Future<void> verify_keyboard_opening() async {
            tester.testTextInput.log.clear();
            await tester.tap(input);
            await tester.pump();
            await tester.pump(half_animation);
            expect(_header_height(tester), greaterThan(0));
            expect(_footer_height(tester), greaterThan(0));
            expect(tester.testTextInput.isVisible, isFalse);
            expect(
              tester.testTextInput.log.where(
                (call) => call.method == 'TextInput.show',
              ),
              isEmpty,
              reason: '正文不可在步骤条及按钮完全收起之前打开键盘',
            );
            for (var frame = 0; frame < 20; frame++) {
              await tester.pump(const Duration(milliseconds: 16));
              if (tester.testTextInput.isVisible) {
                expect(_header_height(tester), 0);
                expect(_footer_height(tester), 0);
                break;
              }
            }
            expect(tester.testTextInput.isVisible, isTrue);
            expect(tester.state<EditableTextState>(editable), original_state);
          }

          await verify_keyboard_opening();
          const edited_content = '尚未完成的短篇正文\n第二段继续写作，收放键盘也要保留。';
          await tester.enterText(input, edited_content);
          expect(content_changes, 1);
          tester.view.viewInsets = const FakeViewPadding(bottom: 300);
          await tester.pumpAndSettle();

          // Android 返回键等操作可以仅隐藏键盘而保留正文焦点。
          tester.testTextInput.hide();
          tester.view.viewInsets = const FakeViewPadding();
          await tester.pumpAndSettle();
          expect(original_state.widget.focusNode.hasFocus, isTrue);
          expect(_header_height(tester), 100);
          expect(_footer_height(tester), 80);
          await verify_keyboard_opening();

          // 主动失焦后，键盘还占据原高度时导航已经同步展开。
          tester.view.viewInsets = const FakeViewPadding(bottom: 300);
          await tester.pumpAndSettle();
          original_state.widget.focusNode.unfocus();
          await tester.pump();
          await tester.pump();
          await tester.pump(half_animation);
          expect(tester.view.viewInsets.bottom, 300);
          expect(_header_height(tester), inExclusiveRange(0, 100));
          expect(_footer_height(tester), inExclusiveRange(0, 80));
          tester.view.viewInsets = const FakeViewPadding();
          await tester.pumpAndSettle();
          expect(_header_height(tester), 100);
          expect(_footer_height(tester), 80);
          expect(content.text, edited_content);
          expect(content_changes, 1);
          expect(tester.state<EditableTextState>(editable), original_state);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
        variant: TargetPlatformVariant.only(platform),
      );
    }
  }
}

double _header_height(WidgetTester tester) =>
    tester.getSize(find.byType(SizeTransition).first).height;

double _footer_height(WidgetTester tester) =>
    tester.getSize(find.byType(SizeTransition).last).height;

class _ShortEditorAssetLoader extends AssetLoader {
  const _ShortEditorAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {
    'creator_center': {
      'short_content_label': '短篇正文',
      'short_content_hint': '开始写下你的故事',
      'upload_file': '导入文件',
    },
    'read': {'chapter_word_count_suffix': '字'},
  };
}
