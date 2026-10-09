// ignore_for_file: non_constant_identifier_names

import 'package:app/components/inline_native_ad/prepared_slot.dart';
import 'package:app/components/shell_tab_host/widgets/shell_tab_pane.dart';
import 'package:app/pages/short_story_read/widgets/native_ad_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 记录每一次真正获准挂载的构建，不能靠后一帧隐藏掩盖屏外首次挂载。
class _SurfaceProbe {
  ValueChanged<NativeAdLoadStatus>? status;
  ValueChanged<double>? measure;
  VoidCallback? attached;
  int attachment_builds = 0;
  int skips = 0;
  bool attach_ad = false;

  Widget build(
    BuildContext context, {
    required bool attach_ad,
    required bool reserve_space,
    required ValueChanged<NativeAdLoadStatus> on_load_status_changed,
    required ValueChanged<double> on_layout_height_changed,
    required VoidCallback on_ad_attached,
  }) {
    status = on_load_status_changed;
    measure = on_layout_height_changed;
    attached = on_ad_attached;
    this.attach_ad = attach_ad;
    if (attach_ad) attachment_builds++;
    return const SizedBox.expand();
  }

  void ready() {
    status!(NativeAdLoadStatus.loaded);
    measure!(300);
  }
}

/// 故意让内层viewport宽400、窗口宽800，验证父横向viewport的真实裁剪。
Widget _reader(
  ScrollController vertical,
  _SurfaceProbe probe, {
  bool retain_attachment_offscreen = true,
}) {
  return SingleChildScrollView(
    controller: vertical,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 900),
        PreparedNativeAdSlot(
          key: const ValueKey('surface_slot'),
          scroll_controller: vertical,
          builder: probe.build,
          leading_extent: 0,
          trailing_extent: 0,
          retain_attachment_offscreen: retain_attachment_offscreen,
          on_skipped: () => probe.skips++,
        ),
        const SizedBox(height: 1500),
      ],
    ),
  );
}

Future<void> _frames(WidgetTester tester, [int count = 4]) async {
  for (int index = 0; index < count; index++) {
    tester.binding.scheduleFrame();
    await tester.pump();
  }
}

