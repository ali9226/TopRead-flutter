import 'package:app/components/inline_native_ad/prepared_slot.dart';
import 'package:app/pages/short_story_read/widgets/native_ad_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 对外暴露监听状态，验证组件替换与销毁不会遗留滚动回调。
class _TrackingScrollController extends ScrollController {
  bool get has_registered_listeners => hasListeners;
}

/// 使用确定尺寸代替平台广告，测试准备、排版和挂载门禁。
class _AdProbe {
  static const double card_height = 300;
  static const double leading_extent = 12;
  static const double trailing_extent = 16;
  static const double reserved_extent =
      card_height + leading_extent + trailing_extent;
  static const double reloaded_card_height = 400;
  static const double reloaded_reserved_extent =
      reloaded_card_height + leading_extent + trailing_extent;

  /// 当前 SDK 已测量的素材高度，可独立于父组件尚未提交的占位高度。
  double measured_card_height = card_height;

  /// 保存组件提供的回调，可模拟真实 SDK 回调的任意到达顺序。
  late ValueChanged<NativeAdLoadStatus> on_load_status_changed;
  late ValueChanged<double> on_layout_height_changed;
  late VoidCallback on_ad_attached;

  /// 最近一次传给广告组件的展示策略。
  bool attach_ad = false;
  bool reserve_space = false;
  bool is_disposed = false;

  /// 记录实际允许挂载的构建时刻，防止下一帧复检掩盖短暂屏外挂载。
  final List<double> attach_card_positions = <double>[];

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
    if (attach_ad) {
      final RenderObject? render_object = context.findRenderObject();
      if (render_object is RenderBox && render_object.hasSize) {
        attach_card_positions.add(
          render_object.localToGlobal(Offset.zero).dy + leading_extent,
        );
      }
    }
    return _FakeNativeAd(probe: this, reserve_space: reserve_space);
  }
}

/// 记录被跳过或销毁的广告是否停止存在于树中。
class _FakeNativeAd extends StatefulWidget {
  final _AdProbe probe;
  final bool reserve_space;

  const _FakeNativeAd({required this.probe, required this.reserve_space});

  @override
  State<_FakeNativeAd> createState() => _FakeNativeAdState();
}

class _FakeNativeAdState extends State<_FakeNativeAd> {
  @override
  void dispose() {
    widget.probe.is_disposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.reserve_space) return const SizedBox.shrink();
    return SizedBox(
      height:
          widget.probe.measured_card_height +
          _AdProbe.leading_extent +
          _AdProbe.trailing_extent,
      child: const Column(
        children: <Widget>[
          SizedBox(height: _AdProbe.leading_extent),
          Expanded(child: SizedBox(key: Key('prepared_card'))),
          SizedBox(height: _AdProbe.trailing_extent),
        ],
      ),
    );
  }
}

/// 安排可控正文长度，使插位前后几何位置可以直接比较。
Future<void> _pump_reader(
  WidgetTester tester,
  ScrollController scroll_controller,
  _AdProbe probe, {
  double prefix_height = 900,
  double viewport_top = 0,
  double viewport_height = 600,
  double viewport_top_inset = 0,
  bool use_list_view = false,
  bool is_enabled = true,
  double? initial_reserved_extent,
  bool resize_above_viewport = true,
  bool retain_attachment_offscreen = true,
  double preload_viewport_count = double.infinity,
  VoidCallback? on_skipped,
  ValueChanged<double>? on_extent_changed,
}) async {
  final Widget reading_content = Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      SizedBox(key: const Key('visible_text'), height: prefix_height),
      PreparedNativeAdSlot(
        key: const Key('prepared_slot'),
        scroll_controller: scroll_controller,
        builder: probe.builder,
        is_enabled: is_enabled,
        layout_revision: prefix_height,
        viewport_top_inset: viewport_top_inset,
        on_extent_changed: on_extent_changed,
        initial_reserved_extent: initial_reserved_extent,
        resize_above_viewport: resize_above_viewport,
        retain_attachment_offscreen: retain_attachment_offscreen,
        preload_viewport_count: preload_viewport_count,
        on_skipped: on_skipped,
      ),
      const SizedBox(key: Key('following_text'), height: 1400),
    ],
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: EdgeInsets.only(top: viewport_top),
          child: SizedBox(
            width: 400,
            height: viewport_height,
            child: use_list_view
                ? ListView(
                    controller: scroll_controller,
                    children: <Widget>[reading_content],
                  )
                : SingleChildScrollView(
                    controller: scroll_controller,
                    child: reading_content,
                  ),
          ),
        ),
      ),
    ),
  );
  await _flush_frames(tester);
}

/// 素材准备和滚动检查在帧末合并，推进到所有布局检查完成。
Future<void> _flush_frames(WidgetTester tester) async {
  await tester.pumpAndSettle();
}

Future<void> _prepare_ad(
  WidgetTester tester,
  _AdProbe probe, {
  double card_height = _AdProbe.card_height,
}) async {
  probe.measured_card_height = card_height;
  probe.on_load_status_changed(NativeAdLoadStatus.loaded);
  probe.on_layout_height_changed(card_height);
  await _flush_frames(tester);
}

