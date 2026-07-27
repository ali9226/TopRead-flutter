// ignore_for_file: non_constant_identifier_names

import 'package:flutter/foundation.dart';
import 'package:app/api/post_request.dart';
import 'package:app/api/results_type.dart';
import 'package:app/models/message_data.dart';

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
    final Map<String, dynamic> parameter = {
        'page': page,
        'page_size': page_size,
    };

    // TODO 如果指定了消息类型，添加筛选参数
    if (type != null && type > 0) {
        parameter['type'] = type;
    }

    final ResultsType<Map<String, dynamic>> results = await postRequest<Map<String, dynamic>>(
        path: 'message/inquire',
        parameter: parameter,
        showTips: false,
        fromJson: (json) => json,
    );

    if (!results.status || results.content == null) {
        debugPrint('TODO inquire_message_list 失败: status=${results.status}, message=${results.message}');
        return null;
    }
    return MessageListResult.from_json(results.content!);
}

/// 获取未读消息数量接口（已登录用户）。
///
/// 返回未读数结果，失败时返回 null。
Future<MessageUnreadCount?> get_unread_count() async {
    final ResultsType<Map<String, dynamic>> results = await postRequest<Map<String, dynamic>>(
        path: 'message/unread_count',
        showTips: false,
        fromJson: (json) => json,
    );

    if (!results.status || results.content == null) {
        debugPrint('TODO get_unread_count 失败: status=${results.status}, message=${results.message}');
        return null;
    }
    return MessageUnreadCount.from_json(results.content!);
}

/// 获取访客的客服聊天未读消息数接口（未登录用户）。
///
/// [visitor_id] 访客 UUID。
/// 返回未读消息数，失败时返回 0。
Future<int> get_visitor_chat_unread({required String visitor_id}) async {
    final ResultsType<Map<String, dynamic>> results = await postRequest<Map<String, dynamic>>(
        path: 'customer_service_chat/visitor_unread_count',
        parameter: {'visitor_id': visitor_id},
        showTips: false,
        fromJson: (json) => json,
    );

    if (!results.status || results.content == null) {
        debugPrint('TODO get_visitor_chat_unread 失败: status=${results.status}, message=${results.message}');
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
    final ResultsType<Map<String, dynamic>> results = await postRequest<Map<String, dynamic>>(
        path: 'message/read',
        parameter: {'id': id},
        showTips: false,
        fromJson: (json) => json,
    );

    return results.status;
}

/// 标记所有消息为已读接口。
///
/// 返回是否成功，失败时返回 false。
Future<bool> read_all_messages() async {
    final ResultsType<Map<String, dynamic>> results = await postRequest<Map<String, dynamic>>(
        path: 'message/read_all',
        showTips: false,
        fromJson: (json) => json,
    );

    return results.status;
}

/// 标记所有在线客服消息为已读接口。
///
/// 返回是否成功，失败时返回 false。
Future<bool> read_all_chat_messages() async {
    final ResultsType<Map<String, dynamic>> results = await postRequest<Map<String, dynamic>>(
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
    final ResultsType<Map<String, dynamic>> results = await postRequest<Map<String, dynamic>>(
        path: 'message/delete',
        parameter: {'id': id},
        showTips: false,
        fromJson: (json) => json,
    );

    return results.status;
}
