// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';

import 'package:app/api/results_type.dart';
import 'package:app/components/page_top_gradient_overlay/index.dart';
import 'package:app/components/top_header_gradient/index.dart';
import 'package:app/components/window_content_layout/index.dart';
import 'package:app/models/novel_info.dart';
import 'package:app/pages/read/index.dart';
import 'package:app/pages/read/logic.dart';
import 'package:app/pages/read/style.dart';
import 'package:app/pages/read/utils/chapter_cache.dart';
import 'package:app/pages/read/widgets/content/paragraph.dart';
import 'package:app/pages/read/widgets/main_list/index.dart';
import 'package:app/pages/read/widgets/navigation_bars/bottom/index.dart';
import 'package:app/pages/read/widgets/navigation_bars/top/index.dart';
import 'package:app/pages/read/widgets/skeleton/content_skeleton.dart';
import 'package:app/pages/read/widgets/skeleton/index.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/novel_reading_store.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:app/stores/read_ad_free_store.dart';
import 'package:app/stores/user_information.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

ResultsType<T> _success<T>(T content) => ResultsType<T>()
  ..status = true
  ..content = content;

class _Device extends DeviceInfo {
  @override
  // ignore: must_call_super
  void onInit() {}
}

class _AdFree extends ReadAdFreeStore {
  _AdFree() {
    is_status_ready = true;
    expire_time = DateTime.now().add(const Duration(days: 1));
  }

  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  Future<void> refresh() async {}
}

class _Assets extends AssetLoader {
  const _Assets();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      Map<String, dynamic>.from(
        jsonDecode(File('$path/en.json').readAsStringSync()) as Map,
      );
}

class _Reader {
  final Logic logic;
  final GlobalKey page_key;
  final dynamic state;
  final List<ReadingContentItem> original_items;

  _Reader(this.logic, this.page_key)
    : state = page_key.currentState!,
      original_items = List<ReadingContentItem>.of(logic.store.reading_items);

  ReadMainList main_list(WidgetTester tester) =>
      tester.widget<ReadMainList>(find.byType(ReadMainList));

  void expect_content_kept() {
    expect(page_key.currentState, same(state));
    expect(logic.is_jumping_chapter.value, isFalse);
    expect(logic.is_switching_chapter.value, isFalse);
    expect(find.byType(ReadSkeleton), findsNothing);
    expect(find.byType(ReadContentSkeleton), findsNothing);
    expect(logic.loaded_chapter_indexes, {0, 1, 2});
    expect(logic.store.reading_items, hasLength(original_items.length));
    for (var index = 0; index < original_items.length; index++) {
      expect(
        logic.store.reading_items[index],
        same(original_items[index]),
        reason: '进入正文和续读应保留现有章节窗口中的每个正文对象',
      );
    }
  }
}

Future<_Reader> _mount_reader(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(466, 678);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final namespace = DateTime.now().microsecondsSinceEpoch;
  final chapter_ids = ['$namespace-0', '$namespace-1', '$namespace-2'];
  final logic = Logic(
    story_id: 7101,
    story_title: 'Smooth reading',
    initial_body_font_size: 18,
    novel_info_loader: (_) async => _success(
      NovelInfo.from_json({
        'id': '7101',
        'title': 'Smooth reading',
        'language_info': {
          'id': '72',
          'title': 'Smooth reading',
          'word_count': 18000,
        },
      }),
    ),
    chapter_directory_loader: (_) async => _success([
      for (var index = 0; index < chapter_ids.length; index++)
        NovelChapterInfo.from_json({
          'id': chapter_ids[index],
          'novel_language_id': '72',
          'chapter_no': index + 1,
          'title': 'Chapter ${index + 1}',
          'word_count': 6000,
        }),
    ]),
    chapter_content_loader: (id) async => List.generate(
      24,
      (paragraph) =>
          'Chapter ${chapter_ids.indexOf(id) + 1}, paragraph $paragraph. '
          'The reader remembers this part of the story when returning to the '
          'cover. Every paragraph remains in the existing reading window.',
    ).join('\n'),
    chapter_paragraph_metadata_loader: (_, {required novel_id}) async => null,
  );
  // 通过真实加载接口准备完整窗口，避免后台追加章节改变本测试的滚动边界。
  // 磁盘缓存走真实异步区；页面生命周期、定位和动画始终使用测试帧。
  await tester.runAsync(() async {
    await logic.fetch_info();
    await logic.load_next_chapter();
    await logic.load_next_chapter();
  });
  final page_key = GlobalKey();
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
          home: WindowLayoutScope(
            max_width: 760,
            child: ReadPage(
              key: page_key,
              story_id: 7101,
              story_title: 'Smooth reading',
              controller: logic,
            ),
          ),
        ),
      ),
    ),
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.runAsync(() async {
      for (final id in chapter_ids) {
        await ChapterCache.clear(id);
      }
    });
  });
  // 阅读页含持续装饰动画，有限帧等待初始化，不使用 pumpAndSettle。
  for (var frame = 0; frame < 12; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  final reader = _Reader(logic, page_key);
  expect(logic.is_loading.value, isFalse);
  expect(logic.scroll_controller.offset, 0);
  expect(reader.state.has_started_reading, isFalse);
  expect(reader.main_list(tester).continuing_listenable!.value, isFalse);
  reader.expect_content_kept();
  return reader;
}

