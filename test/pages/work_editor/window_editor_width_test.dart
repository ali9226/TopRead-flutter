// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:app/components/window_content_layout/index.dart';
import 'package:app/pages/work_editor/_shared/widgets/steps/step_content/widgets/long_content_editor.dart';
import 'package:app/pages/work_editor/single_chapter/widgets/chapter_writing_surface.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _Assets extends AssetLoader {
  const _Assets();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      Map<String, dynamic>.from(
        jsonDecode(File('$path/en.json').readAsStringSync()) as Map,
      );
}

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
  for (final single in [false, true]) {
    for (final dark in [false, true]) {
      testWidgets('真实章节编辑器 single=$single dark=$dark 填满Duo窗口且折叠保留草稿状态', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(951, 669);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final title = TextEditingController(text: 'Draft title');
        final content = TextEditingController(text: 'Unsaved draft.');
        final window_size = ValueNotifier<Size>(const Size(951, 669));
        addTearDown(title.dispose);
        addTearDown(content.dispose);
        addTearDown(window_size.dispose);
        final editor_key = GlobalKey();
        final editor = single
            ? ChapterWritingSurface(
                key: editor_key,
                title_controller: title,
                content_controller: content,
                is_dark: dark,
                is_cjk: false,
                read_only: false,
              )
            : LongContentEditor(
                key: editor_key,
                is_dark: dark,
                is_editing: false,
                chapters: const [],
                chapter_title_controller: title,
                chapter_content_controller: content,
                current_word_count: 13,
                on_content_changed: () {},
                on_file_upload: () {},
                on_edit_chapter: (_) {},
                on_save_current_chapter: () {},
                on_delete_chapter: (_) {},
                on_reorder_chapters: (_, _) {},
              );
        await tester.pumpWidget(
          EasyLocalization(
            supportedLocales: const [Locale('en')],
            path: 'assets/i18n',
            assetLoader: const _Assets(),
            startLocale: const Locale('en'),
            saveLocale: false,
            child: Builder(
              builder: (context) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                theme: ThemeData(
                  brightness: dark ? Brightness.dark : Brightness.light,
                ),
                home: ValueListenableBuilder<Size>(
                  valueListenable: window_size,
                  child: editor,
                  builder: (context, size, child) => MediaQuery(
                    data: MediaQueryData(
                      size: size,
                      padding: const EdgeInsets.only(right: 84, bottom: 34),
                      viewPadding: const EdgeInsets.only(right: 84, bottom: 34),
                      displayFeatures: [
                        DisplayFeature(
                          bounds: Rect.fromLTWH(size.width - 84, 0, 84, 124),
                          type: DisplayFeatureType.cutout,
                          state: DisplayFeatureState.unknown,
                        ),
                      ],
                    ),
                    child: WindowLayoutScope(
                      child: Scaffold(body: WindowContentLayout(child: child!)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final original_element = editor_key.currentContext;
        final original_state = editor_key.currentState;
        final field = find.byKey(
          ValueKey(single ? 'single_chapter_content' : 'chapter_content_input'),
        );
        for (final size in const [
          Size(951, 669),
          Size(466, 678),
          Size(951, 669),
        ]) {
          tester.view.physicalSize = size;
          window_size.value = size;
          await tester.pumpAndSettle();
          expect(tester.getRect(field).left, 12);
          expect(tester.getRect(field).right, size.width - 12);
          expect(editor_key.currentContext, same(original_element));
          expect(editor_key.currentState, same(original_state));
          expect(title.text, 'Draft title');
          expect(content.text, 'Unsaved draft.');
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
