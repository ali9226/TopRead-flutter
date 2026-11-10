import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_test/flutter_test.dart';

import 'package:app/pages/home/widgets/tab_contents/recommend_tab/logic.dart';
import 'package:app/pages/home/widgets/tab_contents/recommend_tab/style.dart';
import 'package:app/pages/home/widgets/tab_contents/recommend_tab/widgets/ranking_section/style.dart';

const _viewport_key = ValueKey('recommend_scroll_viewport');
const _feed_key = ValueKey('recommend_scroll_feed');
const _ranking_key = ValueKey('recommend_scroll_ranking');
const _horizontal_key = ValueKey('ranking_horizontal_list');
const double _ranking_height = RankingSectionStyle.section_fixed_height;
const double _snap_target =
    _ranking_height + RecommendTabStyle.recommend_top_spacing;

void main() {
  testWidgets('慢速上滑松手后平滑停靠到瀑布流顶部', (tester) async {
    final controller = await _pump_page(tester);
    final gesture = await _hold_drag(tester, -140);
    final release_offset = controller.offset;
    expect(release_offset, greaterThan(RankingSectionStyle.tab_bar_height));
    expect(release_offset, lessThan(_ranking_height));

    await gesture.up(timeStamp: const Duration(milliseconds: 500));
    expect(controller.position.activity, isA<DrivenScrollActivity>());
    expect(controller.offset, release_offset);
    await tester.pump();
    await tester.pump(RecommendTabStyle.snap_duration ~/ 2);
    expect(controller.offset, greaterThan(release_offset));
    expect(controller.offset, lessThan(_snap_target));

    await tester.pumpAndSettle();
    _expect_feed_aligned(tester, controller);
  });

  testWidgets('未滑过标题栏时保留松手位置', (tester) async {
    final controller = await _pump_page(tester);
    final gesture = await _hold_drag(tester, -28);
    final release_offset = controller.offset;
    expect(release_offset, greaterThan(0));
    expect(
      release_offset,
      lessThanOrEqualTo(RankingSectionStyle.tab_bar_height),
    );
    await gesture.up(timeStamp: const Duration(milliseconds: 500));
    expect(controller.position.activity, isNot(isA<DrivenScrollActivity>()));
    await tester.pumpAndSettle();
    expect(controller.offset, closeTo(release_offset, 0.01));
  });

  testWidgets('松手位置恰好等于标题栏高度时不吸附', (tester) async {
    final controller = await _pump_page(tester);
    final gesture = await _hold_drag(
      tester,
      -RankingSectionStyle.tab_bar_height,
    );
    expect(controller.offset, RankingSectionStyle.tab_bar_height);
    await gesture.up(timeStamp: const Duration(milliseconds: 500));
    expect(controller.position.activity, isNot(isA<DrivenScrollActivity>()));
    await tester.pumpAndSettle();
    expect(controller.offset, RankingSectionStyle.tab_bar_height);
  });

  testWidgets('松手位置恰好等于榜单区域高度时仍吸附', (tester) async {
    final controller = await _pump_page(tester);
    controller.jumpTo(_ranking_height - 100);
    await tester.pump();
    final gesture = await _hold_drag(tester, -100);
    expect(controller.offset, _ranking_height);
    await gesture.up(timeStamp: const Duration(milliseconds: 500));
    expect(controller.position.activity, isA<DrivenScrollActivity>());
    await tester.pumpAndSettle();
    _expect_feed_aligned(tester, controller);
  });

  testWidgets('内容不足以停靠瀑布流时保留松手位置', (tester) async {
    final controller = await _pump_page(
      tester,
      size: const Size(844, 390),
      feed_height: 150,
    );
    expect(controller.position.maxScrollExtent, lessThan(_snap_target));
    final gesture = await _hold_drag(tester, -140);
    final release_offset = controller.offset;
    expect(release_offset, greaterThan(RankingSectionStyle.tab_bar_height));
    expect(controller.position.outOfRange, isFalse);
    await gesture.up(timeStamp: const Duration(milliseconds: 500));
    expect(controller.position.activity, isNot(isA<DrivenScrollActivity>()));
    await tester.pumpAndSettle();
    expect(controller.offset, closeTo(release_offset, 0.01));
  });

  testWidgets('横屏空瀑布流上拉越界后使用原生回弹', (tester) async {
    final controller = await _pump_page(
      tester,
      size: const Size(844, 390),
      feed_height: 0,
    );
    expect(controller.position.maxScrollExtent, lessThan(_snap_target));
    final gesture = await _hold_drag(tester, -140);
    expect(controller.position.outOfRange, isTrue);
    await gesture.up(timeStamp: const Duration(milliseconds: 500));
    expect(controller.position.activity, isA<BallisticScrollActivity>());
    await tester.pumpAndSettle();
    expect(
      controller.offset,
      closeTo(controller.position.maxScrollExtent, 0.01),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('从瀑布流慢速回滑露出榜单后平滑回顶', (tester) async {
    final controller = await _pump_page(tester);
    controller.jumpTo(_snap_target);
    await tester.pump();
    final gesture = await _hold_drag(tester, 170);
    final release_offset = controller.offset;
    expect(release_offset, greaterThan(RankingSectionStyle.tab_bar_height));
    expect(release_offset, lessThan(_ranking_height));
    await gesture.up(timeStamp: const Duration(milliseconds: 500));
    expect(controller.position.activity, isA<DrivenScrollActivity>());
    expect(controller.offset, release_offset);
    await tester.pump();
    await tester.pump(RecommendTabStyle.snap_duration ~/ 2);
    expect(controller.offset, greaterThan(0));
    expect(controller.offset, lessThan(release_offset));
    await tester.pumpAndSettle();
    _expect_ranking_aligned(tester, controller);
  });

  for (final release_offset in <double>[20, _ranking_height - .5]) {
    testWidgets('回滑后榜单仍可见任意实际内容即回顶 offset=$release_offset', (tester) async {
      final controller = await _pump_page(tester);
      controller.jumpTo(release_offset + 60);
      await tester.pump();
      final gesture = await _hold_drag(tester, 60);
      expect(controller.offset, release_offset);
      await gesture.up(timeStamp: const Duration(milliseconds: 500));
      expect(controller.position.activity, isA<DrivenScrollActivity>());
      await tester.pumpAndSettle();
      _expect_ranking_aligned(tester, controller);
    });
  }

  for (final release_offset in <double>[
    _ranking_height,
    _ranking_height + RecommendTabStyle.recommend_top_spacing / 2,
    _snap_target + 80,
  ]) {
    testWidgets('回滑松手后榜单未真正进入视口时保留当前位置 offset=$release_offset', (tester) async {
      final controller = await _pump_page(tester);
      controller.jumpTo(release_offset + 100);
      await tester.pump();
      final gesture = await _hold_drag(tester, 100);
      expect(controller.offset, release_offset);
      await gesture.up(timeStamp: const Duration(milliseconds: 500));
      expect(controller.position.activity, isNot(isA<DrivenScrollActivity>()));
      await tester.pumpAndSettle();
      expect(controller.offset, closeTo(release_offset, 0.01));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('快速向下回甩露出榜单后直接进入回顶动画', (tester) async {
    final controller = await _pump_page(tester);
    controller.jumpTo(_snap_target + 100);
    await tester.pump();
    await tester.fling(find.byKey(_viewport_key), const Offset(0, 170), 2400);
    expect(controller.offset, greaterThan(0));
    expect(controller.offset, lessThan(_ranking_height));
    expect(controller.position.activity, isA<DrivenScrollActivity>());
    await tester.pumpAndSettle();
    _expect_ranking_aligned(tester, controller);
  });

  testWidgets('回甩在瀑布流松手后由原生惯性进入榜单并继续平滑回顶', (tester) async {
    final controller = await _pump_page(tester);
    controller.jumpTo(700);
    await tester.pump();
    await tester.fling(find.byKey(_viewport_key), const Offset(0, 80), 800);
    expect(controller.offset, greaterThan(_ranking_height));
    expect(controller.position.activity, isA<BallisticScrollActivity>());

    var saw_ranking_during_inertia = false;
    var saw_return_animation = false;
    double? return_start_offset;
    await tester.pump();
    for (var frame = 0; frame < 400; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (controller.position.activity is BallisticScrollActivity &&
          controller.offset > 0 &&
          controller.offset < _ranking_height) {
        saw_ranking_during_inertia = true;
      }
      if (controller.position.activity is DrivenScrollActivity) {
        saw_return_animation = true;
        return_start_offset = controller.offset;
        break;
      }
    }
    expect(saw_ranking_during_inertia, isTrue);
    expect(
      saw_return_animation,
      isTrue,
      reason: '手动惯性在榜单内停下时应继续回顶，当前offset=${controller.offset}',
    );
    expect(return_start_offset, greaterThan(0));
    expect(return_start_offset, lessThan(_ranking_height));
    await tester.pump();
    await tester.pump(RecommendTabStyle.snap_duration ~/ 2);
    expect(controller.offset, greaterThan(0));
    expect(controller.offset, lessThan(return_start_offset!));
    await tester.pumpAndSettle();
    _expect_ranking_aligned(tester, controller);
  });

  testWidgets('保留手动回滑方向后程序越界动画只回弹到短内容末尾', (tester) async {
    final controller = await _pump_page(
      tester,
      size: const Size(844, 390),
      feed_height: 50,
    );
    final max_extent = controller.position.maxScrollExtent;
    expect(max_extent, greaterThan(40));
    expect(max_extent, lessThan(_ranking_height));
    controller.jumpTo(max_extent - 10);
    await tester.pump();
    final gesture = await _hold_drag(tester, 20);
    expect(controller.position.userScrollDirection, ScrollDirection.forward);

    controller.animateTo(
      max_extent + 60,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
    expect(controller.position.activity, isA<DrivenScrollActivity>());
    expect(controller.position.userScrollDirection, ScrollDirection.forward);
    await gesture.up(timeStamp: const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
    await tester.pump(const Duration(milliseconds: 16));
    expect(controller.position.outOfRange, isTrue);
    expect(controller.position.activity, isA<BallisticScrollActivity>());
    await tester.pumpAndSettle();
    expect(controller.offset, closeTo(max_extent, 0.01));
    expect(controller.offset, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('榜单范围内快速上甩在松手时直接进入吸附动画', (tester) async {
    final controller = await _pump_page(tester);
    await tester.fling(find.byKey(_viewport_key), const Offset(0, -160), 2400);
    expect(controller.offset, greaterThan(RankingSectionStyle.tab_bar_height));
    expect(controller.offset, lessThan(_ranking_height));
    expect(controller.position.activity, isA<DrivenScrollActivity>());
    await tester.pumpAndSettle();
    _expect_feed_aligned(tester, controller);
  });

  testWidgets('松手前已滑过榜单时保留原生惯性', (tester) async {
    final controller = await _pump_page(tester);
    await tester.fling(find.byKey(_viewport_key), const Offset(0, -450), 1800);
    final release_offset = controller.offset;
    expect(release_offset, greaterThan(_ranking_height));
    expect(controller.position.activity, isA<BallisticScrollActivity>());
    await tester.pumpAndSettle();
    expect(controller.offset, greaterThan(release_offset));
    expect(tester.takeException(), isNull);
  });

  testWidgets('程序滚动与返回顶部不触发吸附', (tester) async {
    final controller = await _pump_page(tester);
    controller.jumpTo(100);
    await tester.pumpAndSettle();
    expect(controller.offset, 100);
    controller.animateTo(
      160,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
    await tester.pumpAndSettle();
    expect(controller.offset, 160);
    controller.animateTo(
      80,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
    await tester.pumpAndSettle();
    expect(controller.offset, 80);
    controller.animateTo(
      0,
      duration: RecommendTabStyle.snap_duration,
      curve: Curves.easeOutCubic,
    );
    await tester.pumpAndSettle();
    expect(controller.offset, 0);
  });

  testWidgets('横向榜单滚动不改变外层位置', (tester) async {
    final controller = await _pump_page(tester);
    controller.jumpTo(100);
    await tester.pump();
    final horizontal_finder = find.byKey(_horizontal_key);
    expect(horizontal_finder, findsOneWidget);
    await tester.fling(horizontal_finder, const Offset(-180, 0), 1000);
    await tester.pumpAndSettle();
    final horizontal_scrollable = find.descendant(
      of: horizontal_finder,
      matching: find.byType(Scrollable),
    );
    expect(horizontal_scrollable, findsOneWidget);
    expect(
      tester.state<ScrollableState>(horizontal_scrollable).position.pixels,
      greaterThan(0),
    );
    expect(controller.offset, 100);
  });

  testWidgets('减少动态效果设置在松手时生效', (tester) async {
    var disable_animations = false;
    final controller = await _pump_page(
      tester,
      disable_animations: () => disable_animations,
    );
    final gesture = await _hold_drag(tester, -140);
    disable_animations = true;
    await gesture.up(timeStamp: const Duration(milliseconds: 500));
    expect(controller.offset, _snap_target);
    expect(controller.position.activity, isNot(isA<DrivenScrollActivity>()));
    await tester.pumpAndSettle();
    _expect_feed_aligned(tester, controller);
  });

  testWidgets('正向吸附动画被下拉打断后按新方向回到榜单顶部', (tester) async {
    final controller = await _pump_page(tester);
    final gesture = await _hold_drag(tester, -140);
    await gesture.up(timeStamp: const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final interrupt_gesture = await _hold_drag(tester, 70);
    final release_offset = controller.offset;
    expect(release_offset, greaterThan(0));
    expect(release_offset, lessThan(_ranking_height));
    await interrupt_gesture.up(timeStamp: const Duration(milliseconds: 500));
    expect(controller.position.activity, isA<DrivenScrollActivity>());
    await tester.pumpAndSettle();
    _expect_ranking_aligned(tester, controller);
  });

  testWidgets('回顶动画可被新的上滑中断并停靠瀑布流', (tester) async {
    final controller = await _pump_page(tester);
    controller.jumpTo(_snap_target);
    await tester.pump();
    final gesture = await _hold_drag(tester, 170);
    final return_release_offset = controller.offset;
    await gesture.up(timeStamp: const Duration(milliseconds: 500));
    expect(controller.position.activity, isA<DrivenScrollActivity>());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final offset_before_interrupt = controller.offset;
    expect(offset_before_interrupt, greaterThan(0));
    expect(offset_before_interrupt, lessThan(return_release_offset));
    final interrupt_gesture = await _hold_drag(tester, -100);
    final release_offset = controller.offset;
    expect(release_offset, greaterThan(offset_before_interrupt));
    expect(release_offset, greaterThan(RankingSectionStyle.tab_bar_height));
    expect(release_offset, lessThan(_ranking_height));
    await interrupt_gesture.up(timeStamp: const Duration(milliseconds: 500));
    expect(controller.position.activity, isA<DrivenScrollActivity>());
    await tester.pumpAndSettle();
    _expect_feed_aligned(tester, controller);
  });

  testWidgets('回滑磁吸在减少动态效果开启时直接回顶', (tester) async {
    var disable_animations = false;
    final controller = await _pump_page(
      tester,
      disable_animations: () => disable_animations,
    );
    controller.jumpTo(_snap_target);
    await tester.pump();
    final gesture = await _hold_drag(tester, 170);
    disable_animations = true;
    await gesture.up(timeStamp: const Duration(milliseconds: 500));
    expect(controller.offset, 0);
    expect(controller.position.activity, isNot(isA<DrivenScrollActivity>()));
    await tester.pumpAndSettle();
    _expect_ranking_aligned(tester, controller);
  });

  for (final (name, size, brightness) in <(String, Size, Brightness)>[
    ('竖屏', const Size(390, 844), Brightness.light),
    ('横屏夜间', const Size(844, 390), Brightness.dark),
    ('Duo窄屏夜间', const Size(440, 760), Brightness.dark),
    ('Duo展开宽屏', const Size(900, 800), Brightness.light),
  ]) {
    testWidgets('$name下双向磁吸均准确贴齐可视区域顶部', (tester) async {
      final controller = await _pump_page(
        tester,
        size: size,
        brightness: brightness,
      );
      final gesture = await _hold_drag(tester, -140);
      await gesture.up(timeStamp: const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      _expect_feed_aligned(tester, controller);
      final reverse_gesture = await _hold_drag(tester, 170);
      await reverse_gesture.up(timeStamp: const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      _expect_ranking_aligned(tester, controller);
    });
  }

  testWidgets('下拉刷新不会触发向瀑布流吸附', (tester) async {
    var refresh_calls = 0;
    final controller = await _pump_page(
      tester,
      on_refresh: () async => refresh_calls++,
    );
    final gesture = await _hold_drag(tester, 320);
    await gesture.up(timeStamp: const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(refresh_calls, 1);
    expect(controller.offset, 0);
    expect(tester.takeException(), isNull);
  });
}

/// TODO 使用真实滚动控制器和占位内容，只验证手势与滚动动画，避免网络依赖。
Future<RecommendScrollController> _pump_page(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  Brightness brightness = Brightness.light,
  double feed_height = 2000,
  bool Function()? disable_animations,
  Future<void> Function()? on_refresh,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final controller = RecommendScrollController(
    disable_animations: disable_animations ?? () => false,
  );
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(platform: TargetPlatform.iOS, brightness: brightness),
      home: Scaffold(
        appBar: AppBar(title: const Text('推荐')),
        body: RefreshIndicator(
          onRefresh: on_refresh ?? () async {},
          child: ListView(
            key: _viewport_key,
            controller: controller,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: EdgeInsets.zero,
            children: [
              SizedBox(
                key: _ranking_key,
                height: _ranking_height,
                child: Column(
                  children: [
                    const SizedBox(height: 120),
                    SizedBox(
                      height: 80,
                      child: ListView(
                        key: _horizontal_key,
                        scrollDirection: Axis.horizontal,
                        children: const [SizedBox(width: 1800, height: 80)],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: RecommendTabStyle.recommend_top_spacing),
              SizedBox(key: _feed_key, height: feed_height),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return controller;
}

/// TODO 同时检查偏移和真实榜单面板位置，避免回顶时残留裁切或间隙。
void _expect_ranking_aligned(
  WidgetTester tester,
  RecommendScrollController controller,
) {
  expect(controller.offset, closeTo(0, 0.01));
  expect(find.byKey(_ranking_key), findsOneWidget);
  expect(
    tester.getTopLeft(find.byKey(_ranking_key)).dy,
    closeTo(tester.getTopLeft(find.byKey(_viewport_key)).dy, 0.01),
  );
  expect(tester.takeException(), isNull);
}

/// TODO 分开移动和松手，验证拖动期间不吸附，并以停顿消除原生甩动速度。
Future<TestGesture> _hold_drag(WidgetTester tester, double delta) async {
  final viewport = find.byKey(_viewport_key);
  expect(viewport, findsOneWidget);
  final viewport_rect = tester.getRect(viewport);
  final gesture = await tester.startGesture(
    Offset(
      viewport_rect.center.dx,
      viewport_rect.top + viewport_rect.height * .8,
    ),
  );
  await gesture.moveBy(
    Offset(0, delta),
    timeStamp: const Duration(milliseconds: 100),
  );
  await tester.pump(const Duration(milliseconds: 100));
  await gesture.moveBy(
    Offset.zero,
    timeStamp: const Duration(milliseconds: 400),
  );
  await tester.pump(const Duration(milliseconds: 300));
  return gesture;
}

/// TODO 同时断言滚动偏移与实际布局位置，确保瀑布流贴齐可视区域顶部。
void _expect_feed_aligned(
  WidgetTester tester,
  RecommendScrollController controller,
) {
  expect(controller.offset, closeTo(_snap_target, 0.01));
  expect(find.byKey(_feed_key), findsOneWidget);
  expect(
    tester.getTopLeft(find.byKey(_feed_key)).dy,
    closeTo(tester.getTopLeft(find.byKey(_viewport_key)).dy, 0.01),
  );
  expect(tester.takeException(), isNull);
}
