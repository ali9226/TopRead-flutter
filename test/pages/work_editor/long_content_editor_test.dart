import 'dart:io';
import 'dart:ui' as ui;
import 'package:app/pages/author_center/author_style.dart';
import 'package:app/pages/author_center/models/creator_work.dart';
import 'package:app/pages/work_editor/chapter_editing_session.dart';
import 'package:app/pages/work_editor/widgets/steps/step_content/widgets/long_content_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    final icons = FontLoader('MaterialIcons')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File(
              '.fvm/flutter_sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
            ).readAsBytesSync(),
          ),
        ),
      );
    await icons.load();
    // 可选字体仅用于本地视觉预览；非 macOS 环境仍运行交互断言。
    final font = File('/System/Library/Fonts/STHeiti Light.ttc');
    if (font.existsSync()) {
      final loader = FontLoader('CreatorPreview')
        ..addFont(Future.value(ByteData.sublistView(font.readAsBytesSync())));
      await loader.load();
    }
  });
  for (final dark in [false, true]) {
    testWidgets('300章目录搜索与切换、${dark ? '夜间' : '日间'}布局', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final title = TextEditingController();
      final content = TextEditingController();
      final chapters = List.generate(
        300,
        (i) => CreatorChapterDraft(
          local_id: 'chapter_$i',
          title: i == 2 ? '风从海的那边来' : '远方的灯火 ${i + 1}',
          content: i == 2
              ? '天色渐渐暗了下来，海面上最后一道光也隐去了。\n\n她把信放进口袋，沿着熟悉的小路往回走。风带着潮湿的气息，吹动路旁高高的芦苇。\n\n故事，才刚刚开始。'
              : '第 ${i + 1} 章正文',
          update_time: DateTime(2026),
        ),
      );
      final session = ChapterEditingSession(
        chapters: chapters,
        titleController: title,
        contentController: content,
      )..select(2);
      addTearDown(() {
        session.dispose();
        title.dispose();
        content.dispose();
      });
      final boundary = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: dark ? Brightness.dark : Brightness.light,
            fontFamily: 'CreatorPreview',
            colorSchemeSeed: AuthorStyle.gold,
          ),
          builder: (context, child) =>
              RepaintBoundary(key: boundary, child: child!),
          home: Scaffold(
            backgroundColor: AuthorStyle.background(dark),
            appBar: AppBar(
              title: const Text('编辑作品'),
              actions: [
                TextButton(onPressed: () {}, child: const Text('保存草稿')),
              ],
            ),
            body: ListenableBuilder(
              listenable: session,
              builder: (context, _) => LongContentEditor(
                is_dark: dark,
                is_editing: true,
                chapters: chapters,
                active_chapter_index: session.activeIndex,
                chapter_word_count: chapters.fold(
                  0,
                  (sum, c) => sum + c.word_count,
                ),
                chapter_title_controller: title,
                chapter_content_controller: content,
                current_word_count: content.text.length,
                on_content_changed: () {},
                on_file_upload: () {},
                on_edit_chapter: session.select,
                on_save_current_chapter: session.add,
                on_delete_chapter: session.remove,
                on_reorder_chapters: session.reorder,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('远方的灯火 300'), findsNothing, reason: '主界面不展开全部章节');
      await _capture(tester, boundary, 'editor_${dark ? 'dark' : 'light'}');
      await tester.enterText(
        find.byKey(const ValueKey('chapter_content_input')),
        '修改第三章',
      );
      await tester.tap(find.byKey(const ValueKey('chapter_directory_button')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await _capture(tester, boundary, 'directory_${dark ? 'dark' : 'light'}');
      await tester.binding.setSurfaceSize(const Size(320, 600));
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      tester.view.viewInsets = const FakeViewPadding(bottom: 220);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '小屏大字和搜索键盘不能挤出溢出');
      await tester.enterText(
        find.widgetWithText(TextField, '搜索章节名，或输入章号'),
        '300',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('远方的灯火 300'));
      await tester.pumpAndSettle();
      expect(content.text, '第 300 章正文');
      expect(chapters[2].content, '修改第三章');
      expect(chapters.length, 300);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  if (Platform.environment['CREATOR_UI_PREVIEW'] != '1') return;
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('build/creator_editor_preview')
      ..createSync(recursive: true);
    await File(
      '${directory.path}/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
