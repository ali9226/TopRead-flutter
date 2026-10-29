// ignore_for_file: non_constant_identifier_names

import 'package:app/components/fixed_bottom_navigation/index.dart';
import 'package:app/main.dart' as app;
import 'package:app/pages/home/widgets/home_tab_bar/index.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// TODO integration_test 冒烟：真实模拟器 + 真实接口。
/// 验证 App 能完整启动、首页框架（顶栏 tab + 底部导航）渲染且无渲染异常。
/// 注意：本测试走真实网络与真实账号环境，不注入假数据；断言以壳层稳定组件为准。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('真实模拟器冒烟：启动后首页框架可见且无异常', (tester) async {
    app.main();

    // TODO 启动含 Firebase/存储初始化与首屏网络请求；pump 推进帧不等于请求完成，
    // 这里用明确的等待条件（底部导航出现）+ 上限 30 秒，不用 pumpAndSettle（有无限动画会超时）。
    final bottom_nav = find.byType(FixedBottomNavigation);
    final home_tabs = find.byType(HomeTabBar);
    for (var i = 0; i < 30 && bottom_nav.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    expect(tester.takeException(), isNull, reason: '启动过程不应有渲染异常');
    expect(bottom_nav, findsOneWidget, reason: '底部导航应已渲染');
    expect(home_tabs, findsOneWidget, reason: '首页顶部分类 tab 应已渲染');

    // TODO live 绑定收尾：真实引擎可能仍在调度帧，排空在途帧避免 _pendingFrame 抖动。
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
  });
}
