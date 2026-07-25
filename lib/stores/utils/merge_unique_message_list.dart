// ignore_for_file: non_constant_identifier_names

import 'package:app/models/message_data.dart';

/// 合并已有消息与新一页消息，并按稳定身份去重。
///
/// 首次出现的消息会保留原有位置，分页重叠数据和单页重复数据都会被过滤。
List<MessageData> merge_unique_message_list({
  required Iterable<MessageData> current_messages,
  required Iterable<MessageData> incoming_messages,
}) {
  final List<MessageData> merged_messages = <MessageData>[];
  final Set<String> identity_keys = <String>{};

  for (final MessageData message in <MessageData>[
    ...current_messages,
    ...incoming_messages,
  ]) {
    if (identity_keys.add(message.identity_key)) {
      merged_messages.add(message);
    }
  }

  return merged_messages;
}
