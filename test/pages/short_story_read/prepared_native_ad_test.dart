// ignore_for_file: non_constant_identifier_names

import 'package:app/components/inline_native_ad/prepared_slot.dart';
import 'package:app/components/inline_native_ad/style.dart';
import 'package:app/pages/short_story_read/style.dart';
import 'package:app/pages/short_story_read/utils/resolve_story_native_ad_insert_index.dart';
import 'package:app/pages/short_story_read/widgets/native_ad_banner.dart';
import 'package:app/pages/short_story_read/widgets/story_content.dart';
import 'package:app/pages/short_story_read/widgets/story_unlock_gate/index.dart';
import 'package:app/util/native_ad_insert_index.dart';
import 'package:app/util/split_story_paragraphs.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 只模拟 SDK 的素材与尺寸回调，不创建 Google 广告或平台视图。
class _AdProbe {
  static const double card_height = 240;
  static const double reserved_extent =
      InlineNativeAdStyle.spacing_top +
      card_height +
      InlineNativeAdStyle.spacing_bottom;

  late ValueChanged<NativeAdLoadStatus> on_load_status_changed;
  late ValueChanged<double> on_layout_height_changed;
  late VoidCallback on_ad_attached;

  int request_count = 0;
  bool is_disposed = false;
  bool attach_ad = false;
  bool reserve_space = false;
  final List<double> committed_extents = <double>[];

  Widget builder(
    BuildContext context, {
    required bool attach_ad,
    required bool reserve_space,
    required ValueChanged<NativeAdLoadStatus> on_load_status_changed,
    required ValueChanged<double> on_layout_height_changed,
    required VoidCallback on_ad_attached,
  }) {
    this.attach_ad = attach_ad;
    this.reserve_space = reserve_space;
    this.on_load_status_changed = on_load_status_changed;
    this.on_layout_height_changed = on_layout_height_changed;
    this.on_ad_attached = on_ad_attached;
    return _FakeNativeAd(probe: this, reserve_space: reserve_space);
  }
}

/// 记录预加载实例的创建与销毁，尺寸与真实广告卡片使用同一间距。
class _FakeNativeAd extends StatefulWidget {
  final _AdProbe probe;
  final bool reserve_space;

  const _FakeNativeAd({required this.probe, required this.reserve_space});

  @override
  State<_FakeNativeAd> createState() => _FakeNativeAdState();
}

class _FakeNativeAdState extends State<_FakeNativeAd> {
  @override
  void initState() {
    super.initState();
    widget.probe.request_count++;
  }

  @override
  void dispose() {
    widget.probe.is_disposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: widget.reserve_space ? _AdProbe.reserved_extent : 0);
}

class _ReaderAssetLoader extends AssetLoader {
  const _ReaderAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {
    'short_story_read': {
      'locked_remaining_words': '{count} words remaining',
      'watch_ad_to_continue': 'Watch ad to continue',
    },
  };
}

/// 每段使用唯一前缀，确保预览截断与广告位置都能从真实正文定位。
String _story_content({int paragraph_count = 24, int word_count = 80}) =>
    List<String>.generate(
      paragraph_count,
      (index) =>
          'Paragraph $index ${List.filled(word_count, 'continues').join(' ')}.',
    ).join('\n');

