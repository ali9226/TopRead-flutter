// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/models/comics.dart';
import 'package:app/models/recommend_ranking_item.dart';
import 'package:app/models/work_search.dart';
import 'package:app/pages/search/logic.dart';
import 'package:flutter_test/flutter_test.dart';

List<RecommendRankingItem> _novels(Iterable<int> ids) => ids
    .map(
      (id) => RecommendRankingItem.from_json({'id': id, 'title': 'Novel $id'}),
    )
    .toList();

ComicSearchPage _comics(Iterable<int> ids, {int total = 1}) => ComicSearchPage(
  items: ids
      .map((id) => ComicItem.from_json({'id': id, 'title': 'Comic $id'}))
      .toList(),
  total: total,
);

void main() {
  test('同号小说和漫画分别保留，单类重复和非法编号被过滤', () async {
    final logic = Logic(
      novel_loader:
          ({required keyword, required limit, required no_ids}) async =>
              _novels([1, 1, 0]),
      comic_loader:
          ({
            required keyword,
            required page,
            required page_size,
            required language,
          }) async => _comics([1, 1, 0]),
    );
    addTearDown(logic.dispose);
    await logic.search('story', language: 'en');
    expect(
      logic.items.map((item) => item.id),
      containsAll(['novel_1', 'comic_1']),
    );
    expect(logic.items, hasLength(2));
    expect(logic.has_more, isFalse);
  });

  test('小说无命中时仍返回漫画，并显式传入当前语种', () async {
    final logic = Logic(
      novel_loader:
          ({required keyword, required limit, required no_ids}) async => [],
      comic_loader:
          ({
            required keyword,
            required page,
            required page_size,
            required language,
          }) async {
            expect(keyword, 'comic');
            expect(language, 'fr');
            return _comics([8]);
          },
    );
    addTearDown(logic.dispose);
    await logic.search('comic', language: 'fr');
    expect(logic.items.single.id, 'comic_8');
    expect(logic.has_error, isFalse);
  });

  test('小说排除编号与漫画页码分别推进，耗尽的一类不会再请求', () async {
    final novel_requests = <List<int>>[];
    final comic_requests = <int>[];
    final logic = Logic(
      novel_loader:
          ({required keyword, required limit, required no_ids}) async {
            novel_requests.add(List<int>.of(no_ids));
            return novel_requests.length == 1
                ? _novels(List.generate(Logic.page_size, (index) => index + 1))
                : [];
          },
      comic_loader:
          ({
            required keyword,
            required page,
            required page_size,
            required language,
          }) async {
            comic_requests.add(page);
            return _comics(
              List.generate(
                page == 3 ? 5 : page_size,
                (index) => page * 100 + index,
              ),
              total: 45,
            );
          },
    );
    addTearDown(logic.dispose);
    await logic.search('story', language: 'en');
    await logic.load_more();
    expect(novel_requests[1], List.generate(20, (index) => index + 1));
    expect(novel_requests[1].any((id) => id >= 100), isFalse);
    await logic.load_more();
    await logic.load_more();
    expect(novel_requests, hasLength(2));
    expect(comic_requests, [1, 2, 3]);
    expect(logic.items, hasLength(65));
    expect(logic.has_more, isFalse);
  });

  test('漫画失败保留小说，重试原页后恢复且不重查已耗尽小说', () async {
    var novel_requests = 0;
    final comic_pages = <int>[];
    final logic = Logic(
      novel_loader:
          ({required keyword, required limit, required no_ids}) async {
            novel_requests++;
            return _novels([4]);
          },
      comic_loader:
          ({
            required keyword,
            required page,
            required page_size,
            required language,
          }) async {
            comic_pages.add(page);
            if (comic_pages.length == 1) throw StateError('offline');
            return _comics([4]);
          },
    );
    addTearDown(logic.dispose);
    await logic.search('story', language: 'en');
    expect(logic.items.single.id, 'novel_4');
    expect(logic.comic_failed, isTrue);
    expect(logic.loading, isFalse);
    await logic.load_more();
    expect(novel_requests, 1);
    expect(comic_pages, [1, 1]);
    expect(logic.items, hasLength(2));
    expect(logic.has_error, isFalse);
    expect(logic.has_more, isFalse);
  });

  test('小说失败不吞掉漫画，失败状态与空结果区分', () async {
    final logic = Logic(
      novel_loader:
          ({required keyword, required limit, required no_ids}) async =>
              throw StateError('offline'),
      comic_loader:
          ({
            required keyword,
            required page,
            required page_size,
            required language,
          }) async => _comics([9]),
    );
    addTearDown(logic.dispose);
    await logic.search('story', language: 'en');
    expect(logic.items.single.id, 'comic_9');
    expect(logic.novel_failed, isTrue);
    expect(logic.comic_failed, isFalse);
  });

  test('旧关键词与旧语种的迟到响应不能写回新查询', () async {
    final old_novels = Completer<List<RecommendRankingItem>>();
    final old_comics = Completer<ComicSearchPage>();
    final logic = Logic(
      novel_loader: ({required keyword, required limit, required no_ids}) =>
          keyword == 'old' ? old_novels.future : Future.value(_novels([2])),
      comic_loader:
          ({
            required keyword,
            required page,
            required page_size,
            required language,
          }) {
            if (keyword == 'old') return old_comics.future;
            expect(language, 'fr');
            return Future.value(_comics([2]));
          },
    );
    addTearDown(logic.dispose);
    final stale = logic.search('old', language: 'en');
    expect(logic.loading, isTrue);
    expect(logic.items, isEmpty);
    await logic.search('new', language: 'fr');
    old_novels.complete(_novels([1]));
    old_comics.complete(_comics([1], total: 100));
    await stale;
    expect(
      logic.items.map((item) => item.id),
      containsAll(['novel_2', 'comic_2']),
    );
    expect(logic.items, hasLength(2));
    expect(logic.loading, isFalse);
    expect(logic.has_more, isFalse);
  });

  test('同关键词切换语种立即隐藏旧结果，旧分页不覆盖刷新状态', () async {
    final stale_page = Completer<ComicSearchPage>();
    final logic = Logic(
      novel_loader:
          ({required keyword, required limit, required no_ids}) async => [],
      comic_loader:
          ({
            required keyword,
            required page,
            required page_size,
            required language,
          }) {
            if (language == 'fr') return Future.value(_comics([99]));
            if (page == 2) return stale_page.future;
            return Future.value(
              _comics(List.generate(20, (index) => index + 1), total: 40),
            );
          },
    );
    addTearDown(logic.dispose);
    await logic.search('same', language: 'en');
    final old_pagination = logic.load_more();
    logic.reset(show_loading: true);
    expect(logic.items, isEmpty);
    expect(logic.loading, isTrue);
    await logic.search('same', language: 'fr');
    stale_page.complete(_comics([21], total: 40));
    await old_pagination;
    expect(logic.items.single.id, 'comic_99');
    expect(logic.loading_more, isFalse);
    expect(logic.has_more, isFalse);
  });

  test('重复滚动只产生一组在途分页，离开页面后请求不触发通知', () async {
    final pending = Completer<ComicSearchPage>();
    var page_requests = 0;
    var notifications = 0;
    final logic = Logic(
      novel_loader:
          ({required keyword, required limit, required no_ids}) async => [],
      comic_loader:
          ({
            required keyword,
            required page,
            required page_size,
            required language,
          }) {
            page_requests++;
            return page == 1
                ? Future.value(
                    _comics(List.generate(20, (index) => index + 1), total: 40),
                  )
                : pending.future;
          },
    )..addListener(() => notifications++);
    await logic.search('story', language: 'en');
    final pagination = logic.load_more();
    await logic.load_more();
    expect(page_requests, 2);
    logic.dispose();
    final count = notifications;
    pending.complete(_comics([21], total: 21));
    await pagination;
    expect(notifications, count);
  });
}
