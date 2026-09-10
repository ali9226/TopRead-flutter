// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/work_editor/_shared/widgets/editor_keyboard_layout.dart';
import 'package:app/pages/work_editor/_shared/widgets/editor_keyboard_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<FocusNode> mount_editor(
    WidgetTester tester, {
    bool collapse_when_editing = true,
    bool disable_animations = false,
    VoidCallback? on_content_build,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    final focus = FocusNode();
    addTearDown(() {
      focus.dispose();
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
      tester.view.resetViewInsets();
    });
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: disable_animations),
          child: child!,
        ),
        home: Scaffold(
          resizeToAvoidBottomInset: false,
          body: EditorKeyboardLayout(
            collapse_when_editing: collapse_when_editing,
            header: const SizedBox(height: 100, child: Text('步骤')),
            footer: const SizedBox(height: 80, child: Text('上一步 / 下一步')),
            content: Builder(
              builder: (context) {
                on_content_build?.call();
                return SingleChildScrollView(
                  child: EditorKeyboardInput(
                    builder: (read_only, on_tap) => TextField(
                      focusNode: focus,
                      maxLines: null,
                      readOnly: read_only,
                      onTap: on_tap,
                      onTapAlwaysCalled: true,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    return focus;
  }

  double header_height(WidgetTester tester) =>
      tester.getSize(find.byType(SizeTransition).first).height;

  double footer_height(WidgetTester tester) =>
      tester.getSize(find.byType(SizeTransition).last).height;

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets(
      '$platform：首次及保留焦点重开，工具栏归零前不得调用 TextInput.show',
      (tester) async {
        final focus = await mount_editor(tester);
        Future<void> verify_open_sequence() async {
          tester.testTextInput.log.clear();
          await tester.tap(find.byType(TextField));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 110));
          expect(header_height(tester), greaterThan(0));
          expect(tester.testTextInput.isVisible, isFalse);
          expect(
            tester.testTextInput.log.where(
              (call) => call.method == 'TextInput.show',
            ),
            isEmpty,
          );
          for (var frame = 0; frame < 20; frame++) {
            await tester.pump(const Duration(milliseconds: 16));
            if (tester.testTextInput.isVisible) {
              expect(header_height(tester), 0);
              expect(footer_height(tester), 0);
              break;
            }
          }
          expect(tester.testTextInput.isVisible, isTrue);
        }

        await verify_open_sequence();
        await tester.enterText(find.byType(TextField), '正文不会因收放键盘丢失');
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        tester.testTextInput.hide();
        tester.view.viewInsets = const FakeViewPadding();
        await tester.pumpAndSettle();
        expect(focus.hasFocus, isTrue);
        await verify_open_sequence();
        expect(find.text('正文不会因收放键盘丢失'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant.only(platform),
    );

    testWidgets(
      '$platform：收起动画中取消编辑或退出，不得延迟弹出键盘',
      (tester) async {
        final focus = await mount_editor(tester);
        await tester.tap(find.byType(TextField));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        focus.unfocus();
        await tester.pumpAndSettle();
        expect(tester.testTextInput.isVisible, isFalse);
        expect(header_height(tester), 100);
        await tester.tap(find.byType(TextField));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        expect(tester.testTextInput.isVisible, isFalse);
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant.only(platform),
    );
  }

  testWidgets('焦点提前收缩；键盘仍显示时，失焦立即开始恢复工具栏', (tester) async {
    final focus = await mount_editor(tester);
    focus.requestFocus();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 110));
    expect(header_height(tester), inExclusiveRange(0, 100));
    expect(footer_height(tester), inExclusiveRange(0, 80));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(header_height(tester), 0);
    focus.unfocus();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 110));
    expect(tester.view.viewInsets.bottom, 300);
    expect(header_height(tester), inExclusiveRange(0, 100));
    expect(footer_height(tester), inExclusiveRange(0, 80));
    tester.view.viewInsets = const FakeViewPadding();
    await tester.pumpAndSettle();
    expect(header_height(tester), 100);
    expect(tester.takeException(), isNull);
  });

  testWidgets('系统收起但保留焦点时，首个下降帧恢复；重新弹出可反向过渡', (tester) async {
    final focus = await mount_editor(tester);
    focus.requestFocus();
    await tester.pump();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(focus.hasFocus, isTrue);
    expect(footer_height(tester), greaterThan(0));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(footer_height(tester), 0);
    tester.view.viewInsets = const FakeViewPadding();
    await tester.pumpAndSettle();
    expect(footer_height(tester), 80);
    expect(tester.takeException(), isNull);
  });

  testWidgets('键盘逐帧更新不重新构建正文；动画中退出安全', (tester) async {
    var builds = 0;
    final focus = await mount_editor(tester, on_content_build: () => builds++);
    focus.requestFocus();
    await tester.pumpAndSettle();
    final initial_builds = builds;
    for (final inset in [50.0, 100.0, 150.0, 200.0, 250.0, 300.0]) {
      tester.view.viewInsets = FakeViewPadding(bottom: inset);
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(builds, initial_builds);
    focus.unfocus();
    await tester.pump();
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.viewInsets = const FakeViewPadding();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('从其他步骤切入长篇正文，重新启用先收起再输入的约束', (tester) async {
    await mount_editor(tester, collapse_when_editing: false);
    await mount_editor(tester);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 110));
    expect(tester.testTextInput.isVisible, isFalse);
    expect(header_height(tester), greaterThan(0));
    await tester.pumpAndSettle();
    expect(header_height(tester), 0);
    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('其他步骤保留导航；减少动态效果设置受尊重', (tester) async {
    final focus = await mount_editor(tester, collapse_when_editing: false);
    focus.requestFocus();
    await tester.pump();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(header_height(tester), 100);
    expect(footer_height(tester), 80);
    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.viewInsets = const FakeViewPadding();
    final reduced_focus = await mount_editor(tester, disable_animations: true);
    reduced_focus.requestFocus();
    await tester.pump();
    await tester.pump();
    expect(footer_height(tester), 0);
    reduced_focus.unfocus();
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(footer_height(tester), 80);
    expect(tester.takeException(), isNull);
  });
}
