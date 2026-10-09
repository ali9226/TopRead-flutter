// ignore_for_file: non_constant_identifier_names

import 'package:app/components/app_wrapper/utils/app_router.dart';
import 'package:app/fcm/fcm_handler.dart';
import 'package:app/stores/comment_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  tearDown(CommentNavigation.consume);

  Future<GoRouter> mount_router(WidgetTester tester, String location) async {
    final GoRouter router = GoRouter(
      initialLocation: location,
      routes: [
        for (final String path in [
          '/',
          '/read',
          '/short_story_read',
          '/read_archive',
        ])
          GoRoute(
            path: path,
            builder: (_, state) => Scaffold(body: Text(state.uri.toString())),
          ),
      ],
    );
    AppRouter.setRouter(router);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    return router;
  }

  for (final String path in ['/read', '/short_story_read']) {
    testWidgets('推送评论保留 $path 当前小说页面', (tester) async {
      await mount_router(tester, '$path?id=12&title=reader');

      FcmHandler.onMessageTap({
        'type': 4,
        'novel_id': 12,
        'publish_status': path == '/read' ? 1 : 4,
        'comment_id': 35,
      });
      await tester.pumpAndSettle();

      expect(AppRouter.currentLocation(), '$path?id=12&title=reader');
      expect(CommentNavigation.pending_novel_id.value, 12);
      expect(CommentNavigation.pending_comment_id.value, 35);
    });
  }

  testWidgets('相同 ID 前缀不能误认为当前小说', (tester) async {
    await mount_router(tester, '/read?id=123');
    FcmHandler.onMessageTap({
      'type': '4',
      'novel_id': '12',
      'comment_id': '35',
    });
    await tester.pumpAndSettle();

    expect(AppRouter.currentLocation(), '/read?id=12&comment_id=35');
    expect(CommentNavigation.pending_comment_id.value, 0);
  });

  testWidgets('push 栈顶的小说 URI 和路径用于定位当前评论', (tester) async {
    final GoRouter router = await mount_router(tester, '/');
    AppRouter.push('/read?id=12&title=reader');
    await tester.pumpAndSettle();
    final RouteMatch current_match =
        router.routerDelegate.currentConfiguration.last;

    expect(AppRouter.currentPath(), '/read');
    expect(AppRouter.currentLocation(), '/read?id=12&title=reader');
    FcmHandler.onMessageTap({
      'type': '4',
      'novel_id': '12',
      'comment_id': '35',
    });
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.last,
      same(current_match),
    );
    expect(CommentNavigation.pending_comment_id.value, 35);
  });

  testWidgets('路由前缀相同但页面不同需要导航', (tester) async {
    await mount_router(tester, '/read_archive?id=12');
    FcmHandler.onMessageTap({'type': '4', 'novel_id': '12', 'parent_id': '35'});
    await tester.pumpAndSettle();

    expect(AppRouter.currentLocation(), '/read?id=12&comment_id=35');
    expect(CommentNavigation.pending_comment_id.value, 0);
  });
}
