// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/pages/published_long_novel_editor/logic.dart';
import 'package:app/pages/published_long_novel_editor/widgets/editor_header.dart';
import 'package:app/pages/published_long_novel_editor/widgets/chapter_directory.dart';
import 'dart:io';

import 'package:app/pages/work_editor/workspace/widgets/workspace_details.dart';
import 'package:app/pages/work_editor/workspace/widgets/workspace_directory.dart';
import 'package:app/pages/work_editor/workspace/logic.dart';
import 'package:app/pages/work_editor/single_chapter/widgets/chapter_writing_surface.dart';
import 'package:app/pages/work_editor/_shared/widgets/editor_keyboard_layout.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestTranslations extends AssetLoader {
  const _TestTranslations();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
          as Map<String, dynamic>;
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

  Future<void> mount(
    WidgetTester tester,
    Widget child,
    String language,
    bool dark,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [
          Locale('zh'),
          Locale('en'),
          Locale('fr'),
          Locale('sw'),
        ],
        startLocale: Locale(language),
        saveLocale: false,
        path: 'assets/i18n',
        assetLoader: const _TestTranslations(),
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            theme: dark ? ThemeData.dark() : ThemeData.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.3)),
              child: child!,
            ),
            home: Scaffold(body: child),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final language in ['zh', 'en', 'fr', 'sw']) {
    for (final dark in [false, true]) {
      testWidgets(
        '$language / dark=$dark: compact tabs retain navigation and drag mode',
        (tester) async {
          final tabs = TabController(length: 3, vsync: tester);
          final model = PublishedNovelController(1);
          addTearDown(tabs.dispose);
          addTearDown(model.dispose);
          model.chapters = List.generate(
            3,
            (i) => <String, dynamic>{
              'chapter_id': i + 1,
              'chapter_no': i + 1,
              'title': 'Chapter ${i + 1}',
            },
          );
          model.base_order = [1, 2, 3];
          var back = false;
          var deleted = false;
          await mount(
            tester,
            Column(
              children: [
                PublishedEditorHeader(
                  controller: tabs,
                  is_dark: dark,
                  is_cjk: language == 'zh',
                  on_back: () => back = true,
                  on_delete: () => deleted = true,
                ),
                Expanded(
                  child: PublishedChapterDirectory(
                    model: model,
                    is_dark: dark,
                    is_cjk: language == 'zh',
                    on_open: (_) {},
                  ),
                ),
              ],
            ),
            language,
            dark,
          );
          expect(find.byType(TextField), findsNothing);
          final back_rect = tester.getRect(find.byType(BackButton));
          final delete_rect = tester.getRect(
            find.byTooltip(tr('creator_center.delete')),
          );
          final tab_rect = tester.getRect(find.byType(TabBar));
          expect(back_rect.center.dy, delete_rect.center.dy);
          expect(tab_rect.top, greaterThanOrEqualTo(back_rect.bottom));
          expect(
            tester
                .widget<SvgIcon>(
                  find.byWidgetPredicate(
                    (widget) => widget is SvgIcon && widget.name == 'delete',
                  ),
                )
                .color,
            ColorConstants.dangerColor,
          );

          expect(
            tester.widget<TabBar>(find.byType(TabBar)).tabAlignment,
            TabAlignment.start,
          );
          await tester.tap(find.byType(BackButton));
          await tester.tap(find.byTooltip(tr('creator_center.delete')));
          expect(back, true);
          expect(deleted, true);
          await tester.tap(find.text(tr('creator_center.reorder')));
          await tester.pumpAndSettle();
          expect(find.byType(ReorderableDragStartListener), findsNWidgets(3));
          final handles = find.byType(ReorderableDragStartListener);
          await tester.drag(handles.first, const Offset(0, 160));
          await tester.pumpAndSettle();
          expect(model.order_dirty, true);
          expect(model.visible_chapters.first['chapter_id'], isNot(1));
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );

      testWidgets(
        '$language / dark=$dark: narrow directory keeps chapter actions usable',
        (tester) async {
          final model = WorkspaceController(1);
          addTearDown(model.dispose);
          final row = <String, dynamic>{
            'chapter_id': 10,
            'chapter_no': 1,
            'title':
                '很长的章节标题 A very long chapter title that wraps on a narrow screen',
            'word_count': 1800,
          };
          model.chapters = [row];
          Map<String, dynamic>? opened;
          String? action;
          await mount(
            tester,
            WorkspaceDirectory(
              model: model,
              is_dark: dark,
              is_cjk: language == 'zh',
              working: false,
              on_open: (value) => opened = value,
              on_action: (_, value) => action = value,
            ),
            language,
            dark,
          );
          expect(tester.takeException(), isNull);
          await tester.tap(find.textContaining('A very long chapter title'));
          expect(opened, same(row));
          await tester.tap(find.byType(PopupMenuButton<String>));
          await tester.pumpAndSettle();
          await tester.tap(find.text(tr('creator_workspace.move_down')));
          await tester.pumpAndSettle();
          expect(action, 'down');
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        '$language / dark=$dark: published directory toggles order and shows schedule without draft actions',
        (tester) async {
          final model = PublishedNovelController(1);
          addTearDown(model.dispose);
          model.chapters = [
            {'chapter_id': 1, 'chapter_no': 1, 'title': 'First chapter'},
            {
              'revision_id': 2,
              'chapter_no': 0,
              'title': 'Scheduled chapter',
              'is_scheduled': true,
              'scheduled_publish_time': '2026-12-01T10:00:00Z',
            },
          ];
          Map<String, dynamic>? opened;
          await mount(
            tester,
            PublishedChapterDirectory(
              model: model,
              is_dark: dark,
              is_cjk: language == 'zh',
              on_open: (row) => opened = row,
            ),
            language,
            dark,
          );
          expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
          expect(find.byType(PopupMenuButton<String>), findsNothing);
          expect(model.visible_chapters.first['title'], 'Scheduled chapter');
          await tester.tap(find.byTooltip(tr('published_editor.descending')));
          expect(model.visible_chapters.first['title'], 'First chapter');
          await tester.tap(find.textContaining('Scheduled chapter'));
          expect(opened?['revision_id'], 2);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        '$language / dark=$dark: long work details scroll without overflow',
        (tester) async {
          await mount(
            tester,
            WorkspaceDetails(
              novel: {
                'title': 'A long novel title 新作品',
                'introduction': List.filled(60, 'Introduction 简介').join('\n'),
              },
              is_dark: dark,
              is_cjk: language == 'zh',
              is_published: true,
              on_read: () {},
            ),
            language,
            dark,
          );
          expect(tester.takeException(), isNull);
          await tester.drag(
            find.byType(SingleChildScrollView),
            const Offset(0, -300),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'chapter writing preserves input and enforces published request lock',
    (tester) async {
      final title = TextEditingController(text: 'Chapter');
      final content = TextEditingController(text: 'Original text');
      addTearDown(title.dispose);
      addTearDown(content.dispose);
      Widget surface(bool locked) => EditorKeyboardLayout(
        collapse_when_editing: false,
        header: const SizedBox(height: 50),
        footer: const SizedBox(height: 60),
        content: ChapterWritingSurface(
          title_controller: title,
          content_controller: content,
          is_dark: false,
          is_cjk: false,
          read_only: locked,
        ),
      );
      await mount(tester, surface(false), 'en', false);
      await tester.enterText(
        find.byKey(const ValueKey('single_chapter_title')),
        'Updated chapter',
      );
      await tester.enterText(
        find.byKey(const ValueKey('single_chapter_content')),
        'Updated content',
      );
      expect(title.text, 'Updated chapter');
      expect(content.text, 'Updated content');
      await mount(tester, surface(true), 'en', false);
      for (final field in tester.widgetList<TextField>(
        find.byType(TextField),
      )) {
        expect(field.readOnly, isTrue);
      }
      expect(content.text, 'Updated content');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
