// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/models/message_data.dart';
import 'package:app/stores/message_store.dart';
import 'package:app/stores/user_information.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put<UserInformation>(UserInformation()).isLoggedIn.value = true;
  });

  tearDown(Get.reset);

  test('消息列表的重复首屏和翻页请求会复用在途任务', () async {
    final List<int> requested_pages = <int>[];
    final List<Completer<MessageListResult?>> requests =
        <Completer<MessageListResult?>>[];
    final MessageStore store = MessageStore(
      fetch_message_list:
          ({required int page, required int page_size, int? type}) {
            requested_pages.add(page);
            final Completer<MessageListResult?> request =
                Completer<MessageListResult?>();
            requests.add(request);
            return request.future;
          },
    );
    addTearDown(store.onClose);

    final Future<void> first_load = store.fetch_message_list(
      page: 1,
      is_refresh: true,
    );
    final Future<void> duplicate_first_load = store.fetch_message_list(
      page: 1,
      is_refresh: true,
    );
    expect(requested_pages, <int>[1]);

    requests[0].complete(
      _message_result(
        page: 1,
        messages: <MessageData>[
          _message(1),
          _message(1),
          ...List<MessageData>.generate(18, (int index) => _message(index + 2)),
        ],
      ),
    );
    await Future.wait<void>(<Future<void>>[first_load, duplicate_first_load]);

    final Future<void> first_load_more = store.load_more();
    final Future<void> duplicate_load_more = store.load_more();
    expect(requested_pages, <int>[1, 2]);

    requests[1].complete(
      _message_result(
        page: 2,
        messages: <MessageData>[
          _message(19),
          ...List<MessageData>.generate(
            19,
            (int index) => _message(index + 20),
          ),
        ],
      ),
    );
    await Future.wait<void>(<Future<void>>[
      first_load_more,
      duplicate_load_more,
    ]);

    final Future<void> third_page = store.load_more();
    expect(requested_pages, <int>[1, 2, 3]);
    requests[2].complete(_message_result(page: 3, messages: <MessageData>[]));
    await third_page;

    final List<String> identities = store.message_list
        .map((MessageData message) => message.identity_key)
        .toList(growable: false);
    expect(identities.toSet(), hasLength(identities.length));
  });

  test('消息翻页期间的多次刷新只串行追加一轮', () async {
    final List<int> requested_pages = <int>[];
    final List<Completer<MessageListResult?>> requests =
        <Completer<MessageListResult?>>[];
    final MessageStore store = MessageStore(
      fetch_message_list:
          ({required int page, required int page_size, int? type}) {
            requested_pages.add(page);
            final Completer<MessageListResult?> request =
                Completer<MessageListResult?>();
            requests.add(request);
            return request.future;
          },
    );
    addTearDown(store.onClose);

    final Future<void> initial_load = store.fetch_message_list(
      page: 1,
      is_refresh: true,
    );
    requests[0].complete(
      _message_result(
        page: 1,
        messages: List<MessageData>.generate(
          20,
          (int index) => _message(index + 1),
        ),
      ),
    );
    await initial_load;

    final Future<void> load_more = store.load_more();
    final Future<void> first_refresh = store.fetch_message_list(
      page: 1,
      is_refresh: true,
    );
    final Future<void> duplicate_refresh = store.fetch_message_list(
      page: 1,
      is_refresh: true,
    );
    expect(requested_pages, <int>[1, 2]);

    requests[1].complete(
      _message_result(page: 2, messages: <MessageData>[_message(21)]),
    );
    await Future<void>.delayed(Duration.zero);
    expect(requested_pages, <int>[1, 2, 1]);

    requests[2].complete(
      _message_result(page: 1, messages: <MessageData>[_message(100)]),
    );
    await Future.wait<void>(<Future<void>>[
      load_more,
      first_refresh,
      duplicate_refresh,
    ]);

    expect(store.message_list.single.id, 100);
  });

  test('未读统计的同上下文重复请求仅发送一次', () async {
    int request_count = 0;
    final Completer<MessageUnreadCount?> request =
        Completer<MessageUnreadCount?>();
    final MessageStore store = MessageStore(
      fetch_unread_count: () {
        request_count++;
        return request.future;
      },
    );
    addTearDown(store.onClose);

    final Future<void> first_fetch = store.fetch_statistics();
    final Future<void> duplicate_fetch = store.fetch_statistics();
    expect(request_count, 1);

    request.complete(
      const MessageUnreadCount(
        total: 0,
        comment_unread: 0,
        comment_total: 0,
        like_unread: 0,
        like_total: 0,
        favorite_unread: 0,
        favorite_total: 0,
        chat_unread: 0,
        system_unread: 0,
      ),
    );
    await Future.wait<void>(<Future<void>>[first_fetch, duplicate_fetch]);

    expect(request_count, 1);
  });
}

MessageListResult _message_result({
  required int page,
  required List<MessageData> messages,
}) {
  return MessageListResult(
    list: messages,
    total: 100,
    page: page,
    page_size: 20,
  );
}

MessageData _message(int id) {
  return MessageData(
    id: id,
    user_id: 1,
    title: '',
    introduction: '',
    content: '{}',
    type: MessageType.novel_favorite,
    send_user: 2,
    send_time: '2026-08-16T00:00:00.000Z',
    notify_status: NotifyStatus.unread,
    sender_name: 'Tester',
    sender_avatar: '',
  );
}
