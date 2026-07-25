// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:app/models/user_info.dart';
import 'package:app/stores/customer_service_chat_history_store.dart';
import 'package:app/stores/user_information.dart';

void main() {
  tearDown(Get.reset);

  group('ChatMessageItem', () {
    test('解析服务端字段并生成稳定键', () {
      final ChatMessageItem message =
          ChatMessageItem.from_json(<String, dynamic>{
            'id': '42',
            'sender_type': '2',
            'message_type': 1,
            'content': '你好',
            'create_time': '2026-07-19T10:00:00.000Z',
            'sender_name': '客服',
          });

      expect(message.id, 42);
      expect(message.sender_type, 2);
      expect(message.local_key, 'server_42');
      expect(message.content, '你好');
    });

    test('图片落库后保留本地预览和元素键', () {
      const ChatMessageItem local_message = ChatMessageItem(
        id: -1,
        sender_type: 1,
        message_type: 3,
        content: '/tmp/local_image.jpg',
        create_time: '2026-07-19T10:00:00.000Z',
        local_key: 'local_1',
        is_uploading: true,
        is_pending: true,
      );
      final ChatMessageItem server_message =
          ChatMessageItem.from_json(<String, dynamic>{
            'id': 43,
            'sender_type': 1,
            'message_type': 3,
            'content': 'https://example.com/image.jpg',
            'create_time': '2026-07-19T10:00:01.000Z',
          });

      final ChatMessageItem merged = local_message.merge_server_message(
        server_message,
      );

      expect(merged.id, 43);
      expect(merged.local_key, 'local_1');
      expect(merged.content, '/tmp/local_image.jpg');
      expect(merged.server_content, 'https://example.com/image.jpg');
      expect(merged.is_uploading, isFalse);
      expect(merged.is_pending, isFalse);
    });
  });

  group('CustomerServiceChatHistoryStore', () {
    test('本地新消息始终位于反向列表首端', () {
      final CustomerServiceChatHistoryStore store =
          CustomerServiceChatHistoryStore();

      final int first_id = store.add_local_message(
        message_type: 1,
        content: '第一条',
      );
      final int second_id = store.add_local_message(
        message_type: 1,
        content: '第二条',
      );

      expect(first_id, -1);
      expect(second_id, -2);
      expect(
        store.messages.map((ChatMessageItem item) => item.content),
        <String>['第二条', '第一条'],
      );
      expect(store.find_message_index_by_key('local_2'), 0);
      expect(store.find_message_index_by_key('local_1'), 1);
    });

    test('图片上传状态在全局缓存内原地更新', () {
      final CustomerServiceChatHistoryStore store =
          CustomerServiceChatHistoryStore();
      final int local_id = store.add_local_message(
        message_type: 3,
        content: '/tmp/local_image.jpg',
        is_uploading: true,
      );

      store.mark_image_upload_complete(
        local_id,
        'https://example.com/image.jpg',
      );

      expect(store.messages.single.is_uploading, isFalse);
      expect(
        store.messages.single.server_content,
        'https://example.com/image.jpg',
      );
      expect(store.messages.single.local_key, 'local_1');
    });

    test('发送确认合并重复服务端图片时保留当前页面节点', () {
      final CustomerServiceChatHistoryStore store =
          CustomerServiceChatHistoryStore();
      final int local_id = store.add_local_message(
        message_type: 3,
        content: '/tmp/local_image.jpg',
        is_uploading: true,
      );
      store.mark_image_upload_complete(
        local_id,
        'https://example.com/image.jpg',
      );
      store.register_pending_confirmation(local_id);
      store.messages.add(
        ChatMessageItem.from_json(<String, dynamic>{
          'id': 88,
          'sender_type': 1,
          'message_type': 3,
          'content': 'https://example.com/image.jpg',
          'create_time': '2026-07-19T10:00:01.000Z',
        }),
      );

      store.handle_send_success(<String, dynamic>{
        'message_id': 88,
        'session_id': 1,
        'create_time': '2026-07-19T10:00:01.000Z',
      });

      expect(store.messages, hasLength(1));
      expect(store.messages.single.id, 88);
      expect(store.messages.single.local_key, 'local_1');
      expect(store.messages.single.content, '/tmp/local_image.jpg');
      expect(
        store.messages.single.server_content,
        'https://example.com/image.jpg',
      );
      expect(store.messages.single.is_uploading, isFalse);
      expect(store.messages.single.is_pending, isFalse);
    });

    test('过期访客身份请求不会覆盖后到的登录用户', () async {
      final UserInformation user_information = Get.put(UserInformation());
      final Completer<String> visitor_id_completer = Completer<String>();
      final _IdentityTestStore store = _IdentityTestStore(
        visitor_id_loader: () => visitor_id_completer.future,
      );

      final Future<void> stale_visitor_open = store.open_conversation();
      await Future<void>.delayed(Duration.zero);
      user_information.saveUserInfo(_build_user_info(37427));
      await store.open_conversation();
      visitor_id_completer.complete('stale-visitor-id');
      await stale_visitor_open;

      expect(store.identity_key, 'user_37427');
      expect(store.session_key, '37427');
      expect(store.synchronization_count, 1);
    });

    test('WebSocket 客服回复按会话接收并在重连后自动补漏', () async {
      final UserInformation user_information = Get.put(UserInformation());
      user_information.saveUserInfo(_build_user_info(37427));
      final _IdentityTestStore store = _IdentityTestStore(
        visitor_id_loader: () async => 'visitor-id',
      );
      await store.open_conversation();
      store.handle_send_success(<String, dynamic>{
        'session_id': 4,
        'message_id': 0,
      });
      store.messages.add(
        ChatMessageItem.from_json(<String, dynamic>{
          'id': 157,
          'session_id': 4,
          'session_key': '37427',
          'sender_type': 2,
          'message_type': 1,
          'content': '已有历史',
          // TODO 故意构造比实时推送更晚的文本时间，复现两条链路的时区差异。
          'create_time': '2026-07-19T14:40:22.000Z',
        }),
      );

      store.handle_websocket_event(<String, dynamic>{
        'type': 'chat_receive',
        'data': <String, dynamic>{
          'id': 158,
          'session_id': 4,
          'session_key': '37427',
          'sender_type': 2,
          'message_type': 1,
          'content': '客服实时回复',
          'create_time': '2026-07-19T06:40:54.000Z',
        },
      });

      expect(store.messages.map((ChatMessageItem item) => item.id), <int>[
        158,
        157,
      ]);
      expect(store.messages.first.content, '客服实时回复');
      expect(store.received_message_revision, 1);

      store.handle_websocket_event(<String, dynamic>{'type': 'connected'});
      await Future<void>.delayed(Duration.zero);
      expect(store.synchronization_count, 2);
    });

    test('历史加载始终用已有 ID 过滤且不会遗漏最早消息', () async {
      final UserInformation user_information = Get.put(UserInformation());
      user_information.saveUserInfo(_build_user_info(37427));
      final _HistoryIdFilterTestStore store = _HistoryIdFilterTestStore();

      await store.open_conversation();

      expect(store.messages, hasLength(30));
      expect(store.messages.first.id, 36);
      expect(store.messages.last.id, 7);
      expect(store.has_more_history, isTrue);
      expect(store.received_exclude_ids.single, isEmpty);

      await store.load_more_history();

      expect(store.messages, hasLength(36));
      expect(
        store.messages.map((ChatMessageItem item) => item.id),
        List<int>.generate(36, (int index) => 36 - index),
      );
      expect(store.messages.last.content, '1');
      expect(store.has_more_history, isFalse);
      expect(store.received_exclude_ids.last, hasLength(30));

      await store.load_more_history();
      expect(store.received_exclude_ids, hasLength(2));
    });
  });
}

