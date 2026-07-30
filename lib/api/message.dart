// ignore_for_file: non_constant_identifier_names

import 'package:flutter/foundation.dart';
import 'package:app/api/post_request.dart';
import 'package:app/api/results_type.dart';
import 'package:app/models/message_data.dart';

/// 全部已读接口结果。
class MessageReadAllResult {
  /// 接口是否执行成功。
  final bool success;

  /// 操作完成后的权威未读快照。
  final MessageUnreadCount? unread_count;

  /// 服务端为本次未读状态变更生成的单调版本号。
  final int state_version;

  const MessageReadAllResult({
    required this.success,
    this.unread_count,
    this.state_version = 0,
  });
}

/// 查询消息列表接口。
///
/// [page] 页码，默认1。
/// [page_size] 每页数量，默认20。
/// [type] 消息类型（可选，1=系统通知 2=评论回复 3=评论点赞 4=小说点赞 5=小说收藏）。
/// 返回消息列表结果，失败时返回 null。
Future<MessageListResult?> inquire_message_list({
  int page = 1,
  int page_size = 20,
  int? type,
}) async {
  final Map<String, dynamic> parameter = {'page': page, 'page_size': page_size};

  // TODO 如果指定了消息类型，添加筛选参数
  if (type != null && type > 0) {
    parameter['type'] = type;
  }

  final ResultsType<Map<String, dynamic>> results =
      await postRequest<Map<String, dynamic>>(
        path: 'message/inquire',
        parameter: parameter,
        showTips: false,
        fromJson: (json) => json,
      );

  if (!results.status || results.content == null) {
    debugPrint(
      'TODO inquire_message_list 失败: status=${results.status}, message=${results.message}',
    );
    return null;
  }
  return MessageListResult.from_json(results.content!);
}

/// 获取未读消息数量接口（已登录用户）。
///
/// 返回未读数结果，失败时返回 null。
Future<MessageUnreadCount?> get_unread_count() async {
  final ResultsType<Map<String, dynamic>> results =
      await postRequest<Map<String, dynamic>>(
        path: 'message/unread_count',
        showTips: false,
        fromJson: (json) => json,
      );

  if (!results.status || results.content == null) {
    debugPrint(
      'TODO get_unread_count 失败: status=${results.status}, message=${results.message}',
    );
    return null;
  }
  return MessageUnreadCount.from_json(results.content!);
}

/// 获取访客的客服聊天未读消息数接口（未登录用户）。
///
/// [visitor_id] 访客 UUID。
/// 返回未读消息数，失败时返回 0。
Future<int> get_visitor_chat_unread({required String visitor_id}) async {
  final ResultsType<Map<String, dynamic>> results =
      await postRequest<Map<String, dynamic>>(
        path: 'customer_service_chat/visitor_unread_count',
        parameter: {'visitor_id': visitor_id},
        showTips: false,
        fromJson: (json) => json,
      );

  if (!results.status || results.content == null) {
    debugPrint(
      'TODO get_visitor_chat_unread 失败: status=${results.status}, message=${results.message}',
    );
    return 0;
  }
  return results.content!['unread'] is int
      ? results.content!['unread'] as int
      : int.tryParse(results.content!['unread']?.toString() ?? '0') ?? 0;
}

/// 标记单条消息为已读接口。
///
/// [id] 消息ID（必传）。
/// 返回是否成功，失败时返回 false。
Future<bool> read_message({required int id}) async {
  final ResultsType<Map<String, dynamic>> results =
      await postRequest<Map<String, dynamic>>(
        path: 'message/read',
        parameter: {'id': id},
        showTips: false,
        fromJson: (json) => json,
      );

  return results.status;
}

/// 标记所有消息为已读接口。
///
/// 返回执行结果及操作完成后的权威未读快照。
Future<MessageReadAllResult> read_all_messages() async {
  final ResultsType<Map<String, dynamic>> results =
      await postRequest<Map<String, dynamic>>(
        path: 'message/read_all',
        showTips: false,
        fromJson: (json) => json,
      );

  if (!results.status) {
    return const MessageReadAllResult(success: false);
  }

  final dynamic unread_data = results.content?['unread_count'];
  return MessageReadAllResult(
    success: true,
    unread_count: unread_data is Map
        ? MessageUnreadCount.from_json(Map<String, dynamic>.from(unread_data))
        : null,
    state_version: results.content?['state_version'] is int
        ? results.content!['state_version'] as int
        : int.tryParse(results.content?['state_version']?.toString() ?? '0') ??
              0,
  );
}

/// 标记所有在线客服消息为已读接口。
///
/// 返回是否成功，失败时返回 false。
Future<bool> read_all_chat_messages() async {
  final ResultsType<Map<String, dynamic>> results =
      await postRequest<Map<String, dynamic>>(
        path: 'customer_service_chat/read_all',
        showTips: false,
        fromJson: (json) => json,
      );

  return results.status;
}

/// 删除单条消息接口。
///
/// [id] 消息ID（必传）。
/// 返回是否成功，失败时返回 false。
Future<bool> delete_message({required int id}) async {
  final ResultsType<Map<String, dynamic>> results =
      await postRequest<Map<String, dynamic>>(
        path: 'message/delete',
        parameter: {'id': id},
        showTips: false,
        fromJson: (json) => json,
      );

  return results.status;
}
