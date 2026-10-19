// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';

import 'package:app/api/results_type.dart';
import 'package:app/components/window_content_layout/index.dart';
import 'package:app/models/novel_info.dart';
import 'package:app/pages/read/index.dart';
import 'package:app/pages/read/logic.dart';
import 'package:app/pages/read/utils/chapter_cache.dart';
import 'package:app/pages/read/widgets/navigation_bars/bottom/index.dart';
import 'package:app/pages/read/widgets/reading_settings_sheet/index.dart';
import 'package:app/stores/device_info.dart';
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

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storage;
  setUpAll(() async {
    storage = Directory.systemTemp.createTempSync('fold_auto_read_');
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

  testWidgets('真实长篇自动阅读在折叠锚点恢复期间不把重排边界当作章末，恢复后继续', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(466, 678);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final namespace = DateTime.now().microsecondsSinceEpoch;
    final chapter_ids = ['$namespace-0', '$namespace-1', '$namespace-2'];
    final logic = Logic(
      story_id: 7001,
      story_title: 'Folded reading',
      initial_body_font_size: 18,
      initial_auto_read_speed: .2,
      novel_info_loader: (_) async => _success(
        NovelInfo.from_json({
          'id': '7001',
          'title': 'Folded reading',
          'language_info': {
            'id': '71',
            'title': 'Folded reading',
            'word_count': 18000,
          },
        }),
      ),
      chapter_directory_loader: (_) async => _success([
        for (var index = 0; index < 3; index++)
          NovelChapterInfo.from_json({
            'id': chapter_ids[index],
            'novel_language_id': '71',
            'chapter_no': index + 1,
            'title': 'Chapter ${index + 1}',
            'word_count': 6000,
          }),
      ]),
      chapter_content_loader: (_) async => List.filled(
        65,
        'The reader keeps the same chapter and position as the window changes. '
        'Every paragraph wraps naturally at its new width without scaling the text.',
      ).join('\n'),
      chapter_paragraph_metadata_loader: (_, {required novel_id}) async => null,
    );
    // 只把磁盘缓存与本地加载器置于真实异步区；页面、Ticker和折叠重排仍走真实帧。
    await tester.runAsync(() async {
      await logic.fetch_info();
      final generation = await logic.jump_to_chapter(2);
      if (generation != null) logic.complete_chapter_jump(generation);
    });
    // 本回归固定已加载的章节窗口；上一章预取保持在进行中，避免另一笔插章事务干扰。
    logic.is_loading_prev = true;
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
            home: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.only(right: 84, bottom: 34),
                viewPadding: const EdgeInsets.only(right: 84, bottom: 34),
              ),
              child: WindowLayoutScope(
                max_width: 760,
                child: ReadPage(
                  key: page_key,
                  story_id: 7001,
                  story_title: 'Folded reading',
                  controller: logic,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // 真实页面包含持续的装饰动画，使用有限真实帧等待初始化，不能等全局动画静止。
    for (var frame = 0; frame < 12; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(logic.is_loading.value, isFalse);
    expect(logic.loaded_chapter_index, 2);
    final scroll = logic.scroll_controller;
    scroll.jumpTo(scroll.position.maxScrollExtent * .93);
    await tester.pump(const Duration(milliseconds: 100));
    final dynamic state = page_key.currentState!;
    expect(state.has_started_reading, isTrue);
    final chapter_before = logic.current_chapter_index.value;
    expect(chapter_before, 2);

    // 使用真实页面底栏和设置回调启动生产Ticker，测试不复制自动阅读算法。
    tester.widget<ReadBottomBar>(find.byType(ReadBottomBar)).on_setting_tap();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    tester
        .widget<ReadSettingsSheet>(find.byType(ReadSettingsSheet))
        .on_auto_read();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(logic.is_auto_reading.value, isTrue);
    final old_max = scroll.position.maxScrollExtent;
    final old_offset = scroll.offset;
    final double progress_before = state.reading_progress_percent;

    tester.view.physicalSize = const Size(669, 951);
    await tester.pump(const Duration(milliseconds: 16));
    expect(scroll.position.maxScrollExtent, lessThan(old_offset));
    expect(scroll.position.maxScrollExtent, lessThan(old_max));
    // 恢复方法会等待稳定帧；这帧旧offset正在新边界附近，不能结束自动阅读。
    await tester.pump(const Duration(milliseconds: 16));
    expect(logic.is_auto_reading.value, isTrue);
    for (var frame = 0; frame < 8; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(page_key.currentState, same(state));
    expect(state.needs_restore_scroll_position, isFalse);
    expect(logic.current_chapter_index.value, chapter_before);
    expect(logic.is_auto_reading.value, isTrue);
    expect(state.reading_progress_percent, closeTo(progress_before, 1));
    final restored_offset = scroll.offset;
    await tester.pump(const Duration(milliseconds: 200));
    expect(scroll.offset, greaterThan(restored_offset));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.runAsync(() async {
      for (final id in chapter_ids) {
        await ChapterCache.clear(id);
      }
    });
  });
}
