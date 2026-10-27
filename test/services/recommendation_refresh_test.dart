// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/services/recommendation_refresh/index.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('只接受兴趣写入，读取接口和零秒计时锚点不触发推荐刷新', () {
    final signals = RecommendationRefreshSignals();
    addTearDown(signals.dispose);
    signals.record_success('novel/home_sections');
    signals.record_success('comics/discover');
    signals.record_success(
      'novel_read_record/save_progress',
      parameters: {'reading_only': true, 'reading_seconds': 0},
    );
    expect(signals.revision, 0);
    for (final path in [
      'user_preference/choose',
      'novel_favorite/click',
      'novel_comment/add',
      'paragraph_comment/reply',
      'comics/collect',
      'comics_comment/add',
    ]) {
      signals.record_success(path);
    }
    signals.record_success(
      'novel_read_record/save_progress',
      parameters: {'reading_only': true, 'reading_seconds': 10},
    );
    expect(signals.revision, 7);
  });

  testWidgets('阅读期间多次心跳不请求首页，返回页面后只刷新一次', (tester) async {
    final signals = RecommendationRefreshSignals();
    final route = ValueNotifier(0);
    var visible = false;
    var requests = 0;
    final subscription = RecommendationRefreshSubscription(
      signals: signals,
      route_changes: route,
      is_visible: () => visible,
      on_refresh: () async => requests++,
    );
    addTearDown(subscription.dispose);
    addTearDown(route.dispose);
    addTearDown(signals.dispose);
    for (var index = 0; index < 20; index++) {
      signals.record_success('comics/save_progress');
      await tester.pump(const Duration(seconds: 10));
    }
    expect(requests, 0);
    visible = true;
    route.value++;
    await tester.pump(RecommendationRefreshSubscription.debounce);
    expect(requests, 1);
    route.value++;
    await tester.pump(const Duration(seconds: 2));
    expect(requests, 1);
  });

  testWidgets('并发行为合并，刷新途中新增的兴趣再请求一次', (tester) async {
    final signals = RecommendationRefreshSignals();
    final route = ValueNotifier(0);
    final pending = Completer<void>();
    var requests = 0;
    final subscription = RecommendationRefreshSubscription(
      signals: signals,
      route_changes: route,
      is_visible: () => true,
      on_refresh: () async {
        requests++;
        if (requests == 1) await pending.future;
      },
    );
    addTearDown(subscription.dispose);
    addTearDown(route.dispose);
    addTearDown(signals.dispose);
    signals.record_success('novel_like/click');
    signals.record_success('novel_favorite/click');
    await tester.pump(RecommendationRefreshSubscription.debounce);
    expect(requests, 1);
    signals.record_success('novel_comment/add');
    signals.record_success('user_preference/choose');
    await tester.pump(const Duration(seconds: 2));
    expect(requests, 1);
    pending.complete();
    await tester.pump();
    await tester.pump(RecommendationRefreshSubscription.debounce);
    expect(requests, 2);
  });

  testWidgets('主动刷新已读取最新行为，切回页面不重复请求', (tester) async {
    final signals = RecommendationRefreshSignals();
    final route = ValueNotifier(0);
    var requests = 0;
    final subscription = RecommendationRefreshSubscription(
      signals: signals,
      route_changes: route,
      is_visible: () => true,
      on_refresh: () async => requests++,
    );
    addTearDown(subscription.dispose);
    addTearDown(route.dispose);
    addTearDown(signals.dispose);
    signals.record_success('user_preference/choose');
    subscription.acknowledge(signals.revision);
    route.value++;
    await tester.pump(RecommendationRefreshSubscription.debounce);
    expect(requests, 0);
  });

  testWidgets('隐藏页面身份失效，返回时刷新；销毁后不触发请求', (tester) async {
    final signals = RecommendationRefreshSignals();
    final route = ValueNotifier(0);
    var visible = false;
    var requests = 0;
    final subscription = RecommendationRefreshSubscription(
      signals: signals,
      route_changes: route,
      is_visible: () => visible,
      on_refresh: () async => requests++,
    );
    addTearDown(route.dispose);
    addTearDown(signals.dispose);
    subscription.invalidate();
    await tester.pump(RecommendationRefreshSubscription.debounce);
    expect(requests, 0);
    visible = true;
    route.value++;
    await tester.pump(RecommendationRefreshSubscription.debounce);
    expect(requests, 1);
    signals.record_success('comics/collect');
    subscription.dispose();
    await tester.pump(RecommendationRefreshSubscription.debounce);
    expect(requests, 1);
  });
}
