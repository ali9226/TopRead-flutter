// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/models/comics_discovery.dart';
import 'package:app/models/novel_discovery.dart';
import 'package:app/services/recommendation_refresh/index.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('首页和分页都解析服务器画像等待标记，旧响应默认无需补请求', () {
    expect(
      ComicDiscoveryFeed.from_json({'profile_pending': true}).profile_pending,
      isTrue,
    );
    expect(
      ComicDiscoveryPage.from_json({'profile_pending': true}).profile_pending,
      isTrue,
    );
    expect(
      NovelDiscoveryFeed.from_json({'profile_pending': true}).profile_pending,
      isTrue,
    );
    expect(
      NovelDiscoveryPage.from_json({'profile_pending': true}).profile_pending,
      isTrue,
    );
    expect(ComicDiscoveryFeed.from_json({}).profile_pending, isFalse);
    expect(NovelDiscoveryPage.from_json({}).profile_pending, isFalse);
  });

  testWidgets('画像持续等待时最多补三次，成功后停止后续请求', (tester) async {
    final route = ValueNotifier(0);
    var requests = 0;
    final retry = RecommendationPendingRefresh(
      route_changes: route,
      is_visible: () => true,
      context_key: () => 'account-en',
      can_refresh: () => true,
      on_refresh: () async => requests++,
    );
    addTearDown(retry.dispose);
    addTearDown(route.dispose);
    retry.observe(true);
    for (var index = 0; index < 6; index++) {
      await tester.pump(RecommendationPendingRefresh.delay);
    }
    expect(requests, 3);
    retry.observe(false);
    retry.observe(true);
    await tester.pump(RecommendationPendingRefresh.delay);
    expect(requests, 4);
    retry.observe(false);
    await tester.pump(const Duration(seconds: 10));
    expect(requests, 4);
  });

  testWidgets('隐藏时不请求，重新可见才继续；旧账号或语种的定时器失效', (tester) async {
    final route = ValueNotifier(0);
    var visible = true;
    var scope = 'account-a-en';
    var requests = 0;
    final retry = RecommendationPendingRefresh(
      route_changes: route,
      is_visible: () => visible,
      context_key: () => scope,
      can_refresh: () => true,
      on_refresh: () async => requests++,
    );
    addTearDown(retry.dispose);
    addTearDown(route.dispose);
    retry.observe(true);
    visible = false;
    route.value++;
    await tester.pump(const Duration(seconds: 10));
    expect(requests, 0);
    visible = true;
    route.value++;
    await tester.pump(RecommendationPendingRefresh.delay);
    expect(requests, 1);
    scope = 'account-b-zh';
    await tester.pump(RecommendationPendingRefresh.delay);
    expect(requests, 1);
    retry.observe(true);
    await tester.pump(RecommendationPendingRefresh.delay);
    expect(requests, 2);
    retry.observe(false);
  });

  testWidgets('翻页或首屏另有在途请求时不覆盖，完成后只按当前条件继续', (tester) async {
    final route = ValueNotifier(0);
    final content = ValueNotifier(0);
    var can_refresh = false;
    var requests = 0;
    final retry = RecommendationPendingRefresh(
      route_changes: route,
      content_changes: content,
      is_visible: () => true,
      context_key: () => 'account-category-12',
      can_refresh: () => can_refresh,
      on_refresh: () async => requests++,
    );
    addTearDown(retry.dispose);
    addTearDown(route.dispose);
    addTearDown(content.dispose);
    retry.observe(true);
    await tester.pump(const Duration(seconds: 10));
    expect(requests, 0);
    can_refresh = true;
    content.value++;
    await tester.pump(RecommendationPendingRefresh.delay);
    expect(requests, 1);
    can_refresh = false;
    content.value++;
    await tester.pump(const Duration(seconds: 10));
    expect(requests, 1);
  });

  testWidgets('销毁和手动重置取消旧任务，在途补请求也不再排队', (tester) async {
    final route = ValueNotifier(0);
    final pending = Completer<void>();
    var requests = 0;
    final retry = RecommendationPendingRefresh(
      route_changes: route,
      is_visible: () => true,
      context_key: () => 'account-en',
      can_refresh: () => true,
      on_refresh: () async {
        requests++;
        await pending.future;
      },
    );
    addTearDown(route.dispose);
    retry.observe(true);
    retry.reset();
    await tester.pump(const Duration(seconds: 10));
    expect(requests, 0);
    retry.observe(true);
    await tester.pump(RecommendationPendingRefresh.delay);
    expect(requests, 1);
    retry.dispose();
    pending.complete();
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));
    expect(requests, 1);
  });
}
