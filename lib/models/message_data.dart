// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'package:easy_localization/easy_localization.dart' as easy;

/// 消息类型常量。
class MessageType {
  /// 系统通知：后台手动发送。
  static const int system = 1;

  /// 评论回复：用户A回复用户B的评论。
  static const int comment_reply = 2;

  /// 评论点赞：用户A点赞用户B的评论。
  static const int comment_like = 3;

  /// 小说点赞：用户A点赞用户B的小说。
  static const int novel_like = 4;

  /// 小说收藏：用户A收藏用户B的小说。
  static const int novel_favorite = 5;

  /// 客服回复：管理员通过在线客服发送的回复消息。
  static const int chat_reply = 6;
}

/// 消息已读状态常量。
class NotifyStatus {
  /// 未读。
  static const int unread = 1;

  /// 已读。
  static const int read = 2;
}

/// 消息数据模型。
///
/// 对应后端 novel_message 表。
class MessageData {
  /// 消息ID。
  final int id;

  /// 接收消息的用户ID。
  final int user_id;

  /// 消息标题（系统通知时有值，其他类型为空）。
  final String title;

  /// 消息摘要（系统通知时有值，其他类型为空）。
  final String introduction;

  /// 消息完整内容（JSON字符串）。
  final String content;

  /// 消息类型（1=系统通知 2=评论回复 3=评论点赞 4=小说点赞 5=小说收藏）。
  final int type;

  /// 发送消息的用户ID（自己操作的记录时为0，他人通知时>0）。
  final int send_user;

  /// 消息发送时间。
  final String send_time;

  /// 已读状态（1=未读 2=已读）。
  final int notify_status;

  /// 发送者昵称。
  final String sender_name;

  /// 发送者头像URL。
  final String sender_avatar;

  /// 小说封面URL（后端关联查询获取）。
  final String novel_cover;

  const MessageData({
    required this.id,
    required this.user_id,
    required this.title,
    required this.introduction,
    required this.content,
    required this.type,
    required this.send_user,
    required this.send_time,
    required this.notify_status,
    required this.sender_name,
    required this.sender_avatar,
    this.novel_cover = '',
  });

  /// 从后端接口返回的 JSON 数据解析。
  factory MessageData.from_json(Map<String, dynamic> json) {
    return MessageData(
      id: _parse_int(json['id']),
      user_id: _parse_int(json['user_id']),
      title: json['title']?.toString() ?? '',
      introduction: json['introduction']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      type: _parse_int(json['type']),
      send_user: _parse_int(json['send_user']),
      send_time: json['send_time']?.toString() ?? '',
      notify_status: _parse_int(json['notify_status']),
      sender_name: json['sender_name']?.toString() ?? '',
      sender_avatar: json['sender_avatar']?.toString() ?? '',
      novel_cover: json['novel_cover']?.toString() ?? '',
    );
  }

  /// 是否未读。
  bool get is_unread => notify_status == NotifyStatus.unread;

  /// 是否有小说封面。
  bool get has_novel_cover => novel_cover.isNotEmpty;

  /// 是否是自己的操作记录（send_user == 0 表示自己操作的记录）。
  bool get is_self_record => send_user == 0;

  /// 列表中的稳定身份标识。
  ///
  /// 客服消息来自独立的数据表，其数字 ID 可能与普通消息 ID 重复，因此需要按来源隔离。
  String get identity_key {
    final String source = type == MessageType.chat_reply ? 'chat' : 'message';
    return '${source}_$id';
  }

