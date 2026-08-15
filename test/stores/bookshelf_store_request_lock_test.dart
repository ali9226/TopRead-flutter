// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/api/bookshelf.dart';
import 'package:app/stores/bookshelf_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('历史列表复用在途请求且分页不跳页', () async {
    final List<int> requested_pages = <int>[];
    final List<Completer<BookshelfListResult<ReadRecordItem>?>> requests =
        <Completer<BookshelfListResult<ReadRecordItem>?>>[];
    final BookshelfStore store = BookshelfStore(
      fetch_history_list: ({required int page, required int page_size}) {
        requested_pages.add(page);
        final Completer<BookshelfListResult<ReadRecordItem>?> request =
            Completer<BookshelfListResult<ReadRecordItem>?>();
        requests.add(request);
        return request.future;
      },
    );
    addTearDown(store.onClose);

    final Future<void> first_load = store.load_history_if_needed();
    final Future<void> duplicate_first_load = store.load_history_if_needed();
    expect(requested_pages, <int>[1]);

    requests.single.complete(
      _history_result(
        page: 1,
        items: List<ReadRecordItem>.generate(
          20,
          (int index) => _history_item(index + 1),
        ),
      ),
    );
    await Future.wait<void>(<Future<void>>[first_load, duplicate_first_load]);

    final Future<void> first_load_more = store.load_more_history();
    final Future<void> duplicate_load_more = store.load_more_history();
    expect(requested_pages, <int>[1, 2]);

    requests[1].complete(
      _history_result(
        page: 2,
        items: <ReadRecordItem>[
          _history_item(20),
          ...List<ReadRecordItem>.generate(
            19,
            (int index) => _history_item(index + 21),
          ),
        ],
      ),
    );
    await Future.wait<void>(<Future<void>>[
      first_load_more,
      duplicate_load_more,
    ]);

    final Future<void> third_page = store.load_more_history();
    expect(requested_pages, <int>[1, 2, 3]);
    requests[2].complete(_history_result(page: 3, items: <ReadRecordItem>[]));
    await third_page;

    final List<String> identities = store.history_list
        .map((BookshelfBookItem item) => item.id)
        .toList(growable: false);
    expect(identities.toSet(), hasLength(identities.length));
  });

  test('翻页期间的多次历史刷新只追加一轮', () async {
    final List<int> requested_pages = <int>[];
    final List<Completer<BookshelfListResult<ReadRecordItem>?>> requests =
        <Completer<BookshelfListResult<ReadRecordItem>?>>[];
    final BookshelfStore store = BookshelfStore(
      fetch_history_list: ({required int page, required int page_size}) {
        requested_pages.add(page);
        final Completer<BookshelfListResult<ReadRecordItem>?> request =
            Completer<BookshelfListResult<ReadRecordItem>?>();
        requests.add(request);
        return request.future;
      },
    );
    addTearDown(store.onClose);

    final Future<void> initial_load = store.load_history_if_needed();
    requests[0].complete(
      _history_result(
        page: 1,
        items: List<ReadRecordItem>.generate(
          20,
          (int index) => _history_item(index + 1),
        ),
      ),
    );
    await initial_load;

    final Future<void> load_more = store.load_more_history();
    final Future<void> first_refresh = store.refresh_history();
    final Future<void> duplicate_refresh = store.refresh_history();
    expect(requested_pages, <int>[1, 2]);

    requests[1].complete(
      _history_result(page: 2, items: <ReadRecordItem>[_history_item(21)]),
    );
    await Future<void>.delayed(Duration.zero);
    expect(requested_pages, <int>[1, 2, 1]);

    requests[2].complete(
      _history_result(page: 1, items: <ReadRecordItem>[_history_item(100)]),
    );
    await Future.wait<void>(<Future<void>>[
      load_more,
      first_refresh,
      duplicate_refresh,
    ]);

    expect(store.history_list.single.id, '100');
  });

  test('关注列表首屏重复调用与重复数据都会去重', () async {
    int request_count = 0;
    final Completer<BookshelfListResult<FocusAuthorItem>?> request =
        Completer<BookshelfListResult<FocusAuthorItem>?>();
    final BookshelfStore store = BookshelfStore(
      fetch_focus_list: ({required int page, required int page_size}) {
        request_count++;
        return request.future;
      },
    );
    addTearDown(store.onClose);

    final Future<void> first_load = store.load_focus_if_needed();
    final Future<void> duplicate_load = store.load_focus_if_needed();
    expect(request_count, 1);

    request.complete(
      BookshelfListResult<FocusAuthorItem>(
        list: <FocusAuthorItem>[_focus_item(1), _focus_item(1)],
        total: 2,
        page: 1,
        page_size: 20,
      ),
    );
    await Future.wait<void>(<Future<void>>[first_load, duplicate_load]);

    expect(store.focus_list, hasLength(1));
    expect(store.focus_list.single.id, '1');
  });
}

BookshelfListResult<ReadRecordItem> _history_result({
  required int page,
  required List<ReadRecordItem> items,
}) {
  return BookshelfListResult<ReadRecordItem>(
    list: items,
    total: 100,
    page: page,
    page_size: 20,
  );
}

ReadRecordItem _history_item(int id) {
  return ReadRecordItem(
    id: '$id',
    novel_id: '$id',
    novel_language_id: '$id',
    read_duration: 0,
    read_progress: 0,
    create_time: '',
    novel_title: 'Novel $id',
    publish_status: 1,
    author_id: 'author_$id',
    author_name: 'Author $id',
    author_avatar: '',
    language_title: '',
    introduction: '',
    cover_url: '',
    chapter_count: 0,
    category_names: '',
  );
}

FocusAuthorItem _focus_item(int id) {
  return FocusAuthorItem(
    id: '$id',
    author_id: '$id',
    author_name: 'Author $id',
    author_avatar: '',
    novel_count: 1,
    creation_time: '',
  );
}
