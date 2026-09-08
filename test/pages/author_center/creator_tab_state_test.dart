import 'dart:async';

import 'package:app/pages/author_center/creator_tab_state.dart';
import 'package:app/pages/author_center/models/creator_backend_models.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> row(int id, String updated) => {
  'id': '$id',
  'title': '作品$id',
  'creator_update_time': updated,
};

void main() {
  test('草稿区分作品和修订 ID，兼容字符串数字和更新时间', () {
    final work = CreatorWorkModel.fromDraftJson({
      'novel_id': '101',
      'revision_id': '209',
      'work_type': '2',
      'word_count': '125',
      'revision_status': '1',
      'update_time': '2026-09-08 16:30:00',
    });
    expect(work.id, 101);
    expect(work.draft_revision_id, 209);
    expect(work.is_draft, isTrue);
    expect(work.word_count, 125);
    expect(work.updatedAt, DateTime(2026, 9, 8, 16, 30));
  });

  test('分页失败不跳页，重试去重并按最后更新时间排序', () async {
    final requested = <int>[];
    var fail = true;
    final tab = CreatorTabState(
      loadPage: (page) async {
        requested.add(page);
        if (page == 1) {
          return {
            'list': [row(1, '2026-09-07')],
            'total': '3',
          };
        }
        if (fail) return null;
        return {
          'list': [row(1, '2026-09-07'), row(2, '2026-09-08')],
          'total': 3,
          'has_more': false,
        };
      },
    );
    addTearDown(tab.dispose);
    await tab.refresh();
    await tab.loadMore();
    expect(tab.page, 1);
    expect(tab.works.length, 1);
    expect(tab.loadMoreError, isNotNull);
    fail = false;
    await tab.loadMore();
    expect(requested, [1, 2, 2]);
    expect(tab.works.map((work) => work.id), [2, 1]);
    expect(tab.hasMore, isFalse);
    expect(tab.loadMoreError, isNull);
  });

  test('刷新期间到达的旧分页响应不会写回列表', () async {
    final more = Completer<Map<String, dynamic>?>();
    var refreshCount = 0;
    final tab = CreatorTabState(
      loadPage: (page) async {
        if (page == 2) return more.future;
        refreshCount++;
        return {
          'list': [row(refreshCount, '2026-09-08')],
          'total': 2,
        };
      },
    );
    addTearDown(tab.dispose);
    await tab.refresh();
    final pending = tab.loadMore();
    await tab.refresh();
    more.complete({
      'list': [row(3, '2026-09-08')],
      'total': 2,
    });
    await pending;
    expect(tab.works.map((work) => work.id), [2]);
    expect(tab.page, 1);
  });

  test('分类并发加载互不覆盖，空列表可再次刷新', () async {
    var populated = false;
    final published = CreatorTabState(
      loadPage: (_) async => {
        'list': [row(1, '2026-09-08')],
        'total': 1,
      },
    );
    final drafts = CreatorTabState(
      isDraftList: true,
      loadPage: (_) async => {
        'list': populated
            ? [
                {'novel_id': '2', 'revision_id': '8'},
              ]
            : [],
        'total': populated ? 1 : 0,
      },
    );
    addTearDown(published.dispose);
    addTearDown(drafts.dispose);
    await Future.wait([published.refresh(), drafts.refresh()]);
    expect(drafts.works, isEmpty);
    populated = true;
    await drafts.refresh();
    expect(published.works.single.id, 1);
    expect(drafts.works.single.id, 2);
  });
}
