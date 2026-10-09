import 'dart:async';

import 'package:app/pages/work_editor/workspace/logic.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _workspace(int language_id) => {
  'novel': {'work_type': 1, 'novel_language_id': language_id},
};

Map<String, dynamic> _directory(int id, {bool has_more = true}) => {
  'list': [
    {'chapter_id': id},
  ],
  'has_more': has_more,
};

void main() {
  test('筛选失败保留原目录坐标，下一次加载更多不能混用新筛选', () async {
    final requests = <Map<String, dynamic>>[];
    final model = WorkspaceController(
      1,
      call: (path, parameters) async {
        if (path.endsWith('workspace')) return _workspace(10);
        requests.add(Map.of(parameters));
        if (parameters['state'] == 'draft') throw StateError('离线');
        return _directory(parameters['page'] as int);
      },
    );
    addTearDown(model.dispose);
    await model.refresh();
    await model.loadChapters(more: true);
    await model.loadChapters(state: 'draft', search: '新标题');

    expect(model.page, 2);
    expect(model.filter, 'all');
    expect(model.keyword, '');
    expect(model.chapters.map((row) => row['chapter_id']), [1, 2]);
    expect(model.error, isNotNull);

    await model.loadChapters(more: true);
    expect(requests.last['page'], 3);
    expect(requests.last['state'], 'all');
    expect(requests.last['keyword'], '');
    expect(model.chapters.map((row) => row['chapter_id']), [1, 2, 3]);
  });

  test('刷新目录失败时保留整份详情及目录，不能混入新语种身份', () async {
    var refreshes = 0;
    final model = WorkspaceController(
      1,
      call: (path, parameters) async {
        if (path.endsWith('workspace')) return _workspace(++refreshes * 10);
        if (parameters['novel_language_id'] == 20) throw StateError('目录失败');
        return _directory(1);
      },
    );
    addTearDown(model.dispose);
    await model.refresh();
    final old_data = model.data;
    final old_chapters = model.chapters;
    await model.refresh();

    expect(model.data, same(old_data));
    expect(model.chapters, same(old_chapters));
    expect(model.languageId, 10);
    expect(model.busy, isFalse);
  });

  test('目录空响应不能当成功而清除已有章节', () async {
    var directory_requests = 0;
    final model = WorkspaceController(
      1,
      call: (path, parameters) async {
        if (path.endsWith('workspace')) return _workspace(10);
        return ++directory_requests == 1 ? _directory(1) : {};
      },
    );
    addTearDown(model.dispose);
    await model.refresh();
    await model.loadChapters(search: 'other');
    expect(model.chapters.single['chapter_id'], 1);
    expect(model.keyword, '');
    expect(model.error, isNotNull);
  });

  test('详情请求未完成时关闭，不能继续请求目录或提交迟到详情', () async {
    final response = Completer<Map<String, dynamic>>();
    var requests = 0;
    final model = WorkspaceController(
      1,
      call: (_, _) {
        requests++;
        return response.future;
      },
    );
    final refresh = model.refresh();
    model.dispose();
    response.complete(_workspace(10));
    await refresh;
    await model.refresh();
    await model.loadChapters();
    expect(requests, 1);
    expect(model.data, isEmpty);
  });

  test('加载更多失败不跳页，重试沿用同一页直到成功', () async {
    var fail = true;
    final pages = <int>[];
    final model = WorkspaceController(
      1,
      call: (path, parameters) async {
        if (path.endsWith('workspace')) return _workspace(10);
        final page = parameters['page'] as int;
        pages.add(page);
        if (page == 2 && fail) {
          fail = false;
          throw StateError('超时');
        }
        return _directory(page, has_more: page == 1);
      },
    );
    addTearDown(model.dispose);
    await model.refresh();
    await model.loadChapters(more: true);
    expect(model.page, 1);
    await model.loadChapters(more: true);
    await model.loadChapters(more: true);
    expect(pages, [1, 2, 2]);
    expect(model.page, 2);
    expect(model.chapters, hasLength(2));
  });
}