/// 模拟连续两章广告，确保同帧重载时多个高度补偿可以累计。
Future<void> _pump_two_slot_reader(
  WidgetTester tester,
  ScrollController scroll_controller,
  _AdProbe first_probe,
  _AdProbe second_probe, {
  required bool use_list_view,
}) async {
  final Widget reading_content = Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      const SizedBox(height: 900),
      PreparedNativeAdSlot(
        key: const Key('first_slot'),
        scroll_controller: scroll_controller,
        builder: first_probe.builder,
      ),
      const SizedBox(height: 900),
      PreparedNativeAdSlot(
        key: const Key('second_slot'),
        scroll_controller: scroll_controller,
        builder: second_probe.builder,
      ),
      const SizedBox(key: Key('following_text'), height: 1400),
    ],
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 400,
          height: 600,
          child: use_list_view
              ? ListView(
                  controller: scroll_controller,
                  children: <Widget>[reading_content],
                )
              : SingleChildScrollView(
                  controller: scroll_controller,
                  child: reading_content,
                ),
        ),
      ),
    ),
  );
  for (final _AdProbe probe in <_AdProbe>[first_probe, second_probe]) {
    probe.on_load_status_changed(NativeAdLoadStatus.loaded);
    probe.on_layout_height_changed(_AdProbe.card_height);
  }
  await _flush_frames(tester);
}

