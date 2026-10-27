// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/models/novel_discovery.dart';
import 'package:app/pages/novel_discovery/browse/logic.dart';
import 'package:flutter_test/flutter_test.dart';

NovelDiscoveryPage _page(
  List<int> ids, {
  int page = 1,
  int total = 100,
  String seed = 'seed-a',
}) => NovelDiscoveryPage(
  items: ids
      .map(
        (id) => NovelDiscoveryItem.from_json({'id': id, 'title': 'Novel $id'}),
      )
      .toList(),
  total: total,
  page: page,
  page_size: 24,
  seed: seed,
);

Future<void> _flush() async {
  for (var index = 0; index < 6; index++) {
    await Future<void>.value();
  }
}

void main() {
  test('真实分类去重且初始无效分类回到首项，不伪造列表', () async {
    final requests = <int>[];
    final logic = NovelBrowseLogic(
      categories_loader: () async => [
        {'id': 4},
        {'id': 4},
        {'id': 9},
        {'id': 0},
      ],
      page_loader:
          ({
            required category_id,
            required page,
            required page_size,
            seed,
            language,
          }) async {
            requests.add(category_id);
            return _page([category_id], total: 1);
          },
    );
    addTearDown(logic.dispose);
    await logic.initialize();
    await _flush();
    expect(logic.categories.map((item) => item['id']), [4, 9]);
    expect(logic.selected_category_id, 4);
    expect(requests, [4]);
  });

  test('切分类保留各自分页与种子，返回已加载分类无需重新请求', () async {
    final requests = <(int, int, String?)>[];
    final logic = NovelBrowseLogic(
      initial_category_id: 2,
      categories_loader: () async => [
        {'id': 1},
        {'id': 2},
      ],
      page_loader:
          ({
            required category_id,
            required page,
            required page_size,
            seed,
            language,
          }) async {
            requests.add((category_id, page, seed));
            return _page(
              [category_id * 100 + page],
              page: page,
              seed: 'seed-$category_id',
            );
          },
    );
    addTearDown(logic.dispose);
    await logic.initialize(language: 'zh');
    await _flush();
    logic.select_category(1);
    await _flush();
    await logic.load_more(1);
    logic.select_category(2);
    await _flush();
    expect(requests, [(2, 1, null), (1, 1, null), (1, 2, 'seed-1')]);
    expect(logic.state_for(1).items.map((item) => item.id), [101, 102]);
    expect(logic.state_for(2).items.map((item) => item.id), [201]);
    expect(logic.state_for(1).page, 2);
  });

  test('快速刷新替代未完成首屏，迟到响应不能覆盖新种子与结果', () async {
    final first = Completer<NovelDiscoveryPage>();
    final fresh = Completer<NovelDiscoveryPage>();
    var requests = 0;
    final logic = NovelBrowseLogic(
      initial_category_id: 1,
      categories_loader: () async => [
        {'id': 1},
      ],
      page_loader:
          ({
            required category_id,
            required page,
            required page_size,
            seed,
            language,
          }) {
            expect(seed, isNull);
            return ++requests == 1 ? first.future : fresh.future;
          },
    );
    addTearDown(logic.dispose);
    await logic.initialize();
    final refresh = logic.refresh(1);
    fresh.complete(_page([9], seed: 'new-seed'));
    await refresh;
    first.complete(_page([1], seed: 'old-seed'));
    await _flush();
    expect(logic.state_for(1).items.single.id, 9);
    expect(logic.state_for(1).seed, 'new-seed');
    expect(logic.state_for(1).busy, isFalse);
  });

  test('自动分页入口去重，刷新后迟到旧分页被丢弃', () async {
    final more = Completer<NovelDiscoveryPage>();
    var initial_requests = 0;
    var more_requests = 0;
    final logic = NovelBrowseLogic(
      initial_category_id: 1,
      categories_loader: () async => [
        {'id': 1},
      ],
      page_loader:
          ({
            required category_id,
            required page,
            required page_size,
            seed,
            language,
          }) async {
            if (page > 1) {
              more_requests++;
              expect(seed, 'old-seed');
              return more.future;
            }
            initial_requests++;
            return _page([
              initial_requests == 1 ? 1 : 50,
            ], seed: initial_requests == 1 ? 'old-seed' : 'new-seed');
          },
    );
    addTearDown(logic.dispose);
    await logic.initialize();
    await _flush();
    final in_flight = logic.load_more(1);
    await logic.load_more(1);
    expect(more_requests, 1);
    await logic.refresh(1);
    more.complete(_page([2], page: 2, seed: 'old-seed'));
    await in_flight;
    expect(logic.state_for(1).items.single.id, 50);
    expect(logic.state_for(1).page, 1);
    expect(logic.state_for(1).seed, 'new-seed');
  });

  test('分页失败和重试保留旧列表及原种子，刷新失败保留原内容', () async {
    var fail = false;
    final seeds = <String?>[];
    final logic = NovelBrowseLogic(
      initial_category_id: 1,
      categories_loader: () async => [
        {'id': 1},
      ],
      page_loader:
          ({
            required category_id,
            required page,
            required page_size,
            seed,
            language,
          }) async {
            seeds.add(seed);
            if (fail) throw StateError('offline');
            return _page([page], page: page);
          },
    );
    addTearDown(logic.dispose);
    await logic.initialize();
    await _flush();
    fail = true;
    await logic.load_more(1);
    expect(logic.state_for(1).items.single.id, 1);
    expect(logic.state_for(1).failed_more, isTrue);
    fail = false;
    await logic.retry(1);
    expect(logic.state_for(1).items.map((item) => item.id), [1, 2]);
    expect(seeds, [null, 'seed-a', 'seed-a']);
    fail = true;
    await logic.refresh(1);
    expect(logic.state_for(1).items.map((item) => item.id), [1, 2]);
    expect(logic.state_for(1).page, 2);
    expect(logic.state_for(1).seed, 'seed-a');
    expect(logic.state_for(1).failed_more, isFalse);
    expect(seeds.last, isNull);
  });

  test('重复空分页终止自动加载，跨分类旧响应只更新自己的状态', () async {
    final pending = Completer<NovelDiscoveryPage>();
    final logic = NovelBrowseLogic(
      initial_category_id: 1,
      categories_loader: () async => [
        {'id': 1},
        {'id': 2},
      ],
      page_loader:
          ({
            required category_id,
            required page,
            required page_size,
            seed,
            language,
          }) async {
            if (category_id == 2) return pending.future;
            return _page([1], page: page);
          },
    );
    addTearDown(logic.dispose);
    await logic.initialize();
    await _flush();
    logic.select_category(2);
    logic.select_category(1);
    await logic.load_more(1);
    expect(logic.state_for(1).has_more, isFalse);
    pending.complete(_page([22]));
    await _flush();
    expect(logic.selected_category_id, 1);
    expect(logic.state_for(1).items.single.id, 1);
    expect(logic.state_for(2).items.single.id, 22);
  });

  test('退出页面后请求完成不会通知已销毁控制器', () async {
    final pending = Completer<NovelDiscoveryPage>();
    final logic = NovelBrowseLogic(
      initial_category_id: 1,
      categories_loader: () async => [
        {'id': 1},
      ],
      page_loader:
          ({
            required category_id,
            required page,
            required page_size,
            seed,
            language,
          }) => pending.future,
    );
    var notifications = 0;
    logic.addListener(() => notifications++);
    await logic.initialize();
    final before = notifications;
    logic.dispose();
    pending.complete(_page([1]));
    await _flush();
    expect(notifications, before);
  });

  test('切换身份清空所有分类快照与种子，旧身份迟到请求不能回写', () async {
    final old_page = Completer<NovelDiscoveryPage>();
    var identity = 'first';
    final requests = <(String, int, String?, String?)>[];
    final logic = NovelBrowseLogic(
      initial_category_id: 1,
      categories_loader: () async => [
        {'id': 1},
        {'id': 2},
      ],
      page_loader:
          ({
            required category_id,
            required page,
            required page_size,
            seed,
            language,
          }) async {
            requests.add((identity, category_id, seed, language));
            if (identity == 'first' && category_id == 2) return old_page.future;
            return _page([identity == 'first' ? 1 : 99], seed: identity);
          },
    );
    addTearDown(logic.dispose);
    await logic.initialize(language: 'en');
    await _flush();
    logic.state_for(1).scroll_offset = 700;
    logic.select_category(2);
    identity = 'second';
    await logic.refresh_context(language: 'zh');
    await _flush();
    old_page.complete(_page([22], seed: 'first'));
    await _flush();
    expect(logic.selected_category_id, 2);
    expect(logic.state_for(2).items.single.id, 99);
    expect(logic.state_for(2).seed, 'second');
    expect(logic.state_for(1).items, isEmpty);
    expect(logic.state_for(1).seed, isNull);
    expect(logic.state_for(1).scroll_offset, 0);
    expect(requests.last, ('second', 2, null, 'zh'));
    expect(logic.context_revision, 1);
  });

  test('服务端分页种子重置时原子替换第一页，后续同种子才继续拼接', () async {
    var requests = 0;
    final logic = NovelBrowseLogic(
      initial_category_id: 1,
      categories_loader: () async => [
        {'id': 1},
      ],
      page_loader:
          ({
            required category_id,
            required page,
            required page_size,
            seed,
            language,
          }) async {
            requests++;
            if (requests == 1) return _page([1], seed: 'expired');
            if (requests == 2) {
              expect(page, 2);
              expect(seed, 'expired');
              return _page([99], seed: 'fresh', page: 1);
            }
            expect(seed, 'fresh');
            return _page([100], seed: 'fresh', page: 2);
          },
    );
    addTearDown(logic.dispose);
    await logic.initialize();
    await _flush();
    logic.state_for(1).scroll_offset = 700;
    await logic.load_more(1);
    expect(logic.state_for(1).items.single.id, 99);
    expect(logic.state_for(1).page, 1);
    expect(logic.state_for(1).seed, 'fresh');
    expect(logic.state_for(1).scroll_offset, 0);
    expect(logic.state_for(1).snapshot_revision, 1);
    await logic.load_more(1);
    expect(logic.state_for(1).items.map((item) => item.id), [99, 100]);
  });
}
