// ignore_for_file: non_constant_identifier_names

import 'package:app/components/app_wrapper/utils/app_router.dart';
import 'package:app/pages/user_info/view/statistics/logic.dart';
import 'package:app/stores/message_store.dart';
import 'package:app/stores/shell_tab_info.dart';
import 'package:app/stores/user_information.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('统计卡可重复切换到消息页并同步筛选类型', (tester) async {
    late MessageStore message_store;
    final GoRouter router = GoRouter(
      initialLocation: '/user_info',
      routes: <RouteBase>[
        GoRoute(
          path: '/user_info',
          builder: (context, state) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/message',
          builder: (context, state) {
            return Obx(() => Text('${message_store.filter_type}'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    AppRouter.setRouter(router);
    Get.put<UserInformation>(UserInformation());
    message_store = Get.put<MessageStore>(MessageStore());
    final ShellTabInfo shell_tab_info = Get.put<ShellTabInfo>(ShellTabInfo());
    shell_tab_info.updateActivePath('/user_info');
    final Logic logic = Logic();

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    logic.go_to_message(2);
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/message');
    expect(shell_tab_info.activePath.value, '/message');
    expect(message_store.filter_type, 2);
    expect(find.text('2'), findsOneWidget);

    shell_tab_info.updateActivePath('/user_info');
    AppRouter.go('/user_info');
    await tester.pumpAndSettle();

    logic.go_to_message(2);
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/message');
    expect(shell_tab_info.activePath.value, '/message');
    expect(message_store.filter_type, 2);
    expect(find.text('2'), findsOneWidget);

    shell_tab_info.updateActivePath('/user_info');
    AppRouter.go('/user_info');
    await tester.pumpAndSettle();

    logic.go_to_message(5);
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/message');
    expect(shell_tab_info.activePath.value, '/message');
    expect(message_store.filter_type, 5);
    expect(find.text('5'), findsOneWidget);
  });
}
