// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/models/message_data.dart';
import 'package:app/models/user_info.dart';
import 'package:app/api/message.dart' as message_api;
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

  test('首次消息加载失败后加载更多仍请求第一页', () async {
    final List<int> pages = <int>[];
    final MessageStore store = MessageStore(
      fetch_message_list:
          ({required int page, required int page_size, int? type}) async {
            pages.add(page);
            return pages.length == 1
                ? null
                : _message_result(
                    page: page,
                    messages: <MessageData>[_message(1)],
                  );
          },
    );
    addTearDown(store.onClose);
    await store.fetch_message_list(page: 1, is_refresh: true);
    expect(store.has_loaded, isFalse);
    await store.load_more();
    expect(pages, <int>[1, 1]);
    expect(store.has_loaded, isTrue);
    expect(store.message_list.single.id, 1);
  });

  test('旧账号单条已读响应不修改新账号列表和角标', () async {
    final Completer<bool> response = Completer<bool>();
    final MessageStore store = MessageStore(
      read_message: ({required int id}) => response.future,
      fetch_message_list:
          ({required int page, required int page_size, int? type}) async =>
              _message_result(page: page, messages: <MessageData>[_message(1)]),
    );
    addTearDown(store.onClose);
    await store.fetch_message_list(page: 1, is_refresh: true);
    final Future<void> old_read = store.mark_as_read(1);
    Get.find<UserInformation>().saveUserInfo(
      UserInfo.fromJson(<String, dynamic>{'id': 2}),
    );
    store.clear();
    await store.fetch_message_list(page: 1, is_refresh: true);
    store.favorite_unread.value = 7;
    response.complete(true);
    await old_read;
    expect(store.message_list.single.is_unread, isTrue);
    expect(store.favorite_unread.value, 7);
  });

  test('旧账号删除失败不触发新账号列表恢复', () async {
    final Completer<bool> deletion = Completer<bool>();
    int list_calls = 0;
    final MessageStore store = MessageStore(
      delete_message: ({required int id}) => deletion.future,
      fetch_message_list:
          ({required int page, required int page_size, int? type}) async {
            list_calls++;
            return _message_result(
              page: page,
              messages: <MessageData>[_message(list_calls)],
            );
          },
    );
    addTearDown(store.onClose);
    await store.fetch_message_list(page: 1, is_refresh: true);
    final Future<void> old_delete = store.delete_message(1);
    Get.find<UserInformation>().saveUserInfo(
      UserInfo.fromJson(<String, dynamic>{'id': 2}),
    );
    store.clear();
    await store.fetch_message_list(page: 1, is_refresh: true);
    deletion.complete(false);
    await old_delete;
    expect(list_calls, 2);
    expect(store.message_list.single.id, 2);
  });

  test('旧全部已读任务结束不能释放新账号全部已读锁', () async {
    final List<Completer<message_api.MessageReadAllResult>> responses =
        <Completer<message_api.MessageReadAllResult>>[];
    int statistics_calls = 0;
    final MessageStore store = MessageStore(
      read_all_messages: () {
        final Completer<message_api.MessageReadAllResult> response =
            Completer<message_api.MessageReadAllResult>();
        responses.add(response);
        return response.future;
      },
      fetch_unread_count: () async {
        statistics_calls++;
        return null;
      },
    );
    addTearDown(store.onClose);
    final Future<void> old_operation = store.mark_all_as_read();
    Get.find<UserInformation>().saveUserInfo(
      UserInfo.fromJson(<String, dynamic>{'id': 2}),
    );
    store.clear();
    final Future<void> new_operation = store.mark_all_as_read();
    responses[0].complete(
      const message_api.MessageReadAllResult(success: true),
    );
    await old_operation;
    await store.mark_all_as_read();
    await store.fetch_statistics();
    expect(responses, hasLength(2));
    expect(statistics_calls, 0);
    responses[1].complete(
      const message_api.MessageReadAllResult(success: true),
    );
    await new_operation;
    expect(statistics_calls, 1);
  });

  test('删除已读消息会废弃删除之前的列表响应，避免条目重新出现', () async {
    final Completer<MessageListResult?> refresh =
        Completer<MessageListResult?>();
    int calls = 0;
    final MessageData read_message = _message(
      1,
    ).copy_with(notify_status: NotifyStatus.read);
    final MessageStore store = MessageStore(
      delete_message: ({required int id}) async => true,
      fetch_message_list:
          ({required int page, required int page_size, int? type}) {
            calls++;
            return calls == 1
                ? Future<MessageListResult?>.value(
                    _message_result(
                      page: page,
                      messages: <MessageData>[read_message],
                    ),
                  )
                : refresh.future;
          },
    );
    addTearDown(store.onClose);
    await store.fetch_message_list(page: 1, is_refresh: true);
    final Future<void> old_refresh = store.fetch_message_list(
      page: 1,
      is_refresh: true,
    );
    await store.delete_message(1);
    refresh.complete(
      _message_result(page: 1, messages: <MessageData>[read_message]),
    );
    await old_refresh;
    expect(store.message_list, isEmpty);
  });

  test('普通消息已读不修改数字 ID 相同的客服摘要', () async {
    final MessageStore store = MessageStore(
      read_message: ({required int id}) async => true,
      fetch_message_list:
          ({required int page, required int page_size, int? type}) async =>
              _message_result(
                page: page,
                messages: <MessageData>[_message(1)],
                chat_message: _message(1, type: MessageType.chat_reply),
                chat_unread: 3,
              ),
    );
    addTearDown(store.onClose);
    await store.fetch_message_list(page: 1, is_refresh: true);
    store.favorite_unread.value = 1;
    await store.mark_as_read(1);
    expect(store.message_list.first.type, MessageType.chat_reply);
    expect(store.message_list.first.is_unread, isTrue);
    expect(store.message_list.last.is_unread, isFalse);
    expect(store.chat_unread.value, 3);
    expect(store.favorite_unread.value, 0);
  });

  test('按消息类型删除不会误删相同数字 ID 的客服摘要', () async {
    final List<int> deleted_ids = <int>[];
    final MessageStore store = MessageStore(
      delete_message: ({required int id}) async {
        deleted_ids.add(id);
        return true;
      },
      fetch_message_list:
          ({required int page, required int page_size, int? type}) async =>
              _message_result(
                page: page,
                messages: <MessageData>[_message(1)],
                chat_message: _message(1, type: MessageType.chat_reply),
                chat_unread: 3,
              ),
    );
    addTearDown(store.onClose);
    await store.fetch_message_list(page: 1, is_refresh: true);
    await store.delete_message(1, message_type: MessageType.novel_favorite);
    expect(deleted_ids, <int>[1]);
    expect(store.message_list.single.type, MessageType.chat_reply);
    expect(store.chat_unread.value, 3);
  });

  test('客服统计的旧账号和旧未读快照均不能覆盖当前状态', () async {
    final List<Completer<int?>> responses = <Completer<int?>>[];
    final MessageStore store = MessageStore(
      fetch_chat_unread_count: () {
        final Completer<int?> response = Completer<int?>();
        responses.add(response);
        return response.future;
      },
    );
    addTearDown(store.onClose);
    final Future<void> first = store.fetch_chat_unread();
    store.update_chat_unread(7);
    responses[0].complete(2);
    await first;
    expect(store.chat_unread.value, 7);
    final Future<void> second = store.fetch_chat_unread();
    Get.find<UserInformation>().saveUserInfo(
      UserInfo.fromJson(<String, dynamic>{'id': 2}),
    );
    responses[1].complete(4);
    await second;
    expect(store.chat_unread.value, 7);
  });

  test('消息控制器销毁后不应用迟到的未读统计', () async {
    final Completer<int?> response = Completer<int?>();
    final MessageStore store = MessageStore(
      fetch_chat_unread_count: () => response.future,
    );
    final Future<void> request = store.fetch_chat_unread();
    store.onClose();
    response.complete(9);
    await request;
    expect(store.chat_unread.value, 0);
  });

  test('全部已读期间本地状态变化后仍补拉积累的未读校准请求', () async {
    final Completer<message_api.MessageReadAllResult> response =
        Completer<message_api.MessageReadAllResult>();
    int statistics_calls = 0;
    final MessageStore store = MessageStore(
      read_all_messages: () => response.future,
      fetch_unread_count: () async {
        statistics_calls++;
        return MessageUnreadCount.from_json(<String, dynamic>{
          'chat_unread': 4,
        });
      },
    );
    addTearDown(store.onClose);
    final Future<void> operation = store.mark_all_as_read();
    store.update_chat_unread(0);
    await store.fetch_statistics();
    response.complete(
      message_api.MessageReadAllResult(
        success: true,
        unread_count: MessageUnreadCount.from_json(<String, dynamic>{
          'chat_unread': 0,
        }),
      ),
    );
    await operation;
    expect(statistics_calls, 1);
    expect(store.chat_unread.value, 4);
  });

  test('销毁取消合并的列表补拉，不在旧请求完成后重新发送', () async {
    int request_count = 0;
    final Completer<MessageListResult?> response =
        Completer<MessageListResult?>();
    final MessageStore store = MessageStore(
      fetch_message_list:
          ({required int page, required int page_size, int? type}) {
            request_count++;
            return response.future;
          },
    );
    final Future<void> first = store.fetch_message_list(page: 2);
    final Future<void> pending = store.fetch_message_list(
      page: 1,
      is_refresh: true,
    );
    store.onClose();
    response.complete(
      _message_result(page: 2, messages: <MessageData>[_message(1)]),
    );
    await Future.wait<void>(<Future<void>>[first, pending]);
    expect(request_count, 1);
    expect(store.message_list, isEmpty);
  });
}

MessageListResult _message_result({
  required int page,
  required List<MessageData> messages,
  MessageData? chat_message,
  int chat_unread = 0,
}) {
  return MessageListResult(
    list: messages,
    total: 100,
    page: page,
    page_size: 20,
    chat_message: chat_message,
    chat_unread: chat_unread,
  );
}

MessageData _message(int id, {int type = MessageType.novel_favorite}) {
  return MessageData(
    id: id,
    user_id: 1,
    title: '',
    introduction: '',
    content: '{}',
    type: type,
    send_user: 2,
    send_time: '2026-08-16T00:00:00.000Z',
    notify_status: NotifyStatus.unread,
    sender_name: 'Tester',
    sender_avatar: '',
  );
}
