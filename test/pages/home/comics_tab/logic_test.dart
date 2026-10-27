import 'dart:async';

import 'package:app/models/comics_discovery.dart';
import 'package:app/pages/home/widgets/tab_contents/comics_tab/logic.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  test('空组、非法分类和重复分类不进入首页，保持服务端顺序', () async {
    final logic = ComicsTabLogic(
      home_loader: ({language, seed}) async => discovery_feed([
        discovery_section(8),
        discovery_section(9, count: 0),
        discovery_section(8, first_id: 30),
        discovery_section(0),
        discovery_section(3, first_id: 50),
      ]),
    );
    addTearDown(logic.dispose);
    await logic.refresh(language: 'zh');
    expect(logic.sections.map((section) => section.id), [8, 3]);
    expect(logic.has_loaded, isTrue);
    expect(logic.loading, isFalse);
  });

  test('各组独立换批、防连点、排除当前ID并延续服务端seed', () async {
    final pending = <int, Completer<ComicDiscoverySection>>{};
    final requests =
        <
          ({
            int category,
            List<int> exclude,
            List<int> reserved,
            String? seed,
            String? language,
          })
        >[];
    final logic = ComicsTabLogic(
      home_loader: ({language, seed}) async => discovery_feed([
        discovery_section(1),
        discovery_section(2, first_id: 20, seed: 'section-two'),
      ]),
      category_loader:
          ({
            required category_id,
            required exclude_ids,
            reserved_ids,
            language,
            seed,
          }) {
            requests.add((
              category: category_id,
              exclude: exclude_ids,
              reserved: reserved_ids ?? [],
              seed: seed,
              language: language,
            ));
            return (pending[category_id] = Completer<ComicDiscoverySection>())
                .future;
          },
    );
    addTearDown(logic.dispose);
    await logic.refresh(language: 'en');
    final first = logic.shuffle(1);
    final duplicate = logic.shuffle(1);
    final second = logic.shuffle(2);
    await duplicate;
    expect(requests, hasLength(2));
    expect(requests[0].category, 1);
    expect(requests[0].exclude, [1, 2, 3, 4, 5, 6]);
    expect(requests[0].seed, 'home-seed');
    expect(requests[0].language, 'en');
    expect(requests[0].reserved, [20, 21, 22, 23, 24, 25]);
    expect(requests[1].reserved, [1, 2, 3, 4, 5, 6]);
    expect(requests[1].seed, 'section-two');
    expect(logic.is_shuffling(1), isTrue);
    expect(logic.is_shuffling(2), isTrue);
    pending[2]!.complete(discovery_section(2, first_id: 40, seed: 'two-next'));
    await second;
    expect(logic.sections[0].items.first.id, 1);
    expect(logic.sections[1].items.first.id, 40);
    expect(logic.is_shuffling(1), isTrue);
    pending[1]!.complete(discovery_section(1, first_id: 60));
    await first;
    expect(logic.sections[0].items.first.id, 60);
    expect(logic.is_shuffling(1), isFalse);
  });

  test('单组失败保留原内容，重试成功独立清理错误', () async {
    var fail = true;
    final logic = ComicsTabLogic(
      home_loader: ({language, seed}) async =>
          discovery_feed([discovery_section(1)]),
      category_loader:
          ({
            required category_id,
            required exclude_ids,
            reserved_ids,
            language,
            seed,
          }) async {
            if (fail) throw StateError('offline');
            return discovery_section(1, first_id: 30);
          },
    );
    addTearDown(logic.dispose);
    await logic.refresh();
    final original = logic.sections.single;
    await logic.shuffle(1);
    expect(logic.sections.single, same(original));
    expect(logic.shuffle_error(1), isNotNull);
    expect(logic.is_shuffling(1), isFalse);
    fail = false;
    await logic.shuffle(1);
    expect(logic.sections.single.items.first.id, 30);
    expect(logic.shuffle_error(1), isNull);
  });

  test('全组刷新及语种切换使未完成换批失效，旧响应不能闪回', () async {
    final pending = Completer<ComicDiscoverySection>();
    var version = 1;
    final logic = ComicsTabLogic(
      home_loader: ({language, seed}) async =>
          discovery_feed([discovery_section(1, first_id: version)]),
      category_loader:
          ({
            required category_id,
            required exclude_ids,
            reserved_ids,
            language,
            seed,
          }) => pending.future,
    );
    addTearDown(logic.dispose);
    await logic.refresh(language: 'en');
    final stale = logic.shuffle(1);
    version = 50;
    logic.prepare_refresh(language: 'zh');
    expect(logic.sections, isEmpty);
    await logic.refresh(language: 'zh', clear: true);
    pending.complete(discovery_section(1, first_id: 20));
    await stale;
    expect(logic.sections.single.items.first.id, 50);
    expect(logic.is_shuffling(1), isFalse);
  });

  test('刷新失败保留全部分组，结束加载且允许下次重试', () async {
    var fail = false;
    final logic = ComicsTabLogic(
      home_loader: ({language, seed}) async {
        if (fail) throw StateError('offline');
        return discovery_feed([discovery_section(1), discovery_section(2)]);
      },
    );
    addTearDown(logic.dispose);
    await logic.refresh();
    final original = logic.sections;
    fail = true;
    await logic.refresh();
    expect(logic.sections, same(original));
    expect(logic.error, isNotNull);
    expect(logic.loading, isFalse);
  });

  test('多次刷新仅允许最新请求写回', () async {
    final first = Completer<ComicDiscoveryFeed>();
    var calls = 0;
    final logic = ComicsTabLogic(
      home_loader: ({language, seed}) {
        return calls++ == 0
            ? first.future
            : Future.value(discovery_feed([discovery_section(2)]));
      },
    );
    final stale = logic.refresh();
    await logic.refresh();
    first.complete(discovery_feed([discovery_section(1)]));
    await stale;
    expect(logic.sections.single.id, 2);
    logic.dispose();
  });

  test('销毁后到达的请求不会写回或通知已退出页面', () async {
    final pending = Completer<ComicDiscoveryFeed>();
    final logic = ComicsTabLogic(
      home_loader: ({language, seed}) => pending.future,
    );
    var notifications = 0;
    logic.addListener(() => notifications++);
    final request = logic.refresh();
    expect(notifications, 1);
    logic.dispose();
    pending.complete(discovery_feed([discovery_section(1)]));
    await request;
    expect(notifications, 1);
    expect(logic.sections, isEmpty);
  });

  test('多分类同书只保留一次，保留服务端分类及作品排序并移除无独占作品的空组', () async {
    final logic = ComicsTabLogic(
      home_loader: ({language, seed}) async => discovery_feed([
        discovery_section(1),
        discovery_section(2, first_id: 4),
        discovery_section(3, first_id: 1, count: 3),
        discovery_section(4, first_id: 20, count: 2),
      ]),
    );
    addTearDown(logic.dispose);
    await logic.refresh();
    expect(logic.sections.map((section) => section.id), [1, 2, 4]);
    expect(logic.sections[1].items.map((item) => item.id), [7, 8, 9]);
    final ids = logic.sections
        .expand((section) => section.items)
        .map((item) => item.id)
        .toList();
    expect(ids, [1, 2, 3, 4, 5, 6, 7, 8, 9, 20, 21]);
    expect(ids.toSet(), hasLength(ids.length));
    expect(logic.sections[1].total, 40, reason: '分类全部库存不受首页去重影响');
  });

  test('并发换批返回同一本新作品时按最新整页复核，后到分组补回自身作品而不重复', () async {
    final pending = <int, Completer<ComicDiscoverySection>>{};
    final logic = ComicsTabLogic(
      home_loader: ({language, seed}) async => discovery_feed([
        discovery_section(1),
        discovery_section(2, first_id: 20),
      ]),
      category_loader:
          ({
            required category_id,
            required exclude_ids,
            reserved_ids,
            language,
            seed,
          }) => (pending[category_id] = Completer<ComicDiscoverySection>())
              .future,
    );
    addTearDown(logic.dispose);
    await logic.refresh();
    final first = logic.shuffle(1);
    final second = logic.shuffle(2);
    pending[1]!.complete(discovery_section(1, first_id: 100));
    await first;
    pending[2]!.complete(discovery_section(2, first_id: 100));
    await second;
    expect(logic.sections[0].items.map((item) => item.id), [
      100,
      101,
      102,
      103,
      104,
      105,
    ]);
    expect(logic.sections[1].items.map((item) => item.id), [
      20,
      21,
      22,
      23,
      24,
      25,
    ]);
    final ids = logic.sections
        .expand((section) => section.items)
        .map((item) => item.id)
        .toList();
    expect(ids.toSet(), hasLength(ids.length));
    expect(logic.shuffle_error(2), isNull);
  });

  test('服务端只剩少量可用作品时保留真实数量，不拿本组旧作品凑数', () async {
    final logic = ComicsTabLogic(
      home_loader: ({language, seed}) async =>
          discovery_feed([discovery_section(1)]),
      category_loader:
          ({
            required category_id,
            required exclude_ids,
            reserved_ids,
            language,
            seed,
          }) async => discovery_section(category_id, first_id: 80, count: 2),
    );
    addTearDown(logic.dispose);
    await logic.refresh();
    await logic.shuffle(1);
    expect(logic.sections.single.items.map((item) => item.id), [80, 81]);
  });
}