Future<void> _read_chapter_paragraph(
  WidgetTester tester,
  _Reader reader,
  int chapter_index,
) async {
  final paragraph = find
      .byWidgetPredicate(
        (widget) =>
            widget is ReaderParagraphItem &&
            widget.item.chapter_index == chapter_index &&
            !widget.item.is_title,
      )
      .at(10);
  // 选择真实正文段落作为用户阅读位置，由页面自行识别章节和进度。
  await Scrollable.ensureVisible(tester.element(paragraph), alignment: .2);
  await tester.pump(const Duration(milliseconds: 16));
  expect(reader.logic.current_chapter_index.value, chapter_index);
  expect(reader.state.has_started_reading, isTrue);
  expect(reader.main_list(tester).continuing_listenable!.value, isTrue);
}

Future<List<double>> _press_read_and_sample(
  WidgetTester tester,
  _Reader reader, {
  bool repeat_press = false,
}) async {
  final scroll = reader.logic.scroll_controller;
  final on_read = reader.main_list(tester).on_read!;
  final offsets = <double>[scroll.offset];
  on_read();
  reader.expect_content_kept();
  // 留出布局帧，仍要求在一次动画时长附近结束。重复点击若重启动画会超时。
  final frame_count = ((Style.scroll_to_reading_section_duration_ms + 64) / 16)
      .ceil();
  for (var frame = 0; frame < frame_count; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
    reader.expect_content_kept();
    offsets.add(scroll.offset);
    if (repeat_press && (frame == 8 || frame == 9)) {
      on_read();
      reader.expect_content_kept();
    }
  }
  expect(scroll.position.isScrollingNotifier.value, isFalse);
  expect(offsets.last, greaterThan(offsets.first));
  expect(
    offsets
        .where((offset) => offset > .5 && offset < offsets.last - .5)
        .toSet(),
    hasLength(greaterThanOrEqualTo(3)),
    reason: '入口必须出现连续滚动中间帧，不能直接跳到正文',
  );
  for (var index = 1; index < offsets.length; index++) {
    expect(offsets[index], greaterThanOrEqualTo(offsets[index - 1] - .5));
    expect(
      offsets[index] - offsets[index - 1],
      lessThan(offsets.last * .35),
      reason: '正文窗口和滚动范围不应在动画中途突变',
    );
  }
  expect(tester.takeException(), isNull);
  return offsets;
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storage;
  setUpAll(() async {
    storage = Directory.systemTemp.createTempSync('start_reading_scroll_');
    File('${storage.path}/GetStorage.gs').writeAsStringSync('{}');
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => storage.path,
    );
    await GetStorage('GetStorage', storage.path).initStorage;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (call) async => call.method == 'getAll' ? <String, Object>{} : true,
    );
    await EasyLocalization.ensureInitialized();
  });
  setUp(() {
    Get.testMode = true;
    Get.put(UserInformation());
    Get.put<DeviceInfo>(_Device());
    Get.put(ProjectConfigStore());
    Get.put<ReadAdFreeStore>(_AdFree());
  });
  tearDown(Get.reset);
  tearDownAll(() => storage.delete(recursive: true));

  testWidgets('长篇顶栏随当前章节变化显示章节标题', (tester) async {
    final reader = await _mount_reader(tester);
    String title() => tester.widget<ReadTopBar>(find.byType(ReadTopBar)).title;
    expect(title(), 'Chapter 1');
    reader.logic.current_chapter_index.value = 1;
    await tester.pump();
    expect(title(), 'Chapter 2');
    reader.logic.current_chapter_index.value = -1;
    await tester.pump();
    expect(title(), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('导航栏独立响应滚动方向，选词分享关闭后仍能再次上行展开', (tester) async {
    final reader = await _mount_reader(tester);
    final logic = reader.logic;
    final main_list = reader.main_list(tester);
    final progress = reader.state.reading_progress_percent;
    final offset = logic.scroll_controller.offset;

    Future<void> expect_bars(bool visible) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.widget<ReadTopBar>(find.byType(ReadTopBar)).show, visible);
      expect(
        tester.widget<ReadBottomBar>(find.byType(ReadBottomBar)).show,
        visible,
      );
      final top_bar_bottom = tester.getBottomLeft(find.byType(ReadTopBar)).dy;
      expect(top_bar_bottom, visible ? greaterThan(0) : lessThanOrEqualTo(0));
      expect(tester.takeException(), isNull);
    }

    logic.sync_scroll_offset(400);
    logic.on_scroll(409);
    await expect_bars(false);
    logic.on_scroll(400);
    await expect_bars(true);
    logic.on_scroll(409);
    await expect_bars(false);
    logic.on_scroll(400);
    await expect_bars(true);

    // 只改变方向状态，正文和进度均不刷新，避免掩盖缺失的 Rx 订阅。
    expect(reader.main_list(tester), same(main_list));
    expect(reader.state.reading_progress_percent, progress);
    expect(logic.scroll_controller.offset, offset);

    final item = logic.store.reading_items.firstWhere((item) => !item.is_title);
    main_list.on_paragraph_share!(
      item,
      TextSelection(baseOffset: 0, extentOffset: item.text.length),
    );
    await expect_bars(false);
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    logic.on_scroll(391);
    await expect_bars(true);
    expect(reader.state.reading_progress_percent, progress);
    expect(logic.scroll_controller.offset, offset);
  });

  testWidgets('真实长篇正文与封面切换时顶部遮罩保持挂载并连续淡入淡出', (tester) async {
    final reader = await _mount_reader(tester);
    final overlay = find.byType(PageTopGradientOverlay);
    final gradient = find.descendant(
      of: overlay,
      matching: find.byType(TopHeaderGradient),
    );
    double opacity() => tester
        .widget<FadeTransition>(
          find.descendant(of: overlay, matching: find.byType(FadeTransition)),
        )
        .opacity
        .value;
    final original_element = tester.element(gradient);
    expect(opacity(), 0);
    await _read_chapter_paragraph(tester, reader, 0);
    // 滚动在帧末报告正文状态，再一帧提交遮罩的新透明度目标。
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(opacity(), inExclusiveRange(0, 1));
    await tester.pump(const Duration(milliseconds: 300));
    expect(opacity(), 1);
    reader.logic.scroll_controller.jumpTo(0);
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(opacity(), inExclusiveRange(0, 1));
    await tester.pump(const Duration(milliseconds: 300));
    expect(opacity(), 0);
    expect(tester.element(gradient), same(original_element));
    reader.expect_content_kept();
    expect(tester.takeException(), isNull);
  });

  testWidgets('首次从头图开始阅读平滑进入第一章，连续点击不切章或重建窗口', (tester) async {
    final reader = await _mount_reader(tester);
    await _press_read_and_sample(tester, reader, repeat_press: true);
    expect(reader.logic.current_chapter_index.value, 0);
    expect(reader.state.has_started_reading, isTrue);
    expect(
      tester.getTopLeft(find.byKey(reader.logic.get_chapter_key(0))).dy,
      inInclusiveRange(0, 60),
    );
  });

  for (final chapter_index in [0, 1]) {
    testWidgets('第 ${chapter_index + 1} 章返回封面后续读恢复原进度，平滑滚动且保留全部已载章节', (
      tester,
    ) async {
      final reader = await _mount_reader(tester);
      await _read_chapter_paragraph(tester, reader, chapter_index);
      final reading_offset = reader.logic.scroll_controller.offset;
      final double reading_progress = reader.state.reading_progress_percent;
      final chapter_progress = reader.logic.calculate_chapter_progress_percent(
        reading_progress_percent: reading_progress,
        chapter_index: chapter_index,
      );
      expect(chapter_progress, inExclusiveRange(10, 90));

      reader.logic.scroll_controller.jumpTo(0);
      await tester.pump(const Duration(milliseconds: 16));
      expect(
        reader.state.has_started_reading,
        isFalse,
        reason:
            '封面第一章标题位置: '
            '${tester.getTopLeft(find.byKey(reader.logic.get_chapter_key(0))).dy}',
      );
      expect(reader.main_list(tester).continuing_listenable!.value, isTrue);
      reader.expect_content_kept();

      await _press_read_and_sample(tester, reader, repeat_press: true);
      expect(reader.logic.current_chapter_index.value, chapter_index);
      expect(reader.logic.scroll_controller.offset, closeTo(reading_offset, 1));
      expect(
        reader.state.reading_progress_percent,
        closeTo(reading_progress, .1),
      );
      expect(reader.state.has_started_reading, isTrue);
      expect(reader.page_key.currentState, same(reader.state));
    });
  }
}
