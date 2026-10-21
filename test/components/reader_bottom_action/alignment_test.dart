// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'package:app/components/reader_action_icon/index.dart';
import 'package:app/components/reader_bottom_action/index.dart';
import 'package:app/components/reader_bottom_action/style.dart';
import 'package:app/models/project_config.dart';
import 'package:app/pages/comics/reader/widgets/bottom_scrim.dart';
import 'package:app/pages/read/widgets/navigation_bars/bottom/index.dart';
import 'package:app/pages/short_story_read/widgets/bottom_comment_bar.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Assets extends AssetLoader {
  const _Assets();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      jsonDecode(File('$path/en.json').readAsStringSync())
          as Map<String, dynamic>;
}

Widget _bar(String kind) {
  void action() {}
  return switch (kind) {
    'novel' => ReadBottomBar(
      is_dark: false,
      show: true,
      progress: 0,
      chapter_list: const [],
      on_progress_changed_end: (_) {},
      chapter_index_for_progress: (_) => 0,
      on_prev_chapter: action,
      on_next_chapter: action,
      is_first_chapter: true,
      is_last_chapter: true,
      on_catalog_tap: action,
      on_setting_tap: action,
      on_comment_tap: action,
      comment_count: 0,
      is_liked: false,
      like_count: 0,
      is_like_loading: false,
      on_like_tap: action,
    ),
    'short' => Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: BottomCommentBar(
        is_dark: false,
        comment_count: 0,
        like_count: 0,
        is_liked: false,
        is_like_loading: false,
        on_catalog_tap: action,
        on_comment_tap: action,
        on_like_tap: action,
        on_setting_tap: action,
      ),
    ),
    _ => Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: ComicReaderBottomScrim(
        on_open_catalog: action,
        on_progress: action,
        on_appearance: action,
        on_comments: action,
      ),
    ),
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (_) async => <String, Object>{},
        );
    await EasyLocalization.ensureInitialized();
  });
  tearDown(Get.reset);

  for (final scale in [1.0, 2.0]) {
    testWidgets('三种阅读底栏四等分、图标与文字基线、安全区完全对齐 $scale', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.padding = const FakeViewPadding(bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(bottom: 34);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      Get.put(ProjectConfigStore()).save_config(
        ProjectConfig.from_json({'comment_switch': SwitchValue.on}),
      );
      List<Rect>? reference;
      double? icon_y;
      double? text_baseline;
      for (final kind in ['novel', 'short', 'comic']) {
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
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: Scaffold(body: Stack(children: [_bar(kind)])),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final actions = find.byType(ReaderBottomAction);
        expect(actions, findsNWidgets(4));
        final rects = actions
            .evaluate()
            .map((element) => tester.getRect(find.byWidget(element.widget)))
            .toList();
        for (var index = 0; index < rects.length; index++) {
          expect(rects[index].left, closeTo(index * 97.5, 0.01));
          expect(rects[index].width, closeTo(97.5, 0.01));
          expect(
            rects[index].bottom,
            closeTo(810, 0.01),
            reason: '$kind安全区只在图标行下方预留一次',
          );
        }
        final first = actions.first;
        final icon = find.descendant(
          of: first,
          matching: find.byType(ReaderActionIcon),
        );
        final label = find.descendant(of: first, matching: find.byType(Text));
        final paragraph = tester.renderObject<RenderParagraph>(label);
        final baseline =
            tester.getTopLeft(label).dy +
            paragraph.getDryBaseline(
              paragraph.constraints,
              TextBaseline.alphabetic,
            )!;
        if (reference == null) {
          reference = rects;
          icon_y = tester.getCenter(icon).dy;
          text_baseline = baseline;
          expect(rects.first.height, scale == 1 ? 60 : greaterThan(60));
        } else {
          expect(rects, reference);
          expect(tester.getCenter(icon).dy, closeTo(icon_y!, 0.01));
          expect(baseline, closeTo(text_baseline!, 0.01));
        }
        expect(
          tester.getSize(icon),
          const Size(
            ReaderBottomActionStyle.icon_size,
            ReaderBottomActionStyle.icon_size,
          ),
        );
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
