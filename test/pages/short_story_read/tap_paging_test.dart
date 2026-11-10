import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app/components/window_content_layout/index.dart';
import 'package:app/pages/short_story_read/logic.dart';
import 'package:app/pages/short_story_read/story_tap_paging.dart';
import 'package:app/pages/short_story_read/style.dart';
import 'package:app/pages/short_story_read/widgets/reader_overlay_layer.dart';
import 'package:app/pages/short_story_read/widgets/story_content_stack.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:app/stores/short_story_catalog_store.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class _Assets extends AssetLoader {
  const _Assets();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      Map<String, dynamic>.from(
        jsonDecode(File('$path/en.json').readAsStringSync()) as Map,
      );
}

/// TODO 使用真实短篇正文树和逻辑层，仅以本地文本替代网络加载。
class _Reader extends StatefulWidget {
  const _Reader({super.key, this.dark = false});
  final bool dark;

  @override
  State<_Reader> createState() => _ReaderState();
}

class _ReaderState extends State<_Reader> {
  final ScrollController scroll_controller = ScrollController();
  final GlobalKey body_start_key = GlobalKey();
  final GlobalKey story_end_key = GlobalKey();
  final ValueNotifier<bool> has_history = ValueNotifier(false);
  late final ShortStoryReadLogic logic;
  late final StoryTapPagingController paging;
  Offset? tap_position;
  Offset? last_pointer_position;
  int confirmed_taps = 0;

  @override
  void initState() {
    super.initState();
    logic = ShortStoryReadLogic(context: context, story_id: 1);
    logic.content.value = List<String>.generate(
      100,
      (index) =>
          'Paragraph $index. The moon rises above the distant mountains.',
    ).join('\n\n');
    logic.is_loading.value = false;
    logic.is_content_loading.value = false;
    logic.is_appbar_visible.value = false;
    logic.is_bottom_bar_visible.value = false;
    paging = StoryTapPagingController(scroll_controller: scroll_controller);
    scroll_controller.addListener(() {
      if (paging.is_scrolling) {
        logic.sync_scroll_offset(scroll_controller.offset);
      } else {
        logic.on_scroll(scroll_controller.offset);
      }
    });
  }

  @override
  void dispose() {
    paging.cancel();
    scroll_controller.dispose();
    has_history.dispose();
    logic.dispose();
    super.dispose();
  }

  void hide_at(double offset) {
    scroll_controller.jumpTo(offset);
    logic.sync_scroll_offset(offset);
    logic.is_appbar_visible.value = false;
    logic.is_bottom_bar_visible.value = false;
  }

  void on_content_tap() {
    confirmed_taps++;
    final Offset? position = tap_position;
    tap_position = null;
    if (!logic.is_appbar_visible.value &&
        !logic.is_bottom_bar_visible.value &&
        position != null &&
        paging.should_page_up(
          position: position,
          body_start_key: body_start_key,
        )) {
      unawaited(
        paging.scroll_page_up(
          sync_scroll_offset: logic.sync_scroll_offset,
          disable_animations: MediaQuery.disableAnimationsOf(context),
        ),
      );
    } else {
      logic.toggle_bars_visibility();
    }
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: (notification) => paging.on_scroll_notification(
          notification,
          on_pull_at_start: logic.on_scroll,
        ),
        child: Obx(
          () => StoryContentStack(
            status_bar_height: 0,
            bottom_padding: 0,
            theme: StoryContentTheme(
              is_dark: widget.dark,
              is_cjk: false,
              bg_color: widget.dark ? Colors.black : Colors.white,
              title_color: widget.dark ? Colors.white : Colors.black,
              title_font_size: 20,
            ),
            state: StoryContentState(
              logic: logic,
              generation: 0,
              scroll_controller: scroll_controller,
              reader_scroll_physics: const ClampingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              page_transition_controller: const AlwaysStoppedAnimation(0),
              bottom_bar_slide_animation: AlwaysStoppedAnimation(
                logic.is_bottom_bar_visible.value
                    ? Offset.zero
                    : const Offset(0, 1),
              ),
              floating_button_fade_animation: const AlwaysStoppedAnimation(0),
              is_slide_up: true,
              previous_pull_offset: 0,
              next_pull_offset: 0,
              next_story_overlay_opacity: 0,
              body_start_key: body_start_key,
              story_end_key: story_end_key,
              next_story_title_key: GlobalKey(),
              has_reading_history: has_history,
              is_paragraph_selection_active: false,
              is_video_ad_gate_required: false,
              is_rewarded_ad_loading: false,
              native_ad_slot: null,
              native_ad_insert_index: null,
              show_floating_button: false,
            ),
            actions: StoryContentActions(
              on_content_tap: on_content_tap,
              on_pointer_down: (position) {
                tap_position = position;
                last_pointer_position = position;
              },
              on_pointer_move: (_) {},
              on_pointer_end: () {},
              on_viewport_resize_start: () {},
              on_viewport_resize_end: () {},
              on_layout_pending: () {},
              on_extent_changed: (_, _) {},
              on_read_story: () {},
              on_cover_replaced: (_, _, _) {},
              on_back: () {},
              on_favorite: () async {},
              on_share: () {},
              on_comment: ({int scroll_to_comment_id = 0}) async {},
              on_paragraph_comment: (_, _) async {},
              on_paragraph_share: (_, _) {},
              on_paragraph_selection_changed: (_) {},
              on_comment_count_tap: (_, _, _) {},
              on_unlock: () {},
              on_previous_tap: () {},
              on_next_tap: () {},
              on_progress_changed: (_) {},
              on_progress_change_end: (_, complete) => complete(),
              on_scroll_to_bottom: () {},
              on_auto_read_settings_tap: () {},
              on_catalog_tap: () {},
              on_like_tap: () async {},
              on_setting_tap: () async {},
              schedule_next_story_overlay_update: () {},
              reader_text: (key) => key,
            ),
          ),
        ),
      );
}