/// 使用真实短篇解锁组件和正文布局，广告只替换 SDK 实例。
Future<void> _pump_reader(
  WidgetTester tester, {
  required ScrollController scroll_controller,
  required _AdProbe probe,
  required String content,
  int story_id = 1,
  bool is_unlocked = false,
  bool is_dark = false,
  VoidCallback? on_unlock,
  Key? native_ad_key,
  bool is_ad_enabled = true,
  int? native_ad_insert_index,
}) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/i18n',
      assetLoader: const _ReaderAssetLoader(),
      startLocale: const Locale('en'),
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 400,
                height: 500,
                child: SingleChildScrollView(
                  key: const ValueKey('reader_viewport'),
                  controller: scroll_controller,
                  padding: const EdgeInsets.all(24),
                  child: StoryUnlockGate(
                    key: ValueKey(story_id),
                    content: content,
                    is_dark: is_dark,
                    is_loading: false,
                    is_unlocked: is_unlocked,
                    is_unlocking: false,
                    native_ad_insert_index: native_ad_insert_index,
                    font_size: 18,
                    on_unlock: on_unlock ?? () {},
                    native_ad_widget: PreparedNativeAdSlot(
                      key: native_ad_key ?? ValueKey('native_ad_$story_id'),
                      scroll_controller: scroll_controller,
                      is_enabled: is_ad_enabled,
                      on_extent_changed: probe.committed_extents.add,
                      builder: probe.builder,
                    ),
                  ),
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

/// 在树里获得真实预览段落，避免用全文位置猜测锁定正文的广告锚点。
List<String> _rendered_paragraphs(WidgetTester tester) =>
    split_story_paragraphs(
      tester.widget<StoryContent>(find.byType(StoryContent)).content,
    ).map((paragraph) => paragraph.text).toList(growable: false);

Finder _slot_finder(int story_id) =>
    find.byKey(ValueKey('native_ad_$story_id'));

Future<void> _prepare_ad(WidgetTester tester, _AdProbe probe) async {
  probe.on_layout_height_changed(_AdProbe.card_height);
  probe.on_load_status_changed(NativeAdLoadStatus.loaded);
  await tester.pumpAndSettle();
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

  testWidgets('广告准备期间不占高度，锁定预览的相邻正文保持连续', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final probe = _AdProbe();
    final content = _story_content();
    await _pump_reader(
      tester,
      scroll_controller: controller,
      probe: probe,
      content: content,
    );

    final paragraphs = _rendered_paragraphs(tester);
    final insert_index = resolve_native_ad_insert_index(
      paragraph_count: paragraphs.length,
      has_native_ad: true,
      display_ratio: ShortStoryReadStyle.native_ad_display_ratio,
    )!;
    final previous = tester.getRect(find.text(paragraphs[insert_index - 1]));
    final following = tester.getRect(find.text(paragraphs[insert_index]));
    expect(tester.getSize(_slot_finder(1)).height, 0);
    expect(
      following.top - previous.bottom,
      closeTo(ShortStoryReadStyle.paragraph_spacing, 0.01),
    );
    expect(probe.request_count, 1);
    expect(probe.reserve_space, isFalse);
    expect(probe.attach_ad, isFalse);
    expect(probe.committed_extents, isEmpty);
    expect(
      find.byKey(const ValueKey('story_unlock_gradient_overlay')),
      findsOneWidget,
    );
    expect(find.text(content.split('\n').last), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('先滑过锚点再到达的广告永久跳过，回滑不插入正文', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final probe = _AdProbe();
    await _pump_reader(
      tester,
      scroll_controller: controller,
      probe: probe,
      content: _story_content(),
      is_unlocked: true,
    );

    final anchor_top = tester.getTopLeft(_slot_finder(1)).dy;
    controller.jumpTo(anchor_top + _AdProbe.card_height);
    await tester.pumpAndSettle();
    final offset_before_ad = controller.offset;
    await _prepare_ad(tester, probe);
    expect(controller.offset, offset_before_ad);
    expect(tester.getSize(_slot_finder(1)).height, 0);
    expect(probe.is_disposed, isTrue);
    expect(probe.committed_extents, isEmpty);

    controller.jumpTo(0);
    await tester.pumpAndSettle();
    expect(tester.getSize(_slot_finder(1)).height, 0);
    expect(probe.request_count, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('素材与尺寸都就绪才在视口下方提交，卡片进入屏幕后挂载', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final probe = _AdProbe();
    await _pump_reader(
      tester,
      scroll_controller: controller,
      probe: probe,
      content: _story_content(),
      is_dark: true,
    );

    final anchor_top = tester.getTopLeft(_slot_finder(1)).dy;
    final viewport = tester.getRect(
      find.byKey(const ValueKey('reader_viewport')),
    );
    expect(
      anchor_top,
      greaterThan(
        viewport.bottom + InlineNativeAdStyle.insertion_safety_spacing,
      ),
    );
    probe.on_layout_height_changed(_AdProbe.card_height);
    await tester.pumpAndSettle();
    expect(tester.getSize(_slot_finder(1)).height, 0);
    expect(probe.committed_extents, isEmpty);

    probe.on_load_status_changed(NativeAdLoadStatus.loaded);
    await tester.pumpAndSettle();
    expect(tester.getSize(_slot_finder(1)).height, _AdProbe.reserved_extent);
    expect(probe.committed_extents, [_AdProbe.reserved_extent]);
    expect(probe.reserve_space, isTrue);
    expect(probe.attach_ad, isFalse);
    expect(controller.offset, 0);

    controller.jumpTo(anchor_top - viewport.bottom + 48);
    await tester.pumpAndSettle();
    expect(probe.attach_ad, isTrue);
    expect(probe.committed_extents, [_AdProbe.reserved_extent]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('同配置切换故事时使用新 key，清除上一篇错过广告的状态', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final content = _story_content();
    final first_probe = _AdProbe();
    await _pump_reader(
      tester,
      scroll_controller: controller,
      probe: first_probe,
      content: content,
      is_unlocked: true,
    );
    controller.jumpTo(
      tester.getTopLeft(_slot_finder(1)).dy + _AdProbe.card_height,
    );
    await tester.pumpAndSettle();
    expect(first_probe.is_disposed, isTrue);

    controller.jumpTo(0);
    final second_probe = _AdProbe();
    await _pump_reader(
      tester,
      scroll_controller: controller,
      probe: second_probe,
      content: content,
      story_id: 2,
      is_unlocked: true,
    );
    expect(second_probe.request_count, 1);
    expect(second_probe.is_disposed, isFalse);
    await _prepare_ad(tester, second_probe);
    expect(tester.getSize(_slot_finder(2)).height, _AdProbe.reserved_extent);
    expect(second_probe.committed_extents, [_AdProbe.reserved_extent]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('同一广告的 GlobalKey 跨预览和全文父树保留实例与已提交高度', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final probe = _AdProbe();
    final ad_key = GlobalKey();
    final content = _story_content();
    await _pump_reader(
      tester,
      scroll_controller: controller,
      probe: probe,
      content: content,
      native_ad_key: ad_key,
    );
    await _prepare_ad(tester, probe);
    expect(tester.getSize(find.byKey(ad_key)).height, _AdProbe.reserved_extent);
    final ad_state = tester.state(find.byKey(ad_key));

    await _pump_reader(
      tester,
      scroll_controller: controller,
      probe: probe,
      content: content,
      native_ad_key: ad_key,
      is_unlocked: true,
    );
    expect(identical(tester.state(find.byKey(ad_key)), ad_state), isTrue);
    expect(probe.request_count, 1);
    expect(probe.is_disposed, isFalse);
    expect(probe.committed_extents, [_AdProbe.reserved_extent]);
    expect(tester.getSize(find.byKey(ad_key)).height, _AdProbe.reserved_extent);
    expect(
      find.byKey(const ValueKey('story_unlock_gradient_overlay')),
      findsNothing,
    );
    expect(find.text(content.split('\n').last), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('原生广告加载失败不解除视频锁定，观看入口仍可点击', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final probe = _AdProbe();
    final content = _story_content();
    int unlock_requests = 0;
    await _pump_reader(
      tester,
      scroll_controller: controller,
      probe: probe,
      content: content,
      on_unlock: () => unlock_requests++,
    );
    probe.on_load_status_changed(NativeAdLoadStatus.failed);
    await tester.pumpAndSettle();

    expect(probe.is_disposed, isTrue);
    expect(tester.getSize(_slot_finder(1)).height, 0);
    expect(find.text(content.split('\n').last), findsNothing);
    expect(
      find.byKey(const ValueKey('story_unlock_gradient_overlay')),
      findsOneWidget,
    );
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Watch ad to continue'));
    expect(unlock_requests, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('奖励解锁全文后广告保留原段落边界，安全收回屏上方高度不跳段', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final probe = _AdProbe();
    final ad_key = GlobalKey();
    final content = _story_content();
    final insert_index = resolve_story_native_ad_insert_index(
      content: content,
      is_unlocked: false,
      is_cjk: false,
    )!;
    final full_insert_index = resolve_story_native_ad_insert_index(
      content: content,
      is_unlocked: true,
      is_cjk: false,
    )!;
    expect(full_insert_index, greaterThan(insert_index));

    await _pump_reader(
      tester,
      scroll_controller: controller,
      probe: probe,
      content: content,
      native_ad_key: ad_key,
      native_ad_insert_index: insert_index,
    );
    await _prepare_ad(tester, probe);
    final current_paragraph = _rendered_paragraphs(tester)[insert_index + 1];
    controller.jumpTo(tester.getTopLeft(find.text(current_paragraph)).dy - 160);
    await tester.pumpAndSettle();
    final paragraph_top_before = tester
        .getTopLeft(find.text(current_paragraph))
        .dy;
    final offset_before = controller.offset;
    final slot_state = tester.state(find.byKey(ad_key));
    expect(tester.getRect(find.byKey(ad_key)).bottom, lessThan(0));

    await _pump_reader(
      tester,
      scroll_controller: controller,
      probe: probe,
      content: content,
      native_ad_key: ad_key,
      native_ad_insert_index: insert_index,
      is_unlocked: true,
      is_ad_enabled: false,
    );

    expect(identical(tester.state(find.byKey(ad_key)), slot_state), isTrue);
    expect(probe.request_count, 1);
    expect(probe.is_disposed, isTrue);
    expect(probe.committed_extents, [_AdProbe.reserved_extent, 0]);
    expect(tester.getSize(find.byKey(ad_key)).height, 0);
    expect(
      controller.offset,
      closeTo(offset_before - _AdProbe.reserved_extent, 0.01),
    );
    expect(
      tester.getTopLeft(find.text(current_paragraph)).dy,
      closeTo(paragraph_top_before, 0.01),
    );
    expect(find.text(content.split('\n').last), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('全文满足广告段落数但锁定预览不足四段时不请求原生广告', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final probe = _AdProbe();
    final content = _story_content(paragraph_count: 4);
    expect(can_insert_native_ad(content), isTrue);
    await _pump_reader(
      tester,
      scroll_controller: controller,
      probe: probe,
      content: content,
    );

    expect(_rendered_paragraphs(tester).length, lessThan(4));
    expect(find.byType(PreparedNativeAdSlot), findsNothing);
    expect(probe.request_count, 0);
    expect(probe.committed_extents, isEmpty);
    expect(
      find.byKey(const ValueKey('story_unlock_gradient_overlay')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('固定广告边界超出变短后的正文时省略广告，不搬到新的段落', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final probe = _AdProbe();
    final content = _story_content(paragraph_count: 4);
    await _pump_reader(
      tester,
      scroll_controller: controller,
      probe: probe,
      content: content,
      is_unlocked: true,
      native_ad_insert_index: 8,
    );

    expect(_rendered_paragraphs(tester).length, 4);
    expect(find.byType(PreparedNativeAdSlot), findsNothing);
    expect(probe.request_count, 0);
    expect(probe.committed_extents, isEmpty);
    expect(find.text(content.split('\n').last), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
