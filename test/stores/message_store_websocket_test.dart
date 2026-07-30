// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/api/message.dart' as message_api;
import 'package:app/models/message_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:app/stores/message_store.dart';
import 'package:app/stores/user_information.dart';

void main() {
  test('WebSocket 未读快照会同步客服角标和底部导航总角标', () {
    final MessageStore store = MessageStore();
    addTearDown(store.onClose);

    store.handle_websocket_event(<String, dynamic>{
      'type': 'unread_count',
      'data': <String, dynamic>{
        'total': 12,
        'comment_unread': 1,
        'comment_total': 5,
        'like_unread': 2,
        'like_total': 6,
        'favorite_unread': 3,
        'favorite_total': 7,
        'chat_unread': 4,
        'system_unread': 2,
      },
    });

    expect(store.chat_unread.value, 4);
    expect(store.system_unread.value, 2);
    expect(store.unread_total.value, 12);
  });

  test('管理员实时回复优先使用后端未读数并过滤重复消息', () {
    final MessageStore store = MessageStore();
    addTearDown(store.onClose);

    final Map<String, dynamic> event = <String, dynamic>{
      'type': 'chat_receive',
      'data': <String, dynamic>{'id': 101, 'sender_type': 2, 'unread': 3},
    };
    store.handle_websocket_event(event);
    store.handle_websocket_event(event);

    expect(store.chat_unread.value, 3);
    expect(store.unread_total.value, 3);
  });

  test('管理员实时回复会立即替换全部消息中的客服摘要', () {
    final MessageStore store = MessageStore();
    addTearDown(store.onClose);

    store.handle_websocket_event(<String, dynamic>{
      'type': 'chat_receive',
      'data': <String, dynamic>{
        'id': 111,
        'sender_type': 2,
        'sender_id': 7,
        'content': '第一条客服回复',
        'create_time': '2026-07-28T01:00:00.000Z',
        'unread': 1,
      },
    });
    store.handle_websocket_event(<String, dynamic>{
      'type': 'chat_receive',
      'data': <String, dynamic>{
        'id': 112,
        'sender_type': 2,
        'sender_id': 7,
        'content': '最新客服回复',
        'create_time': '2026-07-28T01:01:00.000Z',
        'unread': 2,
      },
    });
    store.handle_websocket_event(<String, dynamic>{
      'type': 'chat_receive',
      'data': <String, dynamic>{
        'id': 110,
        'sender_type': 2,
        'content': '乱序旧回复',
        'unread': 1,
      },
    });

    final List<MessageData> chat_messages = store.message_list
        .where((message) => message.type == MessageType.chat_reply)
        .toList();
    expect(chat_messages, hasLength(1));
    expect(chat_messages.single.id, 112);
    expect(chat_messages.single.display_subtitle, '最新客服回复');
    expect(store.chat_unread.value, 2);
  });

  test('旧版后端未携带未读数时按管理员消息递增', () {
    final MessageStore store = MessageStore();
    addTearDown(store.onClose);

    store.handle_websocket_event(<String, dynamic>{
      'type': 'chat_receive',
      'data': <String, dynamic>{'id': 201, 'sender_type': 2},
    });
    store.handle_websocket_event(<String, dynamic>{
      'type': 'chat_receive',
      'data': <String, dynamic>{'id': 202, 'sender_type': 2},
    });
    store.handle_websocket_event(<String, dynamic>{
      'type': 'chat_receive',
      'data': <String, dynamic>{'id': 203, 'sender_type': 1},
    });

    expect(store.chat_unread.value, 2);
    expect(store.unread_total.value, 2);
  });

  test('乱序旧回复不能覆盖较新回复携带的权威未读数', () {
    final MessageStore store = MessageStore();
    addTearDown(store.onClose);

    store.handle_websocket_event(<String, dynamic>{
      'type': 'chat_receive',
      'data': <String, dynamic>{'id': 302, 'sender_type': 2, 'unread': 5},
    });
    store.handle_websocket_event(<String, dynamic>{
      'type': 'chat_receive',
      'data': <String, dynamic>{'id': 301, 'sender_type': 2, 'unread': 4},
    });

    expect(store.chat_unread.value, 5);
    expect(store.unread_total.value, 5);
  });

  test('普通消息携带权威快照时不会在快照基础上重复加一', () {
    final MessageStore store = MessageStore();
    addTearDown(store.onClose);

    store.handle_websocket_event(<String, dynamic>{
      'type': 'new_message',
      'data': <String, dynamic>{
        'message': _message(id: 401, type: 2),
        'unread_count': <String, dynamic>{
          'total': 1,
          'comment_unread': 1,
          'comment_total': 1,
          'like_unread': 0,
          'like_total': 0,
          'favorite_unread': 0,
          'favorite_total': 0,
          'chat_unread': 0,
          'system_unread': 0,
        },
      },
    });

    expect(store.comment_unread.value, 1);
    expect(store.unread_total.value, 1);
  });

  test('旧版普通消息重复推送只累加一次', () {
    final MessageStore store = MessageStore();
    addTearDown(store.onClose);

    final Map<String, dynamic> event = <String, dynamic>{
      'type': 'new_message',
      'data': <String, dynamic>{'message': _message(id: 501, type: 3)},
    };
    store.handle_websocket_event(event);
    store.handle_websocket_event(event);

    expect(store.like_unread.value, 1);
    expect(store.unread_total.value, 1);
  });

  test('离线消息补发后由最终快照校准角标且包含系统消息', () {
    final MessageStore store = MessageStore();
    addTearDown(store.onClose);

    store.handle_websocket_event(<String, dynamic>{
      'type': 'new_message',
      'data': <String, dynamic>{'message': _message(id: 601, type: 2)},
    });
    store.handle_websocket_event(<String, dynamic>{
      'type': 'new_message',
      'data': <String, dynamic>{'message': _message(id: 602, type: 1)},
    });
    store.handle_websocket_event(<String, dynamic>{
      'type': 'unread_count',
      'data': <String, dynamic>{
        'total': 2,
        'comment_unread': 1,
        'comment_total': 1,
        'like_unread': 0,
        'like_total': 0,
        'favorite_unread': 0,
        'favorite_total': 0,
        'chat_unread': 0,
        'system_unread': 1,
      },
    });

    expect(store.comment_unread.value, 1);
    expect(store.system_unread.value, 1);
    expect(store.unread_total.value, 2);
  });

  test('其他设备已读事件使用权威快照更新全部角标', () {
    final MessageStore store = MessageStore();
    addTearDown(store.onClose);

    store.handle_websocket_event(<String, dynamic>{
      'type': 'message_state_changed',
      'data': <String, dynamic>{
        'action': 'read',
        'message_id': 701,
        'unread_count': <String, dynamic>{
          'total': 3,
          'comment_unread': 1,
          'comment_total': 4,
          'like_unread': 0,
          'like_total': 2,
          'favorite_unread': 0,
          'favorite_total': 1,
          'chat_unread': 2,
          'system_unread': 0,
        },
      },
    });

    expect(store.comment_unread.value, 1);
    expect(store.chat_unread.value, 2);
    expect(store.unread_total.value, 3);
  });

  test('全部已读后会丢弃操作前发起的旧统计响应', () async {
    _register_logged_user();
    final Completer<MessageUnreadCount?> stale_statistics =
        Completer<MessageUnreadCount?>();
    final Completer<message_api.MessageReadAllResult> read_all =
        Completer<message_api.MessageReadAllResult>();
    final MessageStore store = MessageStore(
      fetch_unread_count: () => stale_statistics.future,
      read_all_messages: () => read_all.future,
    );
    addTearDown(store.onClose);

    store.handle_websocket_event(<String, dynamic>{
      'type': 'unread_count',
      'data': _unread_count(comment: 3),
    });
    final Future<void> stale_request = store.fetch_statistics();
    final Future<void> mark_all_request = store.mark_all_as_read();
    expect(store.unread_total.value, 0);

    stale_statistics.complete(
      MessageUnreadCount.from_json(_unread_count(comment: 3)),
    );
    await stale_request;
    expect(store.unread_total.value, 0);

    read_all.complete(
      message_api.MessageReadAllResult(
        success: true,
        unread_count: MessageUnreadCount.from_json(_unread_count()),
        state_version: 20,
      ),
    );
    await mark_all_request;
    expect(store.unread_total.value, 0);

    store.handle_websocket_event(<String, dynamic>{
      'type': 'chat_receive',
      'data': <String, dynamic>{
        'id': 901,
        'sender_type': 2,
        'content': '全部已读之前排队的旧消息',
        'unread': 3,
        'state_version': 19,
      },
    });
    expect(store.unread_total.value, 0);
    expect(
      store.message_list.where(
        (message) => message.type == MessageType.chat_reply,
      ),
      isEmpty,
    );

    store.handle_websocket_event(<String, dynamic>{
      'type': 'chat_receive',
      'data': <String, dynamic>{
        'id': 902,
        'sender_type': 2,
        'content': '全部已读之后的新消息',
        'unread': 1,
        'state_version': 21,
      },
    });
    expect(store.unread_total.value, 1);
    expect(store.message_list.first.id, 902);
  });

  test('全部已读同步期间到达的新客服消息会在最终校准后保留', () async {
    _register_logged_user();
    final Completer<message_api.MessageReadAllResult> read_all =
        Completer<message_api.MessageReadAllResult>();
    int statistics_requests = 0;
    final MessageStore store = MessageStore(
      read_all_messages: () => read_all.future,
      fetch_unread_count: () async {
        statistics_requests++;
        return MessageUnreadCount.from_json(_unread_count(chat: 1));
      },
    );
    addTearDown(store.onClose);

    store.handle_websocket_event(<String, dynamic>{
      'type': 'unread_count',
      'data': _unread_count(chat: 2),
    });
    final Future<void> mark_all_request = store.mark_all_as_read();
    store.handle_websocket_event(<String, dynamic>{
      'type': 'chat_receive',
      'data': <String, dynamic>{
        'id': 801,
        'sender_type': 2,
        'content': '操作期间的新消息',
        'create_time': '2026-07-28T02:00:00.000Z',
        'unread': 1,
      },
    });
    expect(store.unread_total.value, 0);

    read_all.complete(
      message_api.MessageReadAllResult(
        success: true,
        unread_count: MessageUnreadCount.from_json(_unread_count()),
      ),
    );
    await mark_all_request;

    expect(statistics_requests, 1);
    expect(store.chat_unread.value, 1);
    expect(store.unread_total.value, 1);
    expect(store.message_list.first.id, 801);
    expect(store.message_list.first.display_subtitle, '操作期间的新消息');
  });
}

Map<String, dynamic> _message({required int id, required int type}) {
  return <String, dynamic>{
    'id': id,
    'user_id': 9,
    'title': '',
    'introduction': '',
    'content': '{}',
    'type': type,
    'send_user': 8,
    'send_time': '2026-07-28T00:00:00.000Z',
    'notify_status': 1,
    'sender_name': 'Tester',
    'sender_avatar': '',
    'novel_cover': '',
  };
}

Map<String, dynamic> _unread_count({
  int comment = 0,
  int like = 0,
  int favorite = 0,
  int system = 0,
  int chat = 0,
}) {
  return <String, dynamic>{
    'total': comment + like + favorite + system + chat,
    'comment_unread': comment,
    'comment_total': comment,
    'like_unread': like,
    'like_total': like,
    'favorite_unread': favorite,
    'favorite_total': favorite,
    'system_unread': system,
    'chat_unread': chat,
  };
}

void _register_logged_user() {
  Get.testMode = true;
  Get.put<UserInformation>(UserInformation()).isLoggedIn.value = true;
  addTearDown(Get.reset);
}