class _IdentityTestStore extends CustomerServiceChatHistoryStore {
  int synchronization_count = 0;

  _IdentityTestStore({required super.visitor_id_loader});

  @override
  Future<void> synchronize_latest_history() async {
    synchronization_count++;
  }
}

class _HistoryIdFilterTestStore extends CustomerServiceChatHistoryStore {
  final List<List<int>> received_exclude_ids = <List<int>>[];

  _HistoryIdFilterTestStore()
    : super(visitor_id_loader: (() async => 'visitor-id'));

  @override
  Future<Map<String, dynamic>?> request_history({
    required int user_id,
    required String visitor_id,
    required List<int> exclude_ids,
  }) async {
    received_exclude_ids.add(List<int>.from(exclude_ids));
    final Set<int> excluded_id_set = exclude_ids.toSet();
    final List<int> remaining_ids = List<int>.generate(
      36,
      (int index) => 36 - index,
    ).where((int id) => !excluded_id_set.contains(id)).toList();
    final List<int> batch_ids = remaining_ids
        .take(CustomerServiceChatHistoryStore.page_size)
        .toList();

    return <String, dynamic>{
      'session_id': 4,
      'total': 36,
      'has_more': remaining_ids.length > batch_ids.length,
      'list': batch_ids
          .map(
            (int id) => <String, dynamic>{
              'id': id,
              'session_id': 4,
              'sender_type': id.isEven ? 1 : 2,
              'message_type': 1,
              'content': '$id',
              'create_time': '2026-07-19T00:00:00.000Z',
            },
          )
          .toList(),
    };
  }
}

UserInfo _build_user_info(int id) {
  return UserInfo.fromJson(<String, dynamic>{'id': id});
}
