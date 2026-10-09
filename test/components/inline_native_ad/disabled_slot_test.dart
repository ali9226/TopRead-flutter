import 'package:app/components/inline_native_ad/prepared_slot.dart';
import 'package:app/pages/short_story_read/widgets/native_ad_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 固定阅读几何尺寸，广告高度包含卡片上下的装饰留白。
class _ReaderGeometry {
  static const double prefix_height = 900;
  static const double following_height = 1400;
  static const double viewport_height = 600;
  static const double viewport_width = 400;
  static const double card_height = 300;
  static const double leading_extent = 12;
  static const double trailing_extent = 16;
  static const double reserved_extent =
      card_height + leading_extent + trailing_extent;
}

/// 保存 SDK 回调和释放次数，完全替代原生广告及其平台视图。
class _DisabledAdProbe {
  final String id;
  final List<double> committed_extents = <double>[];
  int build_count = 0;
  int disposed_count = 0;
  int skipped_count = 0;
  bool attach_ad = false;
  late ValueChanged<NativeAdLoadStatus> on_load_status_changed;
  late ValueChanged<double> on_layout_height_changed;
  late VoidCallback on_ad_attached;

  _DisabledAdProbe(this.id);

  Key get slot_key => Key('${id}_slot');

  Widget builder(
    BuildContext context, {
    required bool attach_ad,
    required bool reserve_space,
    required ValueChanged<NativeAdLoadStatus> on_load_status_changed,
    required ValueChanged<double> on_layout_height_changed,
    required VoidCallback on_ad_attached,
  }) {
    build_count++;
    this.attach_ad = attach_ad;
    this.on_load_status_changed = on_load_status_changed;
    this.on_layout_height_changed = on_layout_height_changed;
    this.on_ad_attached = on_ad_attached;
    return _FakeDisabledNativeAd(probe: this, reserve_space: reserve_space);
  }
}

class _FakeDisabledNativeAd extends StatefulWidget {
  final _DisabledAdProbe probe;
  final bool reserve_space;

  const _FakeDisabledNativeAd({
    required this.probe,
    required this.reserve_space,
  });

  @override
  State<_FakeDisabledNativeAd> createState() => _FakeDisabledNativeAdState();
}

class _FakeDisabledNativeAdState extends State<_FakeDisabledNativeAd> {
  @override
  void dispose() {
    widget.probe.disposed_count++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.reserve_space ? _ReaderGeometry.reserved_extent : 0,
    );
  }
}