Future<void> _pump_horizontal(
  WidgetTester tester, {
  required PageController horizontal,
  required ScrollController vertical,
  required _SurfaceProbe probe,
  bool reader_first = false,
}) async {
  final reader = _reader(vertical, probe);
  await tester.pumpWidget(
    MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 400,
          height: 600,
          child: PageView(
            controller: horizontal,
            allowImplicitScrolling: true,
            children: reader_first
                ? [reader, const SizedBox.expand()]
                : [const SizedBox.expand(), reader],
          ),
        ),
      ),
    ),
  );
  await _frames(tester);
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed),
  );
  tearDown(
    () => binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed),
  );

  testWidgets('未进入的横向Tab不误跳过零高度广告，返回可见页面后仍能自然提交', (tester) async {
    final horizontal = PageController();
    final vertical = ScrollController(initialScrollOffset: 700);
    addTearDown(horizontal.dispose);
    addTearDown(vertical.dispose);
    final probe = _SurfaceProbe();
    await _pump_horizontal(
      tester,
      horizontal: horizontal,
      vertical: vertical,
      probe: probe,
    );
    expect(
      find.byKey(const ValueKey('surface_slot'), skipOffstage: false),
      findsOneWidget,
    );
    expect(probe.status, isNotNull);
    probe.ready();
    await _frames(tester);
    expect(probe.skips, 0);
    expect(probe.attachment_builds, 0);
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey('surface_slot'), skipOffstage: false),
          )
          .height,
      0,
    );

    // 在隐藏Tab中恢复其滚动位置，不影响是否已经错过广告的业务判断。
    vertical.jumpTo(0);
    await _frames(tester);
    horizontal.jumpToPage(1);
    await _frames(tester);
    expect(probe.skips, 0);
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey('surface_slot'), skipOffstage: false),
          )
          .height,
      300,
    );
    expect(probe.attachment_builds, 0);
    vertical.jumpTo(600);
    await _frames(tester);
    expect(probe.attach_ad, isTrue);
    expect(probe.attachment_builds, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('竖向批准后同帧切到另一Tab，不能首次创建屏幕横向之外的广告视图', (tester) async {
    final horizontal = PageController();
    final vertical = ScrollController();
    addTearDown(horizontal.dispose);
    addTearDown(vertical.dispose);
    final probe = _SurfaceProbe();
    await _pump_horizontal(
      tester,
      horizontal: horizontal,
      vertical: vertical,
      probe: probe,
      reader_first: true,
    );
    probe.ready();
    await _frames(tester);
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey('surface_slot'), skipOffstage: false),
          )
          .height,
      300,
    );
    vertical.jumpTo(600);
    await tester.pump();
    expect(probe.attachment_builds, 0);
    horizontal.jumpToPage(1);
    await _frames(tester);
    expect(probe.attachment_builds, 0);
    horizontal.jumpToPage(0);
    await _frames(tester);
    expect(probe.attach_ad, isTrue);
    expect(probe.attachment_builds, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Offstage里迟到的素材不挂载、不误跳过，显示后恢复判断', (tester) async {
    final vertical = ScrollController(initialScrollOffset: 700);
    addTearDown(vertical.dispose);
    final probe = _SurfaceProbe();
    Future<void> pump(bool hidden) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 400,
              height: 600,
              child: Offstage(
                offstage: hidden,
                child: _reader(vertical, probe),
              ),
            ),
          ),
        ),
      );
      await _frames(tester);
    }

    await pump(true);
    probe.ready();
    await _frames(tester);
    expect(probe.skips, 0);
    expect(probe.attachment_builds, 0);
    vertical.jumpTo(0);
    await pump(false);
    expect(probe.skips, 0);
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey('surface_slot'), skipOffstage: false),
          )
          .height,
      300,
    );
    vertical.jumpTo(600);
    await _frames(tester);
    expect(probe.attach_ad, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('被新路由覆盖期间不首次挂载，pop后重新检查已缓存广告', (tester) async {
    final vertical = ScrollController();
    addTearDown(vertical.dispose);
    final probe = _SurfaceProbe();
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 400,
            height: 600,
            child: _reader(vertical, probe),
          ),
        ),
      ),
    );
    await _frames(tester);
    probe.ready();
    await _frames(tester);
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const ColoredBox(color: Colors.black),
      ),
    );
    await tester.pumpAndSettle();
    vertical.jumpTo(600);
    await _frames(tester);
    expect(probe.attachment_builds, 0);
    expect(probe.skips, 0);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(probe.attach_ad, isTrue);
    expect(probe.attachment_builds, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Shell保留同一个child时，隐藏期间就绪的零高度广告返回后恢复准备', (tester) async {
    final vertical = ScrollController();
    addTearDown(vertical.dispose);
    final probe = _SurfaceProbe();
    final reader = _reader(vertical, probe, retain_attachment_offscreen: false);
    Future<void> pump(bool active) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 400,
              height: 600,
              child: ShellTabPane(
                active: active,
                slideFromLeft: true,
                child: reader,
              ),
            ),
          ),
        ),
      );
      await _frames(tester);
    }

    await pump(false);
    probe.ready();
    await _frames(tester);
    expect(probe.skips, 0);
    expect(probe.attachment_builds, 0);
    await pump(true);
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey('surface_slot'), skipOffstage: false),
          )
          .height,
      300,
    );
    vertical.jumpTo(600);
    await _frames(tester);
    expect(probe.attach_ad, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Shell隐藏期间已预留广告重载，返回同一个child无需新滚动即可首次挂载', (tester) async {
    final vertical = ScrollController();
    addTearDown(vertical.dispose);
    final probe = _SurfaceProbe();
    final reader = _reader(vertical, probe, retain_attachment_offscreen: false);
    Future<void> pump(bool active) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 400,
              height: 600,
              child: ShellTabPane(
                active: active,
                slideFromLeft: true,
                child: reader,
              ),
            ),
          ),
        ),
      );
      await _frames(tester);
    }

    await pump(true);
    probe.ready();
    await _frames(tester);
    expect(probe.attachment_builds, 0);
    await pump(false);
    vertical.jumpTo(600);
    probe.status!(NativeAdLoadStatus.loading);
    probe.ready();
    await _frames(tester);
    expect(probe.attachment_builds, 0);
    expect(probe.skips, 0);
    await pump(true);
    expect(probe.attach_ad, isTrue);
    expect(probe.attachment_builds, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Shell切出时同一个child里的已展示信息流广告立即撤下，返回再复验', (tester) async {
    final vertical = ScrollController();
    addTearDown(vertical.dispose);
    final probe = _SurfaceProbe();
    final reader = _reader(vertical, probe, retain_attachment_offscreen: false);
    Future<void> pump(bool active) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 400,
              height: 600,
              child: ShellTabPane(
                active: active,
                slideFromLeft: true,
                child: reader,
              ),
            ),
          ),
        ),
      );
      await _frames(tester);
    }

    await pump(true);
    probe.ready();
    await _frames(tester);
    vertical.jumpTo(600);
    await _frames(tester);
    expect(probe.attach_ad, isTrue);
    probe.attached!();
    await pump(false);
    expect(probe.attach_ad, isFalse);
    expect(probe.skips, 0);
    await pump(true);
    expect(probe.attach_ad, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('只暂停Ticker而未Offstage时，普通阅读页保留已展示素材', (tester) async {
    final vertical = ScrollController();
    addTearDown(vertical.dispose);
    final probe = _SurfaceProbe();
    final reader = _reader(vertical, probe);
    Future<void> pump(bool enabled) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 400,
              height: 600,
              child: TickerMode(enabled: enabled, child: reader),
            ),
          ),
        ),
      );
      await _frames(tester);
    }

    await pump(true);
    probe.ready();
    await _frames(tester);
    vertical.jumpTo(600);
    await _frames(tester);
    expect(probe.attach_ad, isTrue);
    probe.attached!();
    vertical.jumpTo(1200);
    await _frames(tester);
    await pump(false);
    expect(probe.attach_ad, isTrue);
    expect(probe.skips, 0);
    await pump(true);
    expect(probe.attach_ad, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('挂载批准后应用进入后台，必须等前台复验才首次显示', (tester) async {
    final vertical = ScrollController();
    addTearDown(vertical.dispose);
    final probe = _SurfaceProbe();
    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 400,
            height: 600,
            child: _reader(vertical, probe),
          ),
        ),
      ),
    );
    await _frames(tester);
    probe.ready();
    await _frames(tester);
    vertical.jumpTo(600);
    await tester.pump();
    expect(probe.attachment_builds, 0);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await _frames(tester);
    expect(probe.attachment_builds, 0);
    expect(probe.skips, 0);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _frames(tester);
    expect(probe.attach_ad, isTrue);
    expect(probe.attachment_builds, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('普通阅读页已展示的广告进入后台仍保留原视图语义', (tester) async {
    final vertical = ScrollController();
    addTearDown(vertical.dispose);
    final probe = _SurfaceProbe();
    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 400,
            height: 600,
            child: _reader(vertical, probe),
          ),
        ),
      ),
    );
    await _frames(tester);
    probe.ready();
    await _frames(tester);
    vertical.jumpTo(600);
    await _frames(tester);
    expect(probe.attach_ad, isTrue);
    probe.attached!();
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await _frames(tester);
    expect(probe.attach_ad, isTrue);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _frames(tester);
    expect(probe.attach_ad, isTrue);
    expect(tester.takeException(), isNull);
  });
}
