// ignore_for_file: non_constant_identifier_names

import 'package:app/models/message_data.dart';
import 'package:app/stores/utils/merge_unique_message_list.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('分页合并会过滤当前页和相邻页中的重复消息', () {
    final List<MessageData> merged_messages = merge_unique_message_list(
      current_messages: <MessageData>[
        _build_message(id: 1),
        _build_message(id: 2),
      ],
      incoming_messages: <MessageData>[
        _build_message(id: 2),
        _build_message(id: 3),
        _build_message(id: 3),
      ],
    );

    expect(
      merged_messages.map((MessageData message) => message.id),
      <int>[1, 2, 3],
    );
  });

  test('客服消息和普通消息的数字 ID 相同时仍保留两条数据', () {
    final List<MessageData> merged_messages = merge_unique_message_list(
      current_messages: <MessageData>[_build_message(id: 8)],
      incoming_messages: <MessageData>[
        _build_message(id: 8, type: MessageType.chat_reply),
      ],
    );

    expect(merged_messages, hasLength(2));
    expect(
      merged_messages.map((MessageData message) => message.identity_key),
      <String>['message_8', 'chat_8'],
    );
  });
}

MessageData _build_message({
  required int id,
  int type = MessageType.novel_favorite,
}) {
  return MessageData(
    id: id,
    user_id: 1,
    title: '',
    introduction: '',
    content: '',
    type: type,
    send_user: 2,
    send_time: '2026-07-25T00:00:00.000Z',
    notify_status: NotifyStatus.unread,
    sender_name: '',
    sender_avatar: '',
  );
}
