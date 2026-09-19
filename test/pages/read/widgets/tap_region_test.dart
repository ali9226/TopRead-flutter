// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/read/widgets/content/paragraph.dart';
import 'package:app/pages/read/widgets/content/tap_region.dart';
import 'package:app/stores/novel_reading_store.dart';
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

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    for (final target in ['paragraph_gap', 'second_paragraph']) {
      testWidgets(
        '$platform 选区外点击 $target 先退出选择，第二次点击才翻页',
        (tester) async {
          int turns = 0;
          final selected = <String>{};
          await _pump_reading_region(
            tester,
            on_tap: (_) => turns++,
            on_selection: (key, active) {
              if (active) {
                selected.add(key);
              } else {
                selected.remove(key);
              }
            },
          );

          await tester.longPress(find.byType(EditableText).first);
          await tester.pumpAndSettle();
          expect(selected, {'first_paragraph'});
          expect(turns, 0);

          final target_position = tester.getCenter(
            find.byKey(ValueKey<String>(target)),
          );
          final gesture = await tester.startGesture(target_position);
          await tester.pump();

          // 点击空白会先触发 onTapOutside；点击另一编辑器可能同属 TapRegion。
          if (target == 'paragraph_gap') expect(selected, isEmpty);
          expect(turns, 0);
          await gesture.up();
          await tester.pumpAndSettle();
          expect(turns, 0);
          expect(selected, isEmpty);
          expect(tester.testTextInput.isVisible, isFalse);

          await tester.tapAt(target_position);
          await tester.pumpAndSettle();
          expect(turns, 1);
          expect(tester.takeException(), isNull);
        },
        variant: TargetPlatformVariant.only(platform),
      );
    }
  }

  testWidgets('正文外层门控等待单击确认，拖动滚动不会触发翻页', (tester) async {
    int turns = 0;
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await _pump_reading_region(
      tester,
      on_tap: (_) => turns++,
      on_selection: (_, _) {},
      scroll_controller: controller,
      first_text: List<String>.filled(60, 'A long story beyond the hills.').join(' '),
    );

    final position = tester.getTopLeft(find.byType(EditableText).first) +
        const Offset(40, 20);
    final gesture = await tester.startGesture(position);
    await tester.pump(const Duration(milliseconds: 100));
    expect(turns, 0);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(turns, 1);

    await tester.dragFrom(const Offset(200, 400), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(controller.offset, greaterThan(0));
    expect(turns, 1);
    expect(tester.takeException(), isNull);
  });
}

/// 组合实际长篇段落和正文门控，复现原生选区清理与外层翻页的事件顺序。
Future<void> _pump_reading_region(
  WidgetTester tester, {
  required ValueChanged<Offset> on_tap,
  required void Function(String, bool) on_selection,
  ScrollController? scroll_controller,
  String first_text = 'The first paragraph beneath the moon.',
}) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/i18n',
      assetLoader: const _Translations(),
      startLocale: const Locale('en'),
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              controller: scroll_controller,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(80, 160, 80, 80),
                child: ReaderTapRegion(
                  on_tap_position: on_tap,
                  builder: (on_tap_position, update_selection) {
                    Widget paragraph(String key, String text, int start) =>
                        ReaderParagraphItem(
                          key: ValueKey<String>(key),
                          item: ReadingContentItem(
                            text: text,
                            chapter_no: 1,
                            chapter_index: 0,
                            chapter_id: '11',
                            words_before_this_chapter: 0,
                            chapter_total_words: 100,
                            start_offset: start,
                            end_offset: start + text.length,
                          ),
                          is_dark: false,
                          body_font_size: 18,
                          text_color: Colors.black,
                          on_comment: (_) {},
                          on_tap_position: on_tap_position,
                          on_selection_changed: (active) {
                            update_selection(key, active);
                            on_selection(key, active);
                          },
                        );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        paragraph('first_paragraph', first_text, 0),
                        const SizedBox(
                          key: ValueKey<String>('paragraph_gap'),
                          height: 72,
                        ),
                        paragraph(
                          'second_paragraph',
                          'The second paragraph beyond the forest.',
                          first_text.length + 1,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _Translations extends AssetLoader {
  const _Translations();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {
    'paragraph_comment': {
      'write': 'Comment',
      'share': 'Share',
      'count_label': '{count} comments',
    },
  };
}
