// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:app/components/window_content_layout/index.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/detail/logic.dart';
import 'package:app/pages/comics/reader/index.dart';
import 'package:app/components/reader_top_bar/action_button.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/pages/comics/reader/logic.dart';
import 'package:app/pages/comics/reader/widgets/top_scrim.dart';
import 'package:app/pages/comics/reader/widgets/bottom_scrim.dart';
import 'package:app/pages/comics/reader/widgets/chapter_end.dart';
import 'package:app/services/comics_progress/service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'logic_test.dart' show reading;

class _Assets extends AssetLoader {
  const _Assets();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      jsonDecode(File('$path/en.json').readAsStringSync())
          as Map<String, dynamic>;
}

class _Detail extends ComicDetailLogic {
  _Detail() : super(7) {
    final value = reading(10);
    detail = ComicDetail(
      comic: value.comic,
      languages: [value.language],
      selected_language_id: value.language.id,
      chapters: [value.chapter],
      is_collected: true,
      read_record: {},
    );
    loading = false;
    collected = true;
  }
  @override
  Future<void> load({String? language}) async {}
}

/// TODO 所有交互测试挂载实际阅读页与内存进度服务，不直接调用页面私有手势处理。
Future<(ComicReaderLogic, _Detail, ComicsProgressService)> _mount_reader(
  WidgetTester tester, {
  bool dark = false,
  double text_scale = 1,
  List<ui.DisplayFeature> display_features = const [],
  bool reduce_motion = false,
}) async {
  final progress = ComicsProgressService(
    account_id: () => 0,
    read_storage: (_) async => null,
    write_storage: (_, _) async {},
  );
  final logic = ComicReaderLogic(
    progress: progress,
    read_chapter: (id) async => reading(id),
  );
  final detail = _Detail();
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/i18n',
      assetLoader: const _Assets(),
      startLocale: const Locale('en'),
      saveLocale: false,
      child: Builder(
        builder: (context) => MaterialApp(
          theme: ThemeData(
            brightness: dark ? Brightness.dark : Brightness.light,
          ),
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(text_scale),
              displayFeatures: display_features,
              disableAnimations: reduce_motion,
            ),
            child: WindowLayoutScope(child: child!),
          ),
          home: ComicReaderPage(
            chapter_id: 10,
            controller: logic,
            detail_controller: detail,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  return (logic, detail, progress);
}

Future<void> _dispose_reader(
  WidgetTester tester,
  ComicReaderLogic logic,
  _Detail detail,
  ComicsProgressService progress,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  logic.dispose();
  detail.dispose();
  await progress.flush(comic_id: 7);
  progress.dispose();
}

void _set_viewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  tester.view.padding = const FakeViewPadding(top: 59, bottom: 34);
  tester.view.viewPadding = const FakeViewPadding(top: 59, bottom: 34);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewPadding);
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
  testWidgets('全屏三段点击按一屏翻动，中段显隐导航；进度面板跳转本章', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final (logic, detail, progress) = await _mount_reader(tester);
    expect(
      find.descendant(
        of: find.byType(ComicReaderTopScrim),
        matching: find.text('Chapter 10'),
      ),
      findsOneWidget,
    );
    final favorite = tester
        .widgetList<ReaderTopBarAction>(find.byType(ReaderTopBarAction))
        .singleWhere((action) => action.selected != null);
    expect(favorite.selected, isTrue);
    expect((favorite.icon_widget! as SvgIcon).name, 'user_selected');
    final touch = find.byKey(const ValueKey('comic_reader_touch_surface'));
    await tester.tapAt(tester.getCenter(touch));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(logic.controls_visible, isFalse);
    final rect = tester.getRect(touch);
    await tester.tapAt(Offset(rect.center.dx, rect.bottom - rect.height / 6));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      logic.scroll.offset,
      closeTo(logic.scroll.position.viewportDimension, 1),
    );
    await tester.tapAt(Offset(rect.center.dx, rect.top + rect.height / 6));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(logic.scroll.offset, closeTo(0, 1));
    await tester.tapAt(rect.center);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(logic.controls_visible, isTrue);
    await tester.tap(find.text('Progress'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(Slider), findsOneWidget);
    final slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChanged!(0.6);
    slider.onChangeEnd!(0.6);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(logic.chapter_progress, closeTo(0.6, 0.01));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    logic.dispose();
    detail.dispose();
    await progress.flush(comic_id: 7);
    progress.dispose();
  });
  testWidgets('顶栏与可读画布同步让位，安全区变化不改变章内图片锚点', (tester) async {
    _set_viewport(tester);
    final (logic, detail, progress) = await _mount_reader(tester);
    logic.scroll.jumpTo(240);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(logic.controls_visible, isTrue, reason: '程序化定位不能当作用户向下阅读');
    final touch = find.byKey(const ValueKey('comic_reader_touch_surface'));
    final image = find.byKey(const ValueKey('10:0'));
    final canvas = tester.getRect(touch);
    final top_bar = find.byType(ComicReaderTopScrim);
    final image_height = tester.getSize(image).height;
    final offset = logic.scroll.offset;
    final page_index = logic.page_index;
    void expect_readable_anchor() {
      final visible_canvas = tester.getRect(touch);
      expect(
        visible_canvas.top,
        closeTo(tester.getRect(top_bar).bottom, 0.01),
        reason: '显隐过渡中也不能让实色顶栏盖住当前阅读位置',
      );
      expect(
        tester.getTopLeft(image).dy - visible_canvas.top,
        closeTo(-offset, 0.01),
      );
      expect(tester.getSize(image).height, image_height);
      expect(logic.scroll.offset, closeTo(offset, 0.01));
      expect(logic.page_index, page_index);
      expect(logic.reading!.chapter.id, 10);
    }

    expect_readable_anchor();
    await tester.tapAt(canvas.center);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(logic.controls_visible, isFalse);
    expect_readable_anchor();
    tester.view.padding = const FakeViewPadding();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect_readable_anchor();
    expect(tester.getRect(touch).top, 0, reason: '隐藏顶栏后恢复完整图片画布');
    await tester.tapAt(canvas.center);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(logic.controls_visible, isTrue);
    expect_readable_anchor();
    tester.view.padding = const FakeViewPadding(top: 59, bottom: 34);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect_readable_anchor();
    expect(tester.getRect(touch), canvas);
    await logic.save_progress();
    await progress.flush(comic_id: 7);
    final record = await progress.read_record(7);
    expect(record['page_index'], page_index);
    expect(record['page_fraction'], closeTo(offset / image_height, 0.00001));
    expect(tester.takeException(), isNull);
    await _dispose_reader(tester, logic, detail, progress);
  });

  for (final layout in ['portrait', 'landscape', 'duo']) {
    for (final dark in [false, true]) {
      testWidgets('漫画图片首尾可读且切换不跳章：$layout ${dark ? 'dark' : 'light'}', (
        tester,
      ) async {
        _set_viewport(tester);
        tester.view.physicalSize = switch (layout) {
          'landscape' => const Size(844, 390),
          'duo' => const Size(466, 678),
          _ => const Size(390, 844),
        };
        if (layout == 'landscape') {
          tester.view.padding = const FakeViewPadding(
            left: 59,
            right: 34,
            bottom: 21,
          );
          tester.view.viewPadding = const FakeViewPadding(
            left: 59,
            right: 34,
            bottom: 21,
          );
        }
        final (logic, detail, progress) = await _mount_reader(
          tester,
          dark: dark,
          text_scale: 2,
          reduce_motion: dark,
          display_features: layout == 'duo'
              ? const [
                  ui.DisplayFeature(
                    bounds: Rect.fromLTWH(382, 0, 84, 124),
                    type: ui.DisplayFeatureType.cutout,
                    state: ui.DisplayFeatureState.unknown,
                  ),
                ]
              : const [],
        );
        final touch = find.byKey(const ValueKey('comic_reader_touch_surface'));
        final top_bar = find.byType(ComicReaderTopScrim);
        final first_image = find.byKey(const ValueKey('10:0'));
        expect(
          tester.getTopLeft(first_image).dy,
          closeTo(tester.getRect(top_bar).bottom, 0.01),
          reason: '首张图片从导航栏下方完整开始，宽高比不变',
        );
        final image_width = tester.getSize(first_image).width;
        expect(
          tester.getSize(first_image).height,
          closeTo(image_width * 3, 0.01),
        );
        final bottom_bar = tester.getRect(find.byType(ComicReaderBottomScrim));
        logic.scroll.jumpTo(
          (logic.chapter_scroll_extent + bottom_bar.height).clamp(
            0,
            logic.scroll.position.maxScrollExtent,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        final last_image = find.byKey(const ValueKey('10:2'));
        expect(
          tester.getRect(last_image).bottom,
          closeTo(bottom_bar.top, 0.01),
          reason: '章末区已有滚动余量，末张图片能够完整离开实色底栏',
        );
        logic.scroll.jumpTo(logic.scroll.position.maxScrollExtent);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        final chapter_end = find.byType(ComicReaderChapterEnd);
        final end_bottom = tester.getRect(chapter_end).bottom;
        final page_index = logic.page_index;
        await tester.tapAt(tester.getCenter(touch));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(logic.controls_visible, isFalse);
        expect(tester.getRect(touch).top, 0);
        expect(tester.getRect(chapter_end).bottom, closeTo(end_bottom, 0.01));
        expect(logic.page_index, page_index);
        expect(logic.reading!.chapter.id, 10);
        expect(tester.takeException(), isNull);
        await _dispose_reader(tester, logic, detail, progress);
      });
    }
  }

  testWidgets('用户向下读隐藏工具栏，反向上读显示，惯性结束不反转显隐', (tester) async {
    _set_viewport(tester);
    final (logic, detail, progress) = await _mount_reader(tester);
    logic.scroll.jumpTo(300);
    await tester.pump();
    final touch = find.byKey(const ValueKey('comic_reader_touch_surface'));
    expect(logic.controls_visible, isTrue);
    final initial_offset = logic.scroll.offset;
    await tester.timedDrag(
      touch,
      const Offset(0, -220),
      const Duration(milliseconds: 600),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(logic.scroll.offset, greaterThan(initial_offset));
    expect(logic.controls_visible, isFalse);
    final downward_offset = logic.scroll.offset;
    await tester.timedDrag(
      touch,
      const Offset(0, 180),
      const Duration(milliseconds: 600),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(logic.scroll.offset, lessThan(downward_offset));
    expect(logic.controls_visible, isTrue);
    await tester.pump(const Duration(milliseconds: 400));
    expect(logic.controls_visible, isTrue);
    expect(tester.takeException(), isNull);
    await _dispose_reader(tester, logic, detail, progress);
  });
}
