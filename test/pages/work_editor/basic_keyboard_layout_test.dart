// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:convert';
import 'dart:math' as math;

import 'package:app/pages/author_center/models/creator_work.dart';
import 'package:app/pages/work_editor/index.dart';
import 'package:app/pages/work_editor/_shared/style.dart';
import 'package:app/pages/work_editor/_shared/widgets/editor_step_indicator.dart';
import 'package:app/pages/work_editor/_shared/widgets/steps/step_basic/step_basic.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/language_store.dart';
import 'package:app/stores/preference_store.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// 模拟带底部安全区的手机，捕获按钮上移及重复键盘留白。
const _screen_size = Size(390, 844);
const _safe_bottom = 34.0;
const _frame_duration = Duration(milliseconds: 16);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, dynamic> translations;

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (call) async => call.method == 'getAll' ? <String, Object>{} : true,
        );
    await EasyLocalization.ensureInitialized();
    translations =
        jsonDecode(await rootBundle.loadString('assets/i18n/zh.json'))
            as Map<String, dynamic>;
  });

  for (final type in [CreatorWorkType.long, CreatorWorkType.short]) {
    testWidgets('管理页编辑 ${type.name}：只展示对应步骤，审核由管理页提交', (tester) async {
      addTearDown(Get.reset);
      Get.put<DeviceInfo>(_TestDeviceInfo());
      Get.put<LanguageStore>(_TestLanguageStore());
      Get.put<PreferenceStore>(PreferenceStore());
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('zh')],
          startLocale: const Locale('zh'),
          path: 'assets/i18n',
          assetLoader: _EditorAssetLoader(translations),
          child: Builder(
            builder: (context) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: CreatorWorkEditorPage(
                metadataOnly: type == CreatorWorkType.long,
                saveOnly: true,
                initial_work: CreatorWorkDraft(
                  local_id: 'manage_test',
                  title: '作品',
                  introduction: '',
                  work_type: type,
                  is_completed: false,
                  language_code: 'zh',
                  language_id: 1,
                  category_ids: const [],
                  short_content: '原文',
                  chapters: const [],
                  status: CreatorWorkStatus.draft,
                  release_mode: CreatorReleaseMode.immediate,
                  scheduled_publish_time: null,
                  update_time: DateTime(2026),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final steps = tester.widget<EditorStepIndicator>(
        find.byType(EditorStepIndicator),
      );
      expect(steps.labels.length, type == CreatorWorkType.long ? 2 : 3);
      steps.on_step_tap!(steps.labels.length - 1);
      await tester.pumpAndSettle();
      expect(find.text('保存并返回'), findsOneWidget);
      expect(find.byKey(const ValueKey('step_publish')), findsNothing);
      if (type == CreatorWorkType.long)
        expect(find.byKey(const ValueKey('step_content')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    for (final is_dark in [false, true]) {
      testWidgets(
        '$platform / ${is_dark ? '夜间' : '日间'}：标题和简介键盘不顶起底栏，也不留下按钮高度空白',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = _screen_size;
          tester.view.viewPadding = const FakeViewPadding(bottom: _safe_bottom);
          tester.view.padding = const FakeViewPadding(bottom: _safe_bottom);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetViewPadding);
          addTearDown(tester.view.resetPadding);
          addTearDown(tester.view.resetViewInsets);
          addTearDown(Get.reset);

          Get.put<DeviceInfo>(_TestDeviceInfo()..dark.value = is_dark);
          Get.put<LanguageStore>(_TestLanguageStore());
          Get.put<PreferenceStore>(PreferenceStore());
          await tester.pumpWidget(
            EasyLocalization(
              supportedLocales: const [Locale('zh')],
              startLocale: const Locale('zh'),
              path: 'assets/i18n',
              assetLoader: _EditorAssetLoader(translations),
              child: Builder(
                builder: (context) => MaterialApp(
                  locale: context.locale,
                  supportedLocales: context.supportedLocales,
                  localizationsDelegates: context.localizationDelegates,
                  theme: ThemeData(
                    brightness: is_dark ? Brightness.dark : Brightness.light,
                  ),
                  home: CreatorWorkEditorPage(
                    initial_work: CreatorWorkDraft(
                      local_id: 'keyboard_layout_draft',
                      title: '原始标题',
                      introduction: '原始简介',
                      work_type: CreatorWorkType.short,
                      is_completed: false,
                      language_code: 'zh',
                      category_ids: const [],
                      short_content: '',
                      chapters: const [],
                      status: CreatorWorkStatus.draft,
                      release_mode: CreatorReleaseMode.immediate,
                      scheduled_publish_time: null,
                      update_time: DateTime(2026, 9, 9),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
          final bottom_bar = find.byWidget(scaffold.bottomNavigationBar!);
          final bottom_bar_rect = tester.getRect(bottom_bar);
          final save_button = find.descendant(
            of: bottom_bar,
            matching: find.byType(OutlinedButton),
          );
          final next_button = find.descendant(
            of: bottom_bar,
            matching: find.byWidgetPredicate(
              (widget) => widget is FilledButton,
            ),
          );
          final save_rect = tester.getRect(save_button);
          final next_rect = tester.getRect(next_button);
          expect(bottom_bar_rect.bottom, _screen_size.height);
          expect(
            tester.getRect(find.byType(PageView)).bottom,
            bottom_bar_rect.top,
          );

          final fields = find.descendant(
            of: find.byType(StepBasic),
            matching: find.byType(TextField),
          );
          final initial_states = <EditableTextState>[
            for (var index = 0; index < 2; index++)
              tester.state<EditableTextState>(
                find.descendant(
                  of: fields.at(index),
                  matching: find.byType(EditableText),
                ),
              ),
          ];

          for (var field_index = 0; field_index < 2; field_index++) {
            final field = fields.at(field_index);
            final initial_state = initial_states[field_index];
            final edited_text = field_index == 0
                ? '标题在键盘收放后依旧保留'
                : '简介第一段。\n简介第二段也要保留。';
            await tester.ensureVisible(field);
            await tester.pumpAndSettle();
            await tester.tap(field);
            await tester.enterText(field, edited_text);
            await tester.pump();
            expect(tester.testTextInput.isVisible, isTrue);

            // 包含首次弹出、候选栏增高、键盘高度回落和完全收起。
            for (final inset in <double>[
              24,
              80,
              160,
              240,
              320,
              380,
              300,
              160,
              80,
              24,
              0,
            ]) {
              tester.view.viewInsets = FakeViewPadding(bottom: inset);
              tester.view.padding = FakeViewPadding(
                bottom: math.max(0, _safe_bottom - inset),
              );
              await tester.pump(_frame_duration);

              // 内容只避让键盘与底栏中较高的一者，不重复扣除按钮高度。
              final content_bottom = math.min(
                _screen_size.height - inset,
                bottom_bar_rect.top,
              );
              expect(
                tester.getRect(find.byType(PageView)).bottom,
                closeTo(content_bottom, 0.01),
                reason: '键盘高度 $inset 时，表单底部不可残留按钮高度的空白',
              );
              final current_bar = find.byWidget(
                tester
                    .widget<Scaffold>(find.byType(Scaffold))
                    .bottomNavigationBar!,
              );
              expect(tester.getRect(current_bar), bottom_bar_rect);
              expect(
                tester.getRect(
                  find.descendant(
                    of: current_bar,
                    matching: find.byType(OutlinedButton),
                  ),
                ),
                save_rect,
              );
              expect(
                tester.getRect(
                  find.descendant(
                    of: current_bar,
                    matching: find.byWidgetPredicate(
                      (widget) => widget is FilledButton,
                    ),
                  ),
                ),
                next_rect,
              );
              expect(initial_state.widget.controller.text, edited_text);
              expect(initial_state.widget.focusNode.hasFocus, isTrue);
              for (var index = 0; index < 2; index++) {
                expect(
                  tester.state<EditableTextState>(
                    find.descendant(
                      of: fields.at(index),
                      matching: find.byType(EditableText),
                    ),
                  ),
                  same(initial_states[index]),
                );
              }
              expect(tester.takeException(), isNull);
            }
            tester.testTextInput.hide();
            initial_state.widget.focusNode.unfocus();
            await tester.pumpAndSettle();
          }

          // 在同一真实页面切换布局模式，确保正文输入仍先收起工具栏。
          final page_view_state = tester.state(find.byType(PageView));
          final field_controllers = [
            for (final state in initial_states) state.widget.controller,
          ];
          tester
              .widget<EditorStepIndicator>(find.byType(EditorStepIndicator))
              .on_step_tap!(2);
          await tester.pumpAndSettle();
          expect(tester.state(find.byType(PageView)), same(page_view_state));
          expect(
            tester.widget<Scaffold>(find.byType(Scaffold)).bottomNavigationBar,
            isNull,
          );

          final content = find.byKey(const ValueKey('short_content_input'));
          final content_editable = find.descendant(
            of: content,
            matching: find.byType(EditableText),
          );
          final content_state = tester.state<EditableTextState>(
            content_editable,
          );
          tester.testTextInput.log.clear();
          await tester.tap(content);
          await tester.pump();
          await tester.pump(
            Duration(
              microseconds:
                  WorkEditorStyle.keyboard_chrome_duration.inMicroseconds ~/ 2,
            ),
          );
          expect(
            tester.getSize(find.byType(SizeTransition).first).height,
            greaterThan(0),
          );
          expect(
            tester.getSize(find.byType(SizeTransition).last).height,
            greaterThan(0),
          );
          expect(tester.testTextInput.isVisible, isFalse);
          expect(
            tester.testTextInput.log.where(
              (call) => call.method == 'TextInput.show',
            ),
            isEmpty,
          );
          await tester.pumpAndSettle();
          expect(tester.getSize(find.byType(SizeTransition).first).height, 0);
          expect(tester.getSize(find.byType(SizeTransition).last).height, 0);
          expect(tester.testTextInput.isVisible, isTrue);
          await tester.enterText(content, '切换步骤后继续写作');
          tester.view.viewInsets = const FakeViewPadding(bottom: 320);
          tester.view.padding = const FakeViewPadding();
          await tester.pumpAndSettle();
          expect(
            tester.state<EditableTextState>(content_editable),
            same(content_state),
          );
          expect(content_state.widget.controller.text, '切换步骤后继续写作');
          tester.testTextInput.hide();
          tester.view.viewInsets = const FakeViewPadding();
          tester.view.padding = const FakeViewPadding(bottom: _safe_bottom);
          await tester.pumpAndSettle();

          // 返回步骤一仍使用原控制器；标题可立即输入，底栏不随键盘上移。
          tester
              .widget<EditorStepIndicator>(find.byType(EditorStepIndicator))
              .on_step_tap!(0);
          await tester.pumpAndSettle();
          expect(tester.state(find.byType(PageView)), same(page_view_state));
          for (var index = 0; index < 2; index++) {
            expect(
              tester.widget<TextField>(fields.at(index)).controller,
              same(field_controllers[index]),
            );
          }
          expect(field_controllers[0].text, '标题在键盘收放后依旧保留');
          expect(field_controllers[1].text, '简介第一段。\n简介第二段也要保留。');
          await tester.ensureVisible(fields.first);
          await tester.pumpAndSettle();
          await tester.tap(fields.first);
          await tester.pump();
          expect(tester.testTextInput.isVisible, isTrue);
          tester.view.viewInsets = const FakeViewPadding(bottom: 320);
          tester.view.padding = const FakeViewPadding();
          await tester.pump(_frame_duration);
          expect(
            tester.getRect(
              find.byWidget(
                tester
                    .widget<Scaffold>(find.byType(Scaffold))
                    .bottomNavigationBar!,
              ),
            ),
            bottom_bar_rect,
          );
          expect(
            tester.getRect(find.byType(PageView)).bottom,
            _screen_size.height - 320,
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
        variant: TargetPlatformVariant.only(platform),
      );
    }
  }
}

/// 保留页面使用的真实主题状态，跳过与布局无关的网络监听。
class _TestDeviceInfo extends DeviceInfo {
  @override
  // 测试特意不执行基类的设备网络初始化。
  // ignore: must_call_super
  void onInit() {}
}

/// 语种查询仍使用真实逻辑，跳过本地存储加载。
class _TestLanguageStore extends LanguageStore {
  _TestLanguageStore() : super(asset_language_code_list: ['zh']);

  @override
  // 测试特意不执行基类的本地存储初始化。
  // ignore: must_call_super
  void onInit() {}
}

/// 使用应用真实文案，同时避免逐帧测试依赖异步资源读取。
class _EditorAssetLoader extends AssetLoader {
  final Map<String, dynamic> translations;

  const _EditorAssetLoader(this.translations);

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      translations;
}
