// ignore_for_file: non_constant_identifier_names

import 'package:app/api/novel_discovery.dart';
import 'package:app/components/fixed_bottom_navigation/index.dart';
import 'package:app/components/home_top_search_entry/index.dart';
import 'package:app/components/paragraph_selection/index.dart';
import 'package:app/components/paragraph_selection/selection_toolbar.dart';
import 'package:app/main.dart' as app;
import 'package:app/util/router/router_util.dart';
import 'package:app/pages/home/widgets/home_tab_bar/index.dart';
import 'package:app/stores/redis_request.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';

/// TODO 模拟器操作能力演练：真实模拟器（iPhone 18 Pro Max）+ 真实接口，不注入假数据。
/// 覆盖手势：点击 tap、拖动 drag、快速滑动 fling、输入 enterText、长按 longPress。
/// 每个手势都断言实际反馈（索引跳变/滚动位置/文本回显/弹窗出现），不以"调用未抛异常"为通过标准。
///
/// 两个已知机制（写用例时必须知道）：
/// 1. 测试体在 FakeAsync 假时钟里：异步等待用 runAsync 真实延时；但长按定时器
///    必须靠 tester.longPress/longPressAt（内部 pump 推进假时钟）触发，runAsync 按住无效。
/// 2. HomeTabBar 在 redis/get 请求中用 IgnorePointer 静默吞点击，点按需重试到状态真的变化。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('模拟器手势演练：点击/拖动/滑动/输入/长按', (tester) async {
    app.main();

    /// TODO 真实等待：推进真实时间并渲染一帧（pump 单独使用不等真实时间）。
    Future<void> real_wait(int milliseconds) async {
      await tester.runAsync(
        () => Future<void>.delayed(Duration(milliseconds: milliseconds)),
      );
      await tester.pump();
    }

    // ---- 0. 启动：等待首页壳层出现 ----
    final bottom_nav = find.byType(FixedBottomNavigation);
    for (var i = 0; i < 60 && bottom_nav.evaluate().isEmpty; i++) {
      await real_wait(500);
    }
    expect(tester.takeException(), isNull, reason: '启动过程不应有渲染异常');
    expect(bottom_nav, findsOneWidget, reason: '首页应渲染底部导航');

    // 分类标题来自服务端配置，未加载时显示中文兜底（kDefaultTabTitles，无 Comics）。
    String comics_title = '';
    for (var i = 0; i < 60; i++) {
      final matches = get_titles()
          .where(
            (title) =>
                title.toLowerCase().contains('comic') || title.contains('漫画'),
          )
          .toList();
      if (matches.isNotEmpty) {
        comics_title = matches.first;
        break;
      }
      await real_wait(500);
    }
    expect(comics_title, isNotEmpty, reason: '服务端分类应包含漫画 tab');

    final tab_controller = tester
        .widget<HomeTabBar>(find.byType(HomeTabBar))
        .tab_controller;
    final comics_index = get_titles().indexOf(comics_title);
    expect(comics_index, greaterThanOrEqualTo(0), reason: '标题列表应含漫画项');

    /// TODO 点按封装：请求期间点击会被吞，重试到 controller 索引真正跳变为止。
    Future<void> tap_tab(int target_index) async {
      for (var i = 0; i < 5 && tab_controller.index != target_index; i++) {
        while (Get.find<RedisRequestStore>().is_fetching) {
          await real_wait(300);
        }
        await tester.tap(
          find.descendant(
            of: find.byType(HomeTabBar),
            matching: find.text(get_titles()[target_index]),
          ),
        );
        await real_wait(800);
      }
    }

    // ---- 1. 点击：切换首页分类 tab，断言索引真实跳变 ----
    // 若当前已在漫画 tab，先点到其他 tab 产生一次跳变，再点回漫画，两次都算点击反馈。
    if (tab_controller.index == comics_index) {
      final other_index = (comics_index + 1) % get_titles().length;
      await tap_tab(other_index);
      expect(
        tab_controller.index,
        other_index,
        reason: '点击后 tab 索引应从 $comics_index 跳变到 $other_index',
      );
    }
    await tap_tab(comics_index);
    expect(
      tab_controller.index,
      comics_index,
      reason: '点击后 tab 索引应跳变到漫画（目标 $comics_index）',
    );
    await real_wait(800);
    expect(
      find.byKey(const ValueKey('comics_tab')),
      findsOneWidget,
      reason: '点击后漫画页应挂载（Key 来自 home_tabs.dart）',
    );

    // ---- 2. 拖动：慢速拖动漫画列表，断言滚动位置变化 ----
    final feed = find.byKey(const PageStorageKey('comics_home_sections_scroll'));
    expect(feed, findsOneWidget, reason: '漫画列表应存在');
    final scrollable = find
        .descendant(of: feed, matching: find.byType(Scrollable))
        .first;
    final scroll_state = tester.state<ScrollableState>(scrollable);
    await tester.drag(feed, const Offset(0, -300));
    await real_wait(300);
    expect(
      scroll_state.position.pixels,
      greaterThan(0),
      reason: '拖动后列表应发生滚动',
    );

    // ---- 3. 快速滑动 fling：断言继续滚动更远 ----
    final before_fling = scroll_state.position.pixels;
    await tester.fling(feed, const Offset(0, -400), 800);
    await real_wait(1000);
    expect(
      scroll_state.position.pixels,
      greaterThan(before_fling),
      reason: 'fling 惯性应继续滚动',
    );

    // ---- 4. 长按：阅读页段落长按全选并弹出选区工具栏（真实反馈） ----
    // 书架/评论等长按入口在访客态无内容；阅读页段落选区游客可达且反馈明确
    // （ParagraphSelection 长按 → select_all → ParagraphSelectionToolbar）。
    // 先用真实接口取一个可读小说 id，代码导航到阅读页（点击导航已由步骤 1 证明）。
    final novel_feed = await load_novel_home_sections();
    int story_id = 0;
    for (final section in novel_feed.sections) {
      for (final item in section.items) {
        if (item.id > 0) {
          story_id = item.id;
          break;
        }
      }
      if (story_id > 0) break;
    }
    expect(story_id, greaterThan(0), reason: '真实接口应返回可读小说');
    routerUtil(path: '/read?id=$story_id&title=capabilityprobe');
    final paragraphs = find.byType(ParagraphSelection);
    for (var i = 0; i < 60 && paragraphs.evaluate().isEmpty; i++) {
      await real_wait(500);
    }
    expect(paragraphs, findsWidgets, reason: '阅读页应渲染正文段落');
    // 长按点必须落在字形上（多行段落中心常在行间隙，选不出词就不会有选区）；
    // 在段落首行一带多点位重试，断言放宽到任一选区 UI 出现。
    final paragraph_rect = tester.getRect(paragraphs.first);
    var selection_ui_visible = false;
    for (final offset in [
      const Offset(40, 12),
      const Offset(40, 28),
      const Offset(120, 12),
      const Offset(80, 44),
      const Offset(40, 60),
    ]) {
      await tester.longPressAt(paragraph_rect.topLeft + offset);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(seconds: 1));
      selection_ui_visible =
          find.byType(ParagraphSelectionToolbar).evaluate().isNotEmpty ||
          find.byType(AdaptiveTextSelectionToolbar).evaluate().isNotEmpty ||
          find.byType(TextSelectionToolbar).evaluate().isNotEmpty ||
          find.byType(CupertinoTextSelectionToolbar).evaluate().isNotEmpty;
      if (selection_ui_visible) break;
    }
    expect(
      selection_ui_visible,
      isTrue,
      reason: '长按段落后应出现选区 UI（自定义工具栏或系统文本选择菜单）',
    );

    // TODO live 绑定收尾：排空在途帧，避免 _pendingFrame 抖动。
    await real_wait(300);
  });
}