Future<_ReaderState> _mount(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  bool dark = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  final key = GlobalKey<_ReaderState>();
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      startLocale: const Locale('en'),
      fallbackLocale: const Locale('en'),
      path: 'assets/i18n',
      saveLocale: false,
      assetLoader: const _Assets(),
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          theme: ThemeData(
            brightness: dark ? Brightness.dark : Brightness.light,
          ),
          home: WindowLayoutScope(
            child: Scaffold(
              body: _Reader(key: key, dark: dark),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return key.currentState!;
}

void _expect_hidden(WidgetTester tester, _ReaderState reader) {
  expect(reader.logic.is_appbar_visible.value, isFalse);
  expect(reader.logic.is_bottom_bar_visible.value, isFalse);
  final overlay = tester.widget<ReaderOverlayLayer>(
    find.byType(ReaderOverlayLayer),
  );
  expect(overlay.is_appbar_visible, isFalse);
  expect(overlay.is_bottom_bar_visible, isFalse);
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storage_directory;

  setUpAll(() async {
    storage_directory = Directory.systemTemp.createTempSync(
      'short_story_tap_paging_',
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => storage_directory.path,
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (_) async => <String, Object>{},
    );
    await GetStorage('GetStorage', storage_directory.path).initStorage;
    await EasyLocalization.ensureInitialized();
  });
  setUp(() {
    Get.testMode = true;
    Get.put(ShortStoryCatalogStore());
    Get.put(ProjectConfigStore());
  });
  tearDown(Get.reset);
  tearDownAll(() async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      null,
    );
    await storage_directory.delete(recursive: true);
  });

  for (final size in [const Size(390, 844), const Size(844, 390)]) {
    testWidgets('真实短篇正文上三分区确认单击会翻上一屏，全程保持双栏隐藏 $size', (tester) async {
      final reader = await _mount(
        tester,
        size: size,
        dark: size.width > size.height,
      );
      reader.hide_at(1800);
      await tester.pumpAndSettle();
      final scroll = find.byType(SingleChildScrollView);
      expect(scroll, findsOneWidget);
      final rect = tester.getRect(scroll);
      final tap = Offset(
        rect.left + rect.width * 0.3,
        rect.top + rect.height * 0.2,
      );
      final expected_offset =
          1800 - (rect.height - ShortStoryReadStyle.page_scroll_overlap);
      await tester.tapAt(tap);
      expect(reader.last_pointer_position, tap);
      expect(reader.confirmed_taps, 1);
      await tester.pump();
      for (var frame = 0; frame < 5; frame++) {
        await tester.pump(const Duration(milliseconds: 80));
        _expect_hidden(tester, reader);
      }
      expect(reader.scroll_controller.offset, closeTo(expected_offset, 0.01));
      expect(reader.paging.is_scrolling, isFalse);

      await tester.dragFrom(
        Offset(rect.left + 24, rect.center.dy),
        const Offset(0, 80),
      );
      await tester.pumpAndSettle();
      expect(reader.logic.is_appbar_visible.value, isTrue);
      expect(reader.logic.is_bottom_bar_visible.value, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('上一屏到零偏移仍隐藏双栏，随后下拉可正常显示', (tester) async {
    final reader = await _mount(tester);
    reader.hide_at(200);
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.byType(SingleChildScrollView));
    await tester.tapAt(Offset(rect.left + 24, rect.top + 90));
    await tester.pumpAndSettle();
    expect(reader.scroll_controller.offset, 0);
    _expect_hidden(tester, reader);
    await tester.dragFrom(
      Offset(rect.left + 24, rect.center.dy),
      const Offset(0, 90),
    );
    await tester.pumpAndSettle();
    expect(reader.scroll_controller.offset, 0);
    expect(reader.logic.is_appbar_visible.value, isTrue);
    expect(reader.logic.is_bottom_bar_visible.value, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('动画途中手动下拉接管后立即显示双栏', (tester) async {
    final reader = await _mount(tester);
    reader.hide_at(1800);
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.byType(SingleChildScrollView));
    await tester.tapAt(Offset(rect.left + 24, rect.top + 90));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    _expect_hidden(tester, reader);
    expect(reader.paging.is_scrolling, isTrue);
    await tester.dragFrom(
      Offset(rect.left + 24, rect.center.dy),
      const Offset(0, 100),
    );
    await tester.pumpAndSettle();
    expect(reader.paging.is_scrolling, isFalse);
    expect(reader.logic.is_appbar_visible.value, isTrue);
    expect(reader.logic.is_bottom_bar_visible.value, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('中间和底部单击保留双栏切换语义，不触发上一屏', (tester) async {
    final reader = await _mount(tester);
    final rect = tester.getRect(find.byType(SingleChildScrollView));
    for (final fraction in [0.5, 0.75]) {
      reader.hide_at(1800);
      await tester.pumpAndSettle();
      await tester.tapAt(
        Offset(rect.left + 24, rect.top + rect.height * fraction),
      );
      await tester.pumpAndSettle();
      expect(reader.scroll_controller.offset, 1800);
      expect(reader.logic.is_appbar_visible.value, isTrue);
      expect(reader.logic.is_bottom_bar_visible.value, isTrue);
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