  /// 解析 content JSON 为 Map。
  Map<String, dynamic> get content_map {
    try {
      if (content.isEmpty) return {};
      final decoded = json.decode(content);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (e) {
      return {};
    }
  }

  /// 获取小说ID。
  int get novel_id => _parse_int(content_map['novel_id']);

  /// 获取小说标题。
  String get novel_title => content_map['novel_title']?.toString() ?? '';

  /// 获取小说发布状态（1=连载中 2=已完结 3=下架 4=短篇）。
  int get novel_publish_status =>
      _parse_int(content_map['novel_publish_status']);

  /// 获取评论ID。
  int get comment_id => _parse_int(content_map['comment_id']);

  /// 获取父评论ID（回复时有值）。
  int get parent_id => _parse_int(content_map['parent_id']);

  /// 获取消息类型的 i18n key。
  String get type_key {
    switch (type) {
      case MessageType.system:
        return 'system';
      case MessageType.comment_reply:
        return 'comment_reply';
      case MessageType.comment_like:
        return 'comment_like';
      case MessageType.novel_like:
        return 'novel_like';
      case MessageType.novel_favorite:
        return 'novel_favorite';
      case MessageType.chat_reply:
        return 'chat_reply';
      default:
        return 'system';
    }
  }

  /// 获取卡片标题（已国际化的文本）。
  String get display_title {
    // TODO 系统通知使用存储的标题
    if (type == MessageType.system && title.isNotEmpty) {
      return title;
    }
    // TODO 客服回复使用固定标题
    if (type == MessageType.chat_reply) {
      return easy.tr('message.card_title.chat_reply');
    }
    // TODO 其他类型从 i18n 推导
    return easy.tr('message.card_title.$type_key');
  }

  /// 获取卡片副标题（已国际化的文本）。
  String get display_subtitle {
    // TODO 系统通知使用存储的摘要
    if (type == MessageType.system) {
      return introduction.isNotEmpty ? introduction : '';
    }
    // TODO 客服回复直接显示消息内容
    if (type == MessageType.chat_reply) {
      return introduction.isNotEmpty ? introduction : content;
    }

    // TODO 根据类型和是否自己操作，选择对应的 i18n 模板
    final String suffix = is_self_record ? 'self' : 'other';
    final String i18n_key = 'message.card_subtitle.${type_key}_$suffix';

    // TODO 获取模板后手动替换占位符
    final String template = easy.tr(i18n_key);
    return template.replaceAll('{0}', novel_title);
  }

  /// 获取标签文字（已国际化的文本）。
  String get display_badge {
    return easy.tr('message.type.$type_key');
  }

  /// 解析整数，兼容字符串和数字类型。
  static int _parse_int(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}

/// 消息列表结果模型。
class MessageListResult {
  /// 消息列表。
  final List<MessageData> list;

  /// 总消息数。
  final int total;

  /// 当前页码。
  final int page;

  /// 每页数量。
  final int page_size;

  /// 客服聊天未读数。
  final int chat_unread;

  /// 最新一条未读客服消息。
  final MessageData? chat_message;

  const MessageListResult({
    required this.list,
    required this.total,
    required this.page,
    required this.page_size,
    this.chat_unread = 0,
    this.chat_message,
  });

  /// 从后端接口返回的 JSON 数据解析。
  factory MessageListResult.from_json(Map<String, dynamic> json) {
    final List<dynamic> raw_list = json['list'] ?? [];

    // 解析客服消息
    MessageData? chat_message;
    final chat_data = json['chat_message'];
    if (chat_data is Map<String, dynamic> && chat_data.isNotEmpty) {
      chat_message = MessageData(
        id: _parse_int(chat_data['id'].toString().replaceAll('chat_', '')),
        user_id: 0,
        title: '',
        introduction: chat_data['content']?.toString() ?? '',
        content: chat_data['content']?.toString() ?? '',
        type: 6, // chat_reply
        send_user: 0,
        send_time: chat_data['send_time']?.toString() ?? '',
        notify_status: 1, // unread
        sender_name: '客服',
        sender_avatar: '',
      );
    }

    return MessageListResult(
      list: raw_list
          .map((e) => MessageData.from_json(Map<String, dynamic>.from(e)))
          .toList(),
      total: _parse_int(json['total']),
      page: _parse_int(json['page']),
      page_size: _parse_int(json['page_size']),
      chat_unread: _parse_int(json['chat_unread']),
      chat_message: chat_message,
    );
  }

  /// 解析整数，兼容字符串和数字类型。
  static int _parse_int(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}

/// 消息未读数结果模型。
class MessageUnreadCount {
  /// 总未读数（消息通知 + 客服聊天）。
  final int total;

  /// 评论相关未读数（评论回复）。
  final int comment_unread;

  /// 评论相关总数。
  final int comment_total;

  /// 点赞相关未读数（评论点赞 + 小说点赞）。
  final int like_unread;

  /// 点赞相关总数。
  final int like_total;

  /// 收藏相关未读数（小说收藏）。
  final int favorite_unread;

  /// 收藏相关总数。
  final int favorite_total;

  /// 客服聊天未读数。
  final int chat_unread;

  const MessageUnreadCount({
    required this.total,
    required this.comment_unread,
    required this.comment_total,
    required this.like_unread,
    required this.like_total,
    required this.favorite_unread,
    required this.favorite_total,
    required this.chat_unread,
  });

  /// 从后端接口返回的 JSON 数据解析。
  factory MessageUnreadCount.from_json(Map<String, dynamic> json) {
    return MessageUnreadCount(
      total: _parse_int(json['total']),
      comment_unread: _parse_int(json['comment_unread']),
      comment_total: _parse_int(json['comment_total']),
      like_unread: _parse_int(json['like_unread']),
      like_total: _parse_int(json['like_total']),
      favorite_unread: _parse_int(json['favorite_unread']),
      favorite_total: _parse_int(json['favorite_total']),
      chat_unread: _parse_int(json['chat_unread']),
    );
  }

  /// 解析整数，兼容字符串和数字类型。
  static int _parse_int(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}
