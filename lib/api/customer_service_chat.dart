// ignore_for_file: non_constant_identifier_names

import 'package:app/api/post_request.dart';

/// 在线客服聊天 API。
class CustomerServiceChatApi {
  /// 获取当前用户的聊天历史消息。
  ///
  /// 支持已登录用户（user_id）和访客（visitor_id）。
  /// 自动查找或创建会话，返回历史消息和会话信息。
  static Future<Map<String, dynamic>?> get_my_history({
    int user_id = 0,
    String visitor_id = '',
    int page_size = 10,
    List<int> exclude_ids = const <int>[],
  }) async {
    final Map<String, dynamic> params = {
      'page': 1,
      'page_size': page_size,
      'exclude_ids': exclude_ids,
    };

    if (user_id > 0) {
      params['user_id'] = user_id;
    } else if (visitor_id.isNotEmpty) {
      params['visitor_id'] = visitor_id;
    } else {
      return null;
    }

    final results = await postRequest<Map<String, dynamic>>(
      path: 'customer_service_chat/my_history',
      parameter: params,
      showTips: false,
      fromJson: (json) => json,
    );

    if (results.status && results.content != null) {
      return results.content;
    }
    return null;
  }
}
