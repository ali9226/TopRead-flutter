// ignore_for_file: non_constant_identifier_names

import 'dart:io';

import 'package:app/pages/short_story_read/logic.dart';
import 'package:app/stores/short_story_catalog_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storage_directory;

  setUpAll(() async {
    storage_directory = Directory.systemTemp.createTempSync(
      'short_story_scroll_lifecycle_test_',
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => storage_directory.path,
    );
    await GetStorage('GetStorage', storage_directory.path).initStorage;
  });

  setUp(() {
    Get.testMode = true;
    Get.put(ShortStoryCatalogStore());
  });

  tearDown(() => Get.reset());
  tearDownAll(() async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    await storage_directory.delete(recursive: true);
  });

  /// 仅构造逻辑控制器，不初始化小说数据或发起网络请求。
  Future<ShortStoryReadLogic> create_logic(WidgetTester tester) async {
    final context_key = UniqueKey();
    await tester.pumpWidget(SizedBox(key: context_key));
    final logic = ShortStoryReadLogic(
      context: tester.element(find.byKey(context_key)),
      story_id: 1,
    );
    addTearDown(logic.dispose);
    return logic;
  }

  testWidgets('向下补偿保持栏位可见，后续手动滚动只累计真实位移', (tester) async {
    final logic = await create_logic(tester);
    logic.sync_scroll_offset(400);
    logic.on_scroll(405);

    logic.sync_scroll_offset(500);
    expect(logic.is_appbar_visible.value, isTrue);
    expect(logic.is_bottom_bar_visible.value, isTrue);

    logic.on_scroll(501);
    logic.on_scroll(508);
    expect(logic.is_appbar_visible.value, isTrue);
    expect(logic.is_bottom_bar_visible.value, isTrue);

    logic.on_scroll(509);
    expect(logic.is_appbar_visible.value, isFalse);
    expect(logic.is_bottom_bar_visible.value, isFalse);
  });

  testWidgets('向上补偿保持栏位隐藏，后续微小滚动不会把补偿识别为上滑', (tester) async {
    final logic = await create_logic(tester);
    logic.sync_scroll_offset(400);
    logic.on_scroll(409);
    expect(logic.is_appbar_visible.value, isFalse);
    expect(logic.is_bottom_bar_visible.value, isFalse);

    logic.sync_scroll_offset(300);
    expect(logic.is_appbar_visible.value, isFalse);
    expect(logic.is_bottom_bar_visible.value, isFalse);

    logic.on_scroll(299);
    logic.on_scroll(292);
    expect(logic.is_appbar_visible.value, isFalse);
    expect(logic.is_bottom_bar_visible.value, isFalse);

    logic.on_scroll(291);
    expect(logic.is_appbar_visible.value, isTrue);
    expect(logic.is_bottom_bar_visible.value, isTrue);
  });

  testWidgets('同步到顶部也只更新基准，不自动展开栏位', (tester) async {
    final logic = await create_logic(tester);
    logic.toggle_bars_visibility();

    logic.sync_scroll_offset(0);
    expect(logic.is_appbar_visible.value, isFalse);
    expect(logic.is_bottom_bar_visible.value, isFalse);
  });
}
