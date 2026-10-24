// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/detail/logic.dart';
import 'package:app/pages/comics/reader/index.dart';
import 'package:app/components/reader_top_bar/action_button.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/pages/comics/reader/logic.dart';
import 'package:app/pages/comics/reader/widgets/top_scrim.dart';
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
  WidgetTester tester,
) async {
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
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
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
  testWidgets('中段显隐导航与系统安全区变化不移动漫画、不改变视口或进度', (tester) async {
    _set_viewport(tester);
    final (logic, detail, progress) = await _mount_reader(tester);
    logic.scroll.jumpTo(240);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(logic.controls_visible, isTrue, reason: '程序化定位不能当作用户向下阅读');
    final touch = find.byKey(const ValueKey('comic_reader_touch_surface'));
    final image = find.byKey(const ValueKey('10:0'));
    final canvas = tester.getRect(touch);
    final image_position = tester.getTopLeft(image);
    final viewport_height = logic.scroll.position.viewportDimension;
    final offset = logic.scroll.offset;
    final chapter_progress = logic.chapter_progress;
    void expect_stable_canvas() {
      expect(tester.getRect(touch), canvas);
      expect(tester.getTopLeft(image).dy, closeTo(image_position.dy, 0.01));
      expect(
        logic.scroll.position.viewportDimension,
        closeTo(viewport_height, 0.01),
      );
      expect(logic.scroll.offset, closeTo(offset, 0.01));
      expect(logic.chapter_progress, closeTo(chapter_progress, 0.00001));
    }

    await tester.tapAt(canvas.center);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(logic.controls_visible, isFalse);
    expect_stable_canvas();
    tester.view.padding = const FakeViewPadding();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect_stable_canvas();
    await tester.tapAt(canvas.center);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(logic.controls_visible, isTrue);
    expect_stable_canvas();
    tester.view.padding = const FakeViewPadding(top: 59, bottom: 34);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect_stable_canvas();
    expect(tester.takeException(), isNull);
    await _dispose_reader(tester, logic, detail, progress);
  });

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