/// 仅重建业务开关，保留滚动位置和已插入的同一个广告 State。
Future<void> _pump_reader(
  WidgetTester tester,
  ScrollController scroll_controller,
  List<_DisabledAdProbe> probes, {
  required bool use_list_view,
  bool is_enabled = true,
  bool collapse_when_disabled = true,
  double? initial_reserved_extent,
  double viewport_padding = 0,
  double viewport_top_inset = 0,
  double viewport_height = _ReaderGeometry.viewport_height,
}) async {
  final List<Widget> children = <Widget>[
    const SizedBox(
      key: Key('preceding_text'),
      height: _ReaderGeometry.prefix_height,
    ),
  ];
  for (int index = 0; index < probes.length; index++) {
    final _DisabledAdProbe probe = probes[index];
    if (index > 0) {
      children.add(const SizedBox(height: _ReaderGeometry.prefix_height));
    }
    children.add(
      PreparedNativeAdSlot(
        key: probe.slot_key,
        scroll_controller: scroll_controller,
        builder: probe.builder,
        leading_extent: _ReaderGeometry.leading_extent,
        trailing_extent: _ReaderGeometry.trailing_extent,
        is_enabled: is_enabled,
        collapse_when_disabled: collapse_when_disabled,
        viewport_top_inset: viewport_top_inset,
        initial_reserved_extent: initial_reserved_extent,
        on_extent_changed: probe.committed_extents.add,
        on_skipped: () => probe.skipped_count++,
      ),
    );
  }
  children.add(
    const SizedBox(
      key: Key('following_text'),
      height: _ReaderGeometry.following_height,
    ),
  );
  final Widget reading_content = Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: children,
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: EdgeInsets.only(top: viewport_padding),
          child: SizedBox(
            width: _ReaderGeometry.viewport_width,
            height: viewport_height,
            child: use_list_view
                ? ListView(
                    padding: EdgeInsets.zero,
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
  await tester.pumpAndSettle();
}

/// 模拟素材和测量均准备完毕，让广告先在视口下方提交完整尺寸。
Future<void> _prepare_ads(
  WidgetTester tester,
  List<_DisabledAdProbe> probes,
) async {
  for (final _DisabledAdProbe probe in probes) {
    probe.on_load_status_changed(NativeAdLoadStatus.loaded);
    probe.on_layout_height_changed(_ReaderGeometry.card_height);
  }
  await tester.pumpAndSettle();
  for (final _DisabledAdProbe probe in probes) {
    expect(
      tester.getSize(find.byKey(probe.slot_key)).height,
      _ReaderGeometry.reserved_extent,
    );
  }
}

/// 完成一次真实可见挂载，覆盖已展示广告的保留门禁。
Future<void> _show_ad(
  WidgetTester tester,
  ScrollController scroll_controller,
  _DisabledAdProbe probe,
) async {
  scroll_controller.jumpTo(800);
  await tester.pumpAndSettle();
  expect(probe.attach_ad, isTrue);
  probe.on_ad_attached();
}

void _expect_collapsed(WidgetTester tester, _DisabledAdProbe probe) {
  expect(tester.getSize(find.byKey(probe.slot_key)).height, 0);
  expect(probe.disposed_count, 1);
  expect(probe.skipped_count, 1);
  expect(probe.committed_extents, <double>[_ReaderGeometry.reserved_extent, 0]);
  expect(find.byType(_FakeDisabledNativeAd), findsNothing);
  expect(tester.takeException(), isNull);
}

void main() {
  for (final bool use_list_view in <bool>[false, true]) {
    testWidgets('免广告立即折叠完全可见的插位和上下留白：$use_list_view', (tester) async {
      final ScrollController scroll_controller = ScrollController();
      addTearDown(scroll_controller.dispose);
      final _DisabledAdProbe probe = _DisabledAdProbe('ad');
      final List<_DisabledAdProbe> probes = <_DisabledAdProbe>[probe];
      await _pump_reader(
        tester,
        scroll_controller,
        probes,
        use_list_view: use_list_view,
      );
      await _prepare_ads(tester, probes);
      await _show_ad(tester, scroll_controller, probe);
      final Offset preceding_position = tester.getTopLeft(
        find.byKey(const Key('preceding_text')),
      );
      final double following_top = tester
          .getTopLeft(find.byKey(const Key('following_text')))
          .dy;

      await _pump_reader(
        tester,
        scroll_controller,
        probes,
        use_list_view: use_list_view,
        is_enabled: false,
      );

      _expect_collapsed(tester, probe);
      expect(scroll_controller.offset, 800);
      expect(
        tester.getTopLeft(find.byKey(const Key('preceding_text'))),
        preceding_position,
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('following_text'))).dy,
        following_top - _ReaderGeometry.reserved_extent,
      );
    });

    testWidgets('插位部分在视口上方时仅补偿已读过的高度：$use_list_view', (tester) async {
      final ScrollController scroll_controller = ScrollController();
      addTearDown(scroll_controller.dispose);
      final _DisabledAdProbe probe = _DisabledAdProbe('ad');
      final List<_DisabledAdProbe> probes = <_DisabledAdProbe>[probe];
      await _pump_reader(
        tester,
        scroll_controller,
        probes,
        use_list_view: use_list_view,
      );
      await _prepare_ads(tester, probes);
      await _show_ad(tester, scroll_controller, probe);
      scroll_controller.jumpTo(1000);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byKey(probe.slot_key)).dy, -100);

      await _pump_reader(
        tester,
        scroll_controller,
        probes,
        use_list_view: use_list_view,
        is_enabled: false,
      );

      _expect_collapsed(tester, probe);
      expect(scroll_controller.offset, _ReaderGeometry.prefix_height);
      expect(tester.getTopLeft(find.byKey(const Key('following_text'))).dy, 0);
    });

    for (final bool is_above_viewport in <bool>[false, true]) {
      testWidgets('完整屏外插位禁用后折叠并按位置补偿：$use_list_view/$is_above_viewport', (
        tester,
      ) async {
        final ScrollController scroll_controller = ScrollController();
        addTearDown(scroll_controller.dispose);
        final _DisabledAdProbe probe = _DisabledAdProbe('ad');
        final List<_DisabledAdProbe> probes = <_DisabledAdProbe>[probe];
        await _pump_reader(
          tester,
          scroll_controller,
          probes,
          use_list_view: use_list_view,
        );
        await _prepare_ads(tester, probes);
        if (is_above_viewport) {
          await _show_ad(tester, scroll_controller, probe);
          scroll_controller.jumpTo(1400);
          await tester.pumpAndSettle();
        }
        final double old_offset = scroll_controller.offset;
        final double following_top = tester
            .getTopLeft(find.byKey(const Key('following_text')))
            .dy;

        await _pump_reader(
          tester,
          scroll_controller,
          probes,
          use_list_view: use_list_view,
          is_enabled: false,
        );

        _expect_collapsed(tester, probe);
        expect(
          scroll_controller.offset,
          old_offset -
              (is_above_viewport ? _ReaderGeometry.reserved_extent : 0),
        );
        expect(
          tester.getTopLeft(find.byKey(const Key('following_text'))).dy,
          following_top -
              (is_above_viewport ? 0 : _ReaderGeometry.reserved_extent),
        );
      });
    }

    testWidgets('顶部遮挡范围参与部分插位补偿：$use_list_view', (tester) async {
      final ScrollController scroll_controller = ScrollController();
      addTearDown(scroll_controller.dispose);
      final _DisabledAdProbe probe = _DisabledAdProbe('ad');
      final List<_DisabledAdProbe> probes = <_DisabledAdProbe>[probe];
      const double viewport_padding = 80;
      // 浮层 inset 从窗口顶部计量，与列表 viewport 取交集而非相加。
      const double viewport_top_inset = 104;
      const double viewport_height = 500;
      await _pump_reader(
        tester,
        scroll_controller,
        probes,
        use_list_view: use_list_view,
        viewport_padding: viewport_padding,
        viewport_top_inset: viewport_top_inset,
        viewport_height: viewport_height,
      );
      await _prepare_ads(tester, probes);
      scroll_controller.jumpTo(1000);
      await tester.pumpAndSettle();

      await _pump_reader(
        tester,
        scroll_controller,
        probes,
        use_list_view: use_list_view,
        is_enabled: false,
        viewport_padding: viewport_padding,
        viewport_top_inset: viewport_top_inset,
        viewport_height: viewport_height,
      );

      _expect_collapsed(tester, probe);
      expect(
        scroll_controller.offset,
        _ReaderGeometry.prefix_height - (viewport_top_inset - viewport_padding),
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('following_text'))).dy,
        viewport_top_inset,
      );
    });

    for (final bool second_slot_is_partial in <bool>[false, true]) {
      testWidgets(
        '多个插位同帧禁用累计补偿，包含部分可见卡片：$use_list_view/$second_slot_is_partial',
        (tester) async {
          final ScrollController scroll_controller = ScrollController();
          addTearDown(scroll_controller.dispose);
          final List<_DisabledAdProbe> probes = <_DisabledAdProbe>[
            _DisabledAdProbe('first'),
            _DisabledAdProbe('second'),
          ];
          await _pump_reader(
            tester,
            scroll_controller,
            probes,
            use_list_view: use_list_view,
          );
          await _prepare_ads(tester, probes);
          final double old_offset = second_slot_is_partial ? 2300 : 2800;
          scroll_controller.jumpTo(old_offset);
          await tester.pumpAndSettle();
          final double following_top = tester
              .getTopLeft(find.byKey(const Key('following_text')))
              .dy;

          await _pump_reader(
            tester,
            scroll_controller,
            probes,
            use_list_view: use_list_view,
            is_enabled: false,
          );

          for (final _DisabledAdProbe probe in probes) {
            _expect_collapsed(tester, probe);
          }
          expect(
            scroll_controller.offset,
            second_slot_is_partial
                ? 1800
                : old_offset - 2 * _ReaderGeometry.reserved_extent,
          );
          expect(
            tester.getTopLeft(find.byKey(const Key('following_text'))).dy,
            second_slot_is_partial ? 0 : following_top,
          );
        },
      );
    }

    testWidgets('列表底部禁用仅补偿一次并保留正文位置：$use_list_view', (tester) async {
      final ScrollController scroll_controller = ScrollController();
      addTearDown(scroll_controller.dispose);
      final _DisabledAdProbe probe = _DisabledAdProbe('ad');
      final List<_DisabledAdProbe> probes = <_DisabledAdProbe>[probe];
      await _pump_reader(
        tester,
        scroll_controller,
        probes,
        use_list_view: use_list_view,
      );
      await _prepare_ads(tester, probes);
      scroll_controller.jumpTo(scroll_controller.position.maxScrollExtent);
      await tester.pumpAndSettle();
      final double old_max_extent = scroll_controller.position.maxScrollExtent;
      final Offset following_position = tester.getTopLeft(
        find.byKey(const Key('following_text')),
      );

      await _pump_reader(
        tester,
        scroll_controller,
        probes,
        use_list_view: use_list_view,
        is_enabled: false,
      );

      _expect_collapsed(tester, probe);
      expect(
        scroll_controller.position.maxScrollExtent,
        old_max_extent - _ReaderGeometry.reserved_extent,
      );
      expect(
        scroll_controller.offset,
        scroll_controller.position.maxScrollExtent,
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('following_text'))),
        following_position,
      );
      await tester.pumpAndSettle();
      expect(
        scroll_controller.offset,
        scroll_controller.position.maxScrollExtent,
      );
    });

    testWidgets('拖动中禁用立即释放素材，停止后折叠部分屏上方插位：$use_list_view', (tester) async {
      final ScrollController scroll_controller = ScrollController();
      addTearDown(scroll_controller.dispose);
      final _DisabledAdProbe probe = _DisabledAdProbe('ad');
      final List<_DisabledAdProbe> probes = <_DisabledAdProbe>[probe];
      await _pump_reader(
        tester,
        scroll_controller,
        probes,
        use_list_view: use_list_view,
      );
      await _prepare_ads(tester, probes);
      await _show_ad(tester, scroll_controller, probe);
      scroll_controller.jumpTo(1000);
      await tester.pumpAndSettle();
      final TestGesture gesture = await tester.startGesture(
        const Offset(200, 500),
      );
      await gesture.moveBy(const Offset(0, -40));
      await tester.pump();
      expect(scroll_controller.position.isScrollingNotifier.value, isTrue);
      final double dragging_offset = scroll_controller.offset;

      await _pump_reader(
        tester,
        scroll_controller,
        probes,
        use_list_view: use_list_view,
        is_enabled: false,
      );

      expect(find.byType(_FakeDisabledNativeAd), findsNothing);
      expect(probe.disposed_count, 1);
      expect(
        tester.getSize(find.byKey(probe.slot_key)).height,
        _ReaderGeometry.reserved_extent,
      );
      expect(scroll_controller.offset, dragging_offset);
      expect(probe.committed_extents, <double>[
        _ReaderGeometry.reserved_extent,
      ]);
      // 停留后抬手，避免额外惯性影响本次几何补偿断言。
      await tester.pump(const Duration(seconds: 1));
      await gesture.up();
      await tester.pumpAndSettle();

      _expect_collapsed(tester, probe);
      expect(scroll_controller.offset, _ReaderGeometry.prefix_height);
      expect(tester.getTopLeft(find.byKey(const Key('following_text'))).dy, 0);
    });

    testWidgets('初始禁用忽略缓存广告高度且不创建素材：$use_list_view', (tester) async {
      final ScrollController scroll_controller = ScrollController();
      addTearDown(scroll_controller.dispose);
      final _DisabledAdProbe probe = _DisabledAdProbe('ad');
      await _pump_reader(
        tester,
        scroll_controller,
        <_DisabledAdProbe>[probe],
        use_list_view: use_list_view,
        is_enabled: false,
        initial_reserved_extent: _ReaderGeometry.reserved_extent,
      );

      expect(tester.getSize(find.byKey(probe.slot_key)).height, 0);
      expect(probe.build_count, 0);
      expect(scroll_controller.offset, 0);
      expect(
        tester.getTopLeft(find.byKey(const Key('following_text'))).dy,
        _ReaderGeometry.prefix_height,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('禁用后迟到回调及重新启用不能复活当前插位：$use_list_view', (tester) async {
      final ScrollController scroll_controller = ScrollController();
      addTearDown(scroll_controller.dispose);
      final _DisabledAdProbe probe = _DisabledAdProbe('ad');
      final List<_DisabledAdProbe> probes = <_DisabledAdProbe>[probe];
      await _pump_reader(
        tester,
        scroll_controller,
        probes,
        use_list_view: use_list_view,
      );
      await _prepare_ads(tester, probes);
      await _pump_reader(
        tester,
        scroll_controller,
        probes,
        use_list_view: use_list_view,
        is_enabled: false,
      );
      final int disabled_build_count = probe.build_count;

      for (final bool is_enabled in <bool>[false, true]) {
        await _pump_reader(
          tester,
          scroll_controller,
          probes,
          use_list_view: use_list_view,
          is_enabled: is_enabled,
        );
        probe.on_load_status_changed(NativeAdLoadStatus.loading);
        probe.on_load_status_changed(NativeAdLoadStatus.loaded);
        probe.on_layout_height_changed(_ReaderGeometry.card_height);
        probe.on_ad_attached();
        await tester.pumpAndSettle();
        _expect_collapsed(tester, probe);
        expect(probe.build_count, disabled_build_count);
        expect(scroll_controller.offset, 0);
      }
    });
  }
}