void main() {
  testWidgets('瀑布流远处不创建广告，接近时准备，离开缓存范围释放监听组件', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final probe = _AdProbe();
    await _pump_reader(
      tester,
      controller,
      probe,
      prefix_height: 2000,
      retain_attachment_offscreen: false,
      preload_viewport_count: 1,
    );
    expect(find.byType(_FakeNativeAd), findsNothing);
    controller.jumpTo(1200);
    await _flush_frames(tester);
    expect(find.byType(_FakeNativeAd), findsOneWidget);
    await _prepare_ad(tester, probe);
    controller.jumpTo(3100);
    await _flush_frames(tester);
    expect(find.byType(_FakeNativeAd), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('prepared_slot'))).height,
      _AdProbe.reserved_extent,
    );
    controller.jumpTo(1200);
    await _flush_frames(tester);
    expect(find.byType(_FakeNativeAd), findsOneWidget);
    await _prepare_ad(tester, probe);
    expect(
      tester.getSize(find.byKey(const Key('prepared_slot'))).height,
      _AdProbe.reserved_extent,
    );
  });

  testWidgets('信息流广告离屏撤销挂载但保留尺寸，返回可见区域后恢复', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final probe = _AdProbe();
    await _pump_reader(
      tester,
      controller,
      probe,
      retain_attachment_offscreen: false,
    );
    await _prepare_ad(tester, probe);
    controller.jumpTo(313);
    await _flush_frames(tester);
    probe.on_ad_attached();
    expect(probe.attach_ad, isTrue);
    controller.jumpTo(1400);
    await _flush_frames(tester);
    expect(probe.attach_ad, isFalse);
    expect(
      tester.getSize(find.byKey(const Key('prepared_slot'))).height,
      _AdProbe.reserved_extent,
    );
    controller.jumpTo(500);
    await _flush_frames(tester);
    expect(probe.attach_ad, isTrue);
  });

  testWidgets('缓存广告在当前视口恢复时保留尺寸并重新校验首次挂载', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final probe = _AdProbe();
    await _pump_reader(
      tester,
      controller,
      probe,
      prefix_height: 300,
      initial_reserved_extent: _AdProbe.reserved_extent,
    );
    expect(
      tester.getSize(find.byKey(const Key('prepared_slot'))).height,
      _AdProbe.reserved_extent,
    );
    expect(probe.attach_ad, isFalse);
    await _prepare_ad(tester, probe);
    expect(probe.attach_ad, isTrue);
    expect(probe.is_disposed, isFalse);
  });

  testWidgets('瀑布流屏外上方重载不按单列高度补偿或重排可见卡片', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final probe = _AdProbe();
    await _pump_reader(tester, controller, probe, resize_above_viewport: false);
    await _prepare_ad(tester, probe);
    controller.jumpTo(313);
    await _flush_frames(tester);
    probe.on_ad_attached();
    controller.jumpTo(1400);
    await _flush_frames(tester);
    final position = tester.getTopLeft(find.byKey(const Key('following_text')));
    probe.on_load_status_changed(NativeAdLoadStatus.loading);
    await _prepare_ad(
      tester,
      probe,
      card_height: _AdProbe.reloaded_card_height,
    );
    expect(controller.offset, 1400);
    expect(
      tester.getSize(find.byKey(const Key('prepared_slot'))).height,
      _AdProbe.reserved_extent,
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('following_text'))),
      position,
    );
    controller.jumpTo(0);
    await _flush_frames(tester);
    expect(
      tester.getSize(find.byKey(const Key('prepared_slot'))).height,
      _AdProbe.reloaded_reserved_extent,
    );
  });

  testWidgets('错过的广告只通知一次，迟到回调不能重新创建广告位', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final probe = _AdProbe();
    int skipped_count = 0;
    await _pump_reader(
      tester,
      controller,
      probe,
      prefix_height: 300,
      on_skipped: () => skipped_count++,
    );
    expect(skipped_count, 1);
    expect(probe.is_disposed, isTrue);
    probe.on_load_status_changed(NativeAdLoadStatus.loaded);
    probe.on_layout_height_changed(_AdProbe.card_height);
    await _flush_frames(tester);
    expect(skipped_count, 1);
    expect(tester.getSize(find.byKey(const Key('prepared_slot'))).height, 0);
  });

  testWidgets('准备时零高，提前插入已准备广告不会挤动当前正文', (tester) async {
    final ScrollController scroll_controller = ScrollController();
    addTearDown(scroll_controller.dispose);
    final _AdProbe probe = _AdProbe();
    await _pump_reader(tester, scroll_controller, probe);
    final Offset initial_text_position = tester.getTopLeft(
      find.byKey(const Key('visible_text')),
    );

    probe.on_load_status_changed(NativeAdLoadStatus.loading);
    await _flush_frames(tester);
    expect(tester.getSize(find.byKey(const Key('prepared_slot'))).height, 0);
    expect(find.byKey(const Key('prepared_card')), findsNothing);
    expect(tester.getTopLeft(find.byKey(const Key('following_text'))).dy, 900);

    await _prepare_ad(tester, probe);
    expect(probe.reserve_space, isTrue);
    expect(probe.attach_ad, isFalse);
    expect(
      tester.getSize(find.byKey(const Key('prepared_slot'))).height,
      _AdProbe.reserved_extent,
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('following_text'))).dy,
      900 + _AdProbe.reserved_extent,
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('visible_text'))),
      initial_text_position,
    );
    expect(scroll_controller.offset, 0);
  });

  for (final bool layout_first in <bool>[false, true]) {
    testWidgets('素材和尺寸任意先后到达，二者齐备才预留高度：$layout_first', (tester) async {
      final ScrollController scroll_controller = ScrollController();
      addTearDown(scroll_controller.dispose);
      final _AdProbe probe = _AdProbe();
      final List<double> committed_extents = <double>[];
      await _pump_reader(
        tester,
        scroll_controller,
        probe,
        on_extent_changed: committed_extents.add,
      );
      expect(committed_extents, isEmpty);

      if (layout_first) {
        probe.on_layout_height_changed(_AdProbe.card_height);
      } else {
        probe.on_load_status_changed(NativeAdLoadStatus.loaded);
      }
      await _flush_frames(tester);
      expect(probe.reserve_space, isFalse);
      expect(probe.attach_ad, isFalse);
      expect(tester.getSize(find.byKey(const Key('prepared_slot'))).height, 0);
      expect(committed_extents, isEmpty);

      if (layout_first) {
        probe.on_load_status_changed(NativeAdLoadStatus.loaded);
      } else {
        probe.on_layout_height_changed(_AdProbe.card_height);
      }
      await _flush_frames(tester);
      expect(probe.reserve_space, isTrue);
      expect(probe.attach_ad, isFalse);
      expect(committed_extents, <double>[_AdProbe.reserved_extent]);

      probe.on_layout_height_changed(_AdProbe.card_height);
      probe.on_load_status_changed(NativeAdLoadStatus.loaded);
      await _flush_frames(tester);
      expect(committed_extents, <double>[_AdProbe.reserved_extent]);
    });
  }

  testWidgets('加载失败立即释放广告且不保留骨架高度', (tester) async {
    final ScrollController scroll_controller = ScrollController();
    addTearDown(scroll_controller.dispose);
    final _AdProbe probe = _AdProbe();
    final List<double> committed_extents = <double>[];
    await _pump_reader(
      tester,
      scroll_controller,
      probe,
      on_extent_changed: committed_extents.add,
    );

    probe.on_load_status_changed(NativeAdLoadStatus.loading);
    probe.on_load_status_changed(NativeAdLoadStatus.failed);
    await _flush_frames(tester);
    expect(probe.is_disposed, isTrue);
    expect(find.byType(_FakeNativeAd), findsNothing);
    expect(tester.getSize(find.byKey(const Key('prepared_slot'))).height, 0);
    expect(tester.getTopLeft(find.byKey(const Key('following_text'))).dy, 900);
    expect(committed_extents, isEmpty);
  });

  for (final double scroll_offset in <double>[225, 1100]) {
    testWidgets('慢加载靠近或快速越过插位时跳过，迟到素材不改变正文：$scroll_offset', (tester) async {
      final ScrollController scroll_controller = ScrollController();
      addTearDown(scroll_controller.dispose);
      final _AdProbe probe = _AdProbe();
      final List<double> committed_extents = <double>[];
      await _pump_reader(
        tester,
        scroll_controller,
        probe,
        on_extent_changed: committed_extents.add,
      );
      probe.on_load_status_changed(NativeAdLoadStatus.loading);
      await _flush_frames(tester);

      scroll_controller.jumpTo(scroll_offset);
      await _flush_frames(tester);
      final Offset following_position = tester.getTopLeft(
        find.byKey(const Key('following_text')),
      );
      expect(probe.is_disposed, isTrue);
      expect(find.byType(_FakeNativeAd), findsNothing);

      probe.on_load_status_changed(NativeAdLoadStatus.loaded);
      probe.on_layout_height_changed(_AdProbe.card_height);
      await _flush_frames(tester);
      expect(tester.getSize(find.byKey(const Key('prepared_slot'))).height, 0);
      expect(
        tester.getTopLeft(find.byKey(const Key('following_text'))),
        following_position,
      );
      expect(scroll_controller.offset, scroll_offset);
      expect(committed_extents, isEmpty);

      scroll_controller.jumpTo(0);
      await _flush_frames(tester);
      expect(find.byType(_FakeNativeAd), findsNothing);
      expect(tester.getSize(find.byKey(const Key('prepared_slot'))).height, 0);
      expect(committed_extents, isEmpty);
    });
  }

  testWidgets('卡片真正可见至少一像素才挂载，顶部留白不算广告可见', (tester) async {
    final ScrollController scroll_controller = ScrollController();
    addTearDown(scroll_controller.dispose);
    final _AdProbe probe = _AdProbe();
    await _pump_reader(tester, scroll_controller, probe);
    await _prepare_ad(tester, probe);

    scroll_controller.jumpTo(300);
    await _flush_frames(tester);
    expect(probe.attach_ad, isFalse);
    scroll_controller.jumpTo(312);
    await _flush_frames(tester);
    expect(tester.getTopLeft(find.byKey(const Key('prepared_card'))).dy, 600);
    expect(probe.attach_ad, isFalse);
    scroll_controller.jumpTo(313);
    await _flush_frames(tester);
    expect(tester.getTopLeft(find.byKey(const Key('prepared_card'))).dy, 599);
    expect(probe.attach_ad, isTrue);
  });

  testWidgets('挂载范围以真实阅读视口为准，应用栏下方留白不视为可见', (tester) async {
    final ScrollController scroll_controller = ScrollController();
    addTearDown(scroll_controller.dispose);
    final _AdProbe probe = _AdProbe();
    await _pump_reader(
      tester,
      scroll_controller,
      probe,
      viewport_top: 60,
      viewport_height: 480,
    );
    await _prepare_ad(tester, probe);

    scroll_controller.jumpTo(432);
    await _flush_frames(tester);
    expect(tester.getTopLeft(find.byKey(const Key('prepared_card'))).dy, 540);
    expect(probe.attach_ad, isFalse);
    scroll_controller.jumpTo(433);
    await _flush_frames(tester);
    expect(tester.getTopLeft(find.byKey(const Key('prepared_card'))).dy, 539);
    expect(probe.attach_ad, isTrue);
  });

  testWidgets('顶部浮层从安全区起算，广告仅处于遮挡区域时禁止首次挂载', (tester) async {
    tester.view.viewPadding = FakeViewPadding(
      top: 20 * tester.view.devicePixelRatio,
    );
    addTearDown(tester.view.resetViewPadding);
    final ScrollController scroll_controller = ScrollController();
    addTearDown(scroll_controller.dispose);
    final _AdProbe probe = _AdProbe();
    await _pump_reader(
      tester,
      scroll_controller,
      probe,
      viewport_top: 60,
      viewport_height: 480,
      viewport_top_inset: 400,
    );
    await _prepare_ad(tester, probe);

    scroll_controller.jumpTo(852);
    await _flush_frames(tester);
    expect(
      tester.getBottomLeft(find.byKey(const Key('prepared_card'))).dy,
      420,
    );
    expect(probe.attach_ad, isFalse);

    scroll_controller.jumpTo(851);
    await _flush_frames(tester);
    expect(
      tester.getBottomLeft(find.byKey(const Key('prepared_card'))).dy,
      421,
    );
    expect(probe.attach_ad, isTrue);
  });

  for (final bool use_list_view in <bool>[false, true]) {
    testWidgets('关闭屏外上方广告时补偿高度，当前正文保持原位：$use_list_view', (tester) async {
      final ScrollController scroll_controller = ScrollController();
      addTearDown(scroll_controller.dispose);
      final _AdProbe probe = _AdProbe();
      await _pump_reader(
        tester,
        scroll_controller,
        probe,
        use_list_view: use_list_view,
      );
      await _prepare_ad(tester, probe);
      scroll_controller.jumpTo(1400);
      await _flush_frames(tester);
      final Offset following_position = tester.getTopLeft(
        find.byKey(const Key('following_text')),
      );

      await _pump_reader(
        tester,
        scroll_controller,
        probe,
        use_list_view: use_list_view,
        is_enabled: false,
      );

      expect(probe.is_disposed, isTrue);
      expect(find.byType(_FakeNativeAd), findsNothing);
      expect(tester.getSize(find.byKey(const Key('prepared_slot'))).height, 0);
      expect(scroll_controller.offset, 1400 - _AdProbe.reserved_extent);
      expect(
        tester.getTopLeft(find.byKey(const Key('following_text'))),
        following_position,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('关闭当前可见广告先卸载素材，离屏后才收回高度：$use_list_view', (tester) async {
      final ScrollController scroll_controller = ScrollController();
      addTearDown(scroll_controller.dispose);
      final _AdProbe probe = _AdProbe();
      await _pump_reader(
        tester,
        scroll_controller,
        probe,
        use_list_view: use_list_view,
      );
      await _prepare_ad(tester, probe);
      scroll_controller.jumpTo(313);
      await _flush_frames(tester);
      probe.on_ad_attached();
      final Offset following_position = tester.getTopLeft(
        find.byKey(const Key('following_text')),
      );

      await _pump_reader(
        tester,
        scroll_controller,
        probe,
        use_list_view: use_list_view,
        is_enabled: false,
      );

      expect(probe.is_disposed, isTrue);
      expect(find.byType(_FakeNativeAd), findsNothing);
      expect(
        tester.getSize(find.byKey(const Key('prepared_slot'))).height,
        _AdProbe.reserved_extent,
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('following_text'))),
        following_position,
      );
      expect(scroll_controller.offset, 313);

      scroll_controller.jumpTo(1400);
      await _flush_frames(tester);
      expect(tester.getSize(find.byKey(const Key('prepared_slot'))).height, 0);
      expect(scroll_controller.offset, 1400 - _AdProbe.reserved_extent);
      expect(
        tester.getTopLeft(find.byKey(const Key('following_text'))).dy,
        900 + _AdProbe.reserved_extent - 1400,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('未就绪广告关闭后保持零高，迟到素材与重新开启不能复活：$use_list_view', (tester) async {
      final ScrollController scroll_controller = ScrollController();
      addTearDown(scroll_controller.dispose);
      final _AdProbe probe = _AdProbe();
      await _pump_reader(
        tester,
        scroll_controller,
        probe,
        use_list_view: use_list_view,
      );

      await _pump_reader(
        tester,
        scroll_controller,
        probe,
        use_list_view: use_list_view,
        is_enabled: false,
      );
      probe.on_load_status_changed(NativeAdLoadStatus.loaded);
      probe.on_layout_height_changed(_AdProbe.card_height);
      await _flush_frames(tester);
      await _pump_reader(
        tester,
        scroll_controller,
        probe,
        use_list_view: use_list_view,
      );

      expect(probe.is_disposed, isTrue);
      expect(find.byType(_FakeNativeAd), findsNothing);
      expect(tester.getSize(find.byKey(const Key('prepared_slot'))).height, 0);
      expect(
        tester.getTopLeft(find.byKey(const Key('following_text'))).dy,
        900,
      );
      expect(probe.attach_card_positions, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('首次高度批准后布局前越过锚点，撤销插入且正文不位移：$use_list_view', (tester) async {
      final ScrollController scroll_controller = ScrollController();
      addTearDown(scroll_controller.dispose);
      final _AdProbe probe = _AdProbe();
      await _pump_reader(
        tester,
        scroll_controller,
        probe,
        use_list_view: use_list_view,
      );

      probe.on_load_status_changed(NativeAdLoadStatus.loaded);
      probe.on_layout_height_changed(_AdProbe.card_height);
      // 当前帧末批准布局，广告的真实 RenderBox 仍是零高度。
      await tester.pump();
      expect(tester.getSize(find.byKey(const Key('prepared_slot'))).height, 0);
      scroll_controller.jumpTo(1100);
      await _flush_frames(tester);

      expect(tester.getSize(find.byKey(const Key('prepared_slot'))).height, 0);
      expect(
        tester.getTopLeft(find.byKey(const Key('following_text'))).dy,
        -200,
      );
      expect(scroll_controller.offset, 1100);
      expect(probe.is_disposed, isTrue);
      expect(probe.attach_card_positions, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('卡片进入视口后持续滚动，首次挂载不能一直被撤销：$use_list_view', (tester) async {
      final ScrollController scroll_controller = ScrollController();
      addTearDown(scroll_controller.dispose);
      final _AdProbe probe = _AdProbe();
      await _pump_reader(
        tester,
        scroll_controller,
        probe,
        use_list_view: use_list_view,
      );
      await _prepare_ad(tester, probe);

      scroll_controller.jumpTo(313);
      await tester.pump();
      expect(probe.attach_ad, isFalse);
      scroll_controller.jumpTo(320);
      await tester.pump();
      scroll_controller.jumpTo(330);
      await tester.pump();

      expect(probe.attach_card_positions, isNotEmpty);
      expect(probe.attach_ad, isTrue);
      expect(probe.attach_card_positions.every((top) => top < 600), isTrue);
      expect(
        probe.attach_card_positions.every(
          (top) => top + _AdProbe.card_height > 0,
        ),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('首次挂载批准后正文布局改动，禁止复用旧帧的可见门禁：$use_list_view', (tester) async {
      final ScrollController scroll_controller = ScrollController();
      addTearDown(scroll_controller.dispose);
      final _AdProbe probe = _AdProbe();
      await _pump_reader(
        tester,
        scroll_controller,
        probe,
        use_list_view: use_list_view,
      );
      await _prepare_ad(tester, probe);

      scroll_controller.jumpTo(313);
      await tester.pump();
      expect(probe.attach_ad, isFalse);
      await _pump_reader(
        tester,
        scroll_controller,
        probe,
        prefix_height: 1300,
        use_list_view: use_list_view,
      );

      expect(probe.attach_card_positions, isEmpty);
      expect(probe.attach_ad, isFalse);
      expect(tester.getTopLeft(find.byKey(const Key('prepared_card'))).dy, 999);
      expect(tester.takeException(), isNull);
    });

    testWidgets('卡片同帧已被快速划出，迟到挂载回调不能锁住屏外挂载：$use_list_view', (tester) async {
      final ScrollController scroll_controller = ScrollController();
      addTearDown(scroll_controller.dispose);
      final _AdProbe probe = _AdProbe();
      await _pump_reader(
        tester,
        scroll_controller,
        probe,
        use_list_view: use_list_view,
      );
      await _prepare_ad(tester, probe);
      scroll_controller.jumpTo(313);
      await _flush_frames(tester);
      expect(probe.attach_ad, isTrue);

      scroll_controller.jumpTo(1400);
      probe.on_ad_attached();
      await _flush_frames(tester);
      expect(probe.attach_ad, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('可见门禁开放后下一帧已离屏，构建过程也不能短暂挂载：$use_list_view', (tester) async {
      final ScrollController scroll_controller = ScrollController();
      addTearDown(scroll_controller.dispose);
      final _AdProbe probe = _AdProbe();
      await _pump_reader(
        tester,
        scroll_controller,
        probe,
        use_list_view: use_list_view,
      );
      await _prepare_ad(tester, probe);

      scroll_controller.jumpTo(313);
      await tester.pump();
      expect(probe.attach_ad, isFalse);
      scroll_controller.jumpTo(1400);
      await _flush_frames(tester);

      expect(probe.attach_card_positions, isEmpty);
      expect(probe.attach_ad, isFalse);
    });
  }

  testWidgets('已展示广告重载后重新判断当前卡片可见范围', (tester) async {
    final ScrollController scroll_controller = ScrollController();
    addTearDown(scroll_controller.dispose);
    final _AdProbe probe = _AdProbe();
    await _pump_reader(tester, scroll_controller, probe);
    await _prepare_ad(tester, probe);
    scroll_controller.jumpTo(313);
    await _flush_frames(tester);
    expect(probe.attach_ad, isTrue);
    probe.on_ad_attached();

    scroll_controller.jumpTo(1400);
    await _flush_frames(tester);
    probe.on_load_status_changed(NativeAdLoadStatus.loading);
    await _flush_frames(tester);
    expect(probe.attach_ad, isFalse);
    await _prepare_ad(tester, probe);
    expect(probe.attach_ad, isFalse);

    scroll_controller.jumpTo(313);
    await _flush_frames(tester);
    expect(probe.attach_ad, isTrue);
  });

  for (final bool use_list_view in <bool>[false, true]) {
    testWidgets('屏外下方重载可以直接应用完整的新卡片高度：$use_list_view', (tester) async {
      final ScrollController scroll_controller = ScrollController();
      addTearDown(scroll_controller.dispose);
      final _AdProbe probe = _AdProbe();
      await _pump_reader(
        tester,
        scroll_controller,
        probe,
        use_list_view: use_list_view,
      );
      await _prepare_ad(tester, probe);

      probe.on_load_status_changed(NativeAdLoadStatus.loading);
      await _flush_frames(tester);
      expect(
        tester.getSize(find.byKey(const Key('prepared_slot'))).height,
        _AdProbe.reserved_extent,
      );
      await _prepare_ad(
        tester,
        probe,
        card_height: _AdProbe.reloaded_card_height,
      );
      expect(
        tester.getSize(find.byKey(const Key('prepared_slot'))).height,
        _AdProbe.reloaded_reserved_extent,
      );
      expect(
        tester.getSize(find.byKey(const Key('prepared_card'))).height,
        _AdProbe.reloaded_card_height,
      );
      expect(probe.attach_ad, isFalse);
      expect(scroll_controller.offset, 0);
    });

    testWidgets('屏外上方重载以高度差补偿滚动位置，当前正文保持原位：$use_list_view', (tester) async {
      final ScrollController scroll_controller = ScrollController();
      addTearDown(scroll_controller.dispose);
      final _AdProbe probe = _AdProbe();
      await _pump_reader(
        tester,
        scroll_controller,
        probe,
        use_list_view: use_list_view,
      );
      await _prepare_ad(tester, probe);
      scroll_controller.jumpTo(313);
      await _flush_frames(tester);
      probe.on_ad_attached();
      scroll_controller.jumpTo(1400);
      await _flush_frames(tester);
      final Offset following_position = tester.getTopLeft(
        find.byKey(const Key('following_text')),
      );

      probe.on_load_status_changed(NativeAdLoadStatus.loading);
      await _flush_frames(tester);
      expect(
        tester.getSize(find.byKey(const Key('prepared_slot'))).height,
        _AdProbe.reserved_extent,
      );
      expect(scroll_controller.offset, 1400);
      await _prepare_ad(
        tester,
        probe,
        card_height: _AdProbe.reloaded_card_height,
      );
      expect(
        tester.getSize(find.byKey(const Key('prepared_slot'))).height,
        _AdProbe.reloaded_reserved_extent,
      );
      expect(scroll_controller.offset, 1500);
      expect(
        tester.getTopLeft(find.byKey(const Key('following_text'))),
        following_position,
      );
      expect(probe.attach_ad, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('可视卡片重载变高时等待，移出视口后才提交新尺寸并允许挂载：$use_list_view', (tester) async {
      final ScrollController scroll_controller = ScrollController();
      addTearDown(scroll_controller.dispose);
      final _AdProbe probe = _AdProbe();
      final List<double> committed_extents = <double>[];
      await _pump_reader(
        tester,
        scroll_controller,
        probe,
        use_list_view: use_list_view,
        on_extent_changed: committed_extents.add,
      );
      await _prepare_ad(tester, probe);
      expect(committed_extents, <double>[_AdProbe.reserved_extent]);
      scroll_controller.jumpTo(800);
      await _flush_frames(tester);
      probe.on_ad_attached();
      final Offset following_position = tester.getTopLeft(
        find.byKey(const Key('following_text')),
      );
      probe.attach_card_positions.clear();

      probe.on_load_status_changed(NativeAdLoadStatus.loading);
      await _flush_frames(tester);
      await _prepare_ad(
        tester,
        probe,
        card_height: _AdProbe.reloaded_card_height,
      );
      expect(
        tester.getSize(find.byKey(const Key('prepared_slot'))).height,
        _AdProbe.reserved_extent,
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('following_text'))),
        following_position,
      );
      expect(scroll_controller.offset, 800);
      expect(probe.attach_ad, isFalse);
      expect(probe.attach_card_positions, isEmpty);
      expect(committed_extents, <double>[_AdProbe.reserved_extent]);

      scroll_controller.jumpTo(0);
      await _flush_frames(tester);
      expect(
        tester.getSize(find.byKey(const Key('prepared_slot'))).height,
        _AdProbe.reloaded_reserved_extent,
      );
      expect(probe.attach_ad, isFalse);
      expect(committed_extents, <double>[
        _AdProbe.reserved_extent,
        _AdProbe.reloaded_reserved_extent,
      ]);

      probe.on_layout_height_changed(_AdProbe.reloaded_card_height);
      probe.on_load_status_changed(NativeAdLoadStatus.loaded);
      await _flush_frames(tester);
      expect(committed_extents, <double>[
        _AdProbe.reserved_extent,
        _AdProbe.reloaded_reserved_extent,
      ]);
      scroll_controller.jumpTo(313);
      await _flush_frames(tester);
      expect(probe.attach_ad, isTrue);
      expect(
        tester.getSize(find.byKey(const Key('prepared_card'))).height,
        _AdProbe.reloaded_card_height,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final bool use_list_view in <bool>[false, true]) {
    testWidgets('已预留广告在屏外下方重载失败时释放空位：$use_list_view', (tester) async {
      final ScrollController scroll_controller = ScrollController();
      addTearDown(scroll_controller.dispose);
      final _AdProbe probe = _AdProbe();
      final List<double> committed_extents = <double>[];
      await _pump_reader(
        tester,
        scroll_controller,
        probe,
        use_list_view: use_list_view,
        on_extent_changed: committed_extents.add,
      );
      await _prepare_ad(tester, probe);

      probe.on_load_status_changed(NativeAdLoadStatus.loading);
      probe.on_load_status_changed(NativeAdLoadStatus.failed);
      await _flush_frames(tester);

      expect(tester.getSize(find.byKey(const Key('prepared_slot'))).height, 0);
      expect(
        tester.getTopLeft(find.byKey(const Key('following_text'))).dy,
        900,
      );
      expect(scroll_controller.offset, 0);
      expect(probe.is_disposed, isTrue);
      expect(committed_extents, <double>[_AdProbe.reserved_extent, 0]);

      probe.on_load_status_changed(NativeAdLoadStatus.loaded);
      probe.on_layout_height_changed(_AdProbe.card_height);
      await _flush_frames(tester);
      expect(find.byType(_FakeNativeAd), findsNothing);
      expect(committed_extents, <double>[_AdProbe.reserved_extent, 0]);
    });

    testWidgets('可见广告重载失败保留当前正文，划离屏幕后才释放：$use_list_view', (tester) async {
      final ScrollController scroll_controller = ScrollController();
      addTearDown(scroll_controller.dispose);
      final _AdProbe probe = _AdProbe();
      final List<double> committed_extents = <double>[];
      await _pump_reader(
        tester,
        scroll_controller,
        probe,
        use_list_view: use_list_view,
        on_extent_changed: committed_extents.add,
      );
      await _prepare_ad(tester, probe);
      scroll_controller.jumpTo(800);
      await _flush_frames(tester);
      probe.on_ad_attached();
      final Offset following_position = tester.getTopLeft(
        find.byKey(const Key('following_text')),
      );

      probe.on_load_status_changed(NativeAdLoadStatus.loading);
      probe.on_load_status_changed(NativeAdLoadStatus.failed);
      await _flush_frames(tester);
      expect(
        tester.getSize(find.byKey(const Key('prepared_slot'))).height,
        _AdProbe.reserved_extent,
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('following_text'))),
        following_position,
      );
      expect(scroll_controller.offset, 800);
      expect(probe.attach_ad, isFalse);
      expect(committed_extents, <double>[_AdProbe.reserved_extent]);

      scroll_controller.jumpTo(0);
      await _flush_frames(tester);
      expect(tester.getSize(find.byKey(const Key('prepared_slot'))).height, 0);
      expect(probe.is_disposed, isTrue);
      expect(scroll_controller.offset, 0);
      expect(committed_extents, <double>[_AdProbe.reserved_extent, 0]);
    });

    testWidgets('已预留广告在屏外上方失败时补偿高度，当前正文不移动：$use_list_view', (tester) async {
      final ScrollController scroll_controller = ScrollController();
      addTearDown(scroll_controller.dispose);
      final _AdProbe probe = _AdProbe();
      final List<double> committed_extents = <double>[];
      await _pump_reader(
        tester,
        scroll_controller,
        probe,
        use_list_view: use_list_view,
        on_extent_changed: committed_extents.add,
      );
      await _prepare_ad(tester, probe);
      scroll_controller.jumpTo(1400);
      await _flush_frames(tester);
      final Offset following_position = tester.getTopLeft(
        find.byKey(const Key('following_text')),
      );

      probe.on_load_status_changed(NativeAdLoadStatus.loading);
      probe.on_load_status_changed(NativeAdLoadStatus.failed);
      await _flush_frames(tester);

      expect(tester.getSize(find.byKey(const Key('prepared_slot'))).height, 0);
      expect(scroll_controller.offset, 1400 - _AdProbe.reserved_extent);
      expect(
        tester.getTopLeft(find.byKey(const Key('following_text'))),
        following_position,
      );
      expect(probe.is_disposed, isTrue);
      expect(committed_extents, <double>[_AdProbe.reserved_extent, 0]);
      expect(tester.takeException(), isNull);
    });
  }

  for (final bool use_list_view in <bool>[false, true]) {
    testWidgets('屏外上方多个广告同帧重载时累计补偿正文位置：$use_list_view', (tester) async {
      final ScrollController scroll_controller = ScrollController();
      addTearDown(scroll_controller.dispose);
      final _AdProbe first_probe = _AdProbe();
      final _AdProbe second_probe = _AdProbe();
      await _pump_two_slot_reader(
        tester,
        scroll_controller,
        first_probe,
        second_probe,
        use_list_view: use_list_view,
      );
      scroll_controller.jumpTo(2800);
      await _flush_frames(tester);
      final Offset following_position = tester.getTopLeft(
        find.byKey(const Key('following_text')),
      );

      for (final _AdProbe probe in <_AdProbe>[first_probe, second_probe]) {
        probe.on_load_status_changed(NativeAdLoadStatus.loading);
        probe.measured_card_height = _AdProbe.reloaded_card_height;
        probe.on_load_status_changed(NativeAdLoadStatus.loaded);
        probe.on_layout_height_changed(_AdProbe.reloaded_card_height);
      }
      await _flush_frames(tester);
      expect(
        tester.getSize(find.byKey(const Key('first_slot'))).height,
        _AdProbe.reloaded_reserved_extent,
      );
      expect(
        tester.getSize(find.byKey(const Key('second_slot'))).height,
        _AdProbe.reloaded_reserved_extent,
      );
      expect(scroll_controller.offset, 3000);
      expect(
        tester.getTopLeft(find.byKey(const Key('following_text'))),
        following_position,
      );
      expect(first_probe.attach_ad, isFalse);
      expect(second_probe.attach_ad, isFalse);
    });
  }

  for (final bool use_list_view in <bool>[false, true]) {
    testWidgets('列表底部广告重载变矮时只补偿一次，保持正文与底部位置：$use_list_view', (tester) async {
      final ScrollController scroll_controller = ScrollController();
      addTearDown(scroll_controller.dispose);
      final _AdProbe probe = _AdProbe();
      await _pump_reader(
        tester,
        scroll_controller,
        probe,
        use_list_view: use_list_view,
      );
      await _prepare_ad(
        tester,
        probe,
        card_height: _AdProbe.reloaded_card_height,
      );
      scroll_controller.jumpTo(scroll_controller.position.maxScrollExtent);
      await _flush_frames(tester);
      final double previous_max_extent =
          scroll_controller.position.maxScrollExtent;
      final Offset following_position = tester.getTopLeft(
        find.byKey(const Key('following_text')),
      );

      probe.on_load_status_changed(NativeAdLoadStatus.loading);
      await _flush_frames(tester);
      await _prepare_ad(tester, probe);
      expect(
        tester.getSize(find.byKey(const Key('prepared_slot'))).height,
        _AdProbe.reserved_extent,
      );
      expect(
        scroll_controller.position.maxScrollExtent,
        previous_max_extent -
            (_AdProbe.reloaded_card_height - _AdProbe.card_height),
      );
      expect(
        scroll_controller.offset,
        scroll_controller.position.maxScrollExtent,
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('following_text'))),
        following_position,
      );
      expect(probe.attach_ad, isFalse);
    });
  }

  testWidgets('更换阅读控制器会解绑旧监听并使用新控制器检查可见性', (tester) async {
    final _TrackingScrollController first_controller =
        _TrackingScrollController();
    final _TrackingScrollController second_controller =
        _TrackingScrollController();
    addTearDown(first_controller.dispose);
    addTearDown(second_controller.dispose);
    final _AdProbe probe = _AdProbe();
    await _pump_reader(tester, first_controller, probe);
    await _pump_reader(tester, second_controller, probe);
    expect(first_controller.hasClients, isFalse);
    expect(first_controller.has_registered_listeners, isFalse);
    expect(second_controller.hasClients, isTrue);

    await _prepare_ad(tester, probe);
    second_controller.jumpTo(313);
    await _flush_frames(tester);
    expect(probe.attach_ad, isTrue);
  });

  testWidgets('销毁后安全忽略待处理布局帧和旧 SDK 回调', (tester) async {
    final _TrackingScrollController scroll_controller =
        _TrackingScrollController();
    addTearDown(scroll_controller.dispose);
    final _AdProbe probe = _AdProbe();
    await _pump_reader(tester, scroll_controller, probe);
    probe.on_load_status_changed(NativeAdLoadStatus.loaded);
    probe.on_layout_height_changed(_AdProbe.card_height);

    await tester.pumpWidget(const SizedBox.shrink());
    probe.on_load_status_changed(NativeAdLoadStatus.loading);
    probe.on_layout_height_changed(_AdProbe.card_height);
    probe.on_ad_attached();
    await _flush_frames(tester);
    expect(probe.is_disposed, isTrue);
    expect(scroll_controller.has_registered_listeners, isFalse);
    expect(tester.takeException(), isNull);
  });
}
