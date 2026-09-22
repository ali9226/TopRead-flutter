// ignore_for_file: non_constant_identifier_names

/// 评论数据模型。
///
/// 用于评论列表的数据展示，支持嵌套回复结构。
/// 数据来源为后端 novel_comment 接口。
class CommentData {
  /// 评论 ID。
  final int id;

  /// 用户ID。
  final int user_id;

  /// 用户头像 URL。
  final String avatar;

  /// 用户昵称。
  final String nickname;

  /// 评论内容。
  final String content;

  /// 评论时间（ISO 格式字符串，如 "2024-01-01 12:00:00"）。
  final String time;

  /// 点赞数。
  final int like_count;

  /// 当前用户是否已点赞。
  final bool is_liked;

  /// 回复列表（嵌套评论）。
  final List<CommentData> replies;

  /// 被回复用户的昵称（仅回复时显示）。
  final String? reply_to_nickname;

  /// 父评论ID，0表示顶层评论。
  final int parent_id;

  /// 评分（1-5）。
  final int score;

  /// 段落ID（段评时有值，普通评论为 null）。
  final int? paragraph_id;

  /// 段落内容（段评时有值，用于在小说评论列表中展示）。
  final String? paragraph_text;

  /// 是否正在发送中（显示沙漏动画，禁用长按和点赞）。
  final bool is_sending;

  /// 是否被当前用户标记为不喜欢（显示折叠样式）。
  final bool is_disliked;

  /// 是否已被作者/管理员删除（显示"已删除"标记，禁用交互，子回复仍可见）。
  final bool is_deleted;

  const CommentData({
    required this.id,
    required this.user_id,
    required this.avatar,
    required this.nickname,
    required this.content,
    required this.time,
    this.like_count = 0,
    this.is_liked = false,
    this.replies = const [],
    this.reply_to_nickname,
    this.parent_id = 0,
    this.score = 5,
    this.paragraph_id,
    this.paragraph_text,
    this.is_sending = false,
    this.is_disliked = false,
    this.is_deleted = false,
  });

  /// 从后端接口返回的 JSON 数据解析评论对象。
  ///
  /// [json] 后端返回的评论数据 Map。
  /// 返回解析后的 [CommentData] 对象。
  factory CommentData.from_json(Map<String, dynamic> json) {
    // TODO 解析回复列表（如果有）
    List<CommentData> replies = [];
    if (json['replies'] != null && json['replies'] is List) {
      replies = (json['replies'] as List)
          .map((e) => CommentData.from_json(Map<String, dynamic>.from(e)))
          .toList();
    }

    return CommentData(
      id: _parse_int(json['id']),
      user_id: _parse_int(json['user_id']),
      avatar: json['avatar_url']?.toString() ?? '',
      nickname: json['nickname']?.toString() ?? '',
      content: json['comment_content']?.toString() ?? '',
      time: json['create_time']?.toString() ?? '',
      like_count: _parse_int(json['like_count']),
      is_liked: _parse_bool(json['like'] ?? json['is_liked']),
      is_disliked: _parse_bool(json['is_disliked']),
      is_deleted: _parse_bool(json['is_deleted']),
      replies: replies,
      reply_to_nickname: json['reply_to_nickname']?.toString(),
      parent_id: _parse_int(json['parent_id']),
      score: _parse_int(json['score']),
      paragraph_id: json['paragraph_id'] != null ? _parse_int(json['paragraph_id']) : null,
      paragraph_text: json['paragraph_text']?.toString(),
    );
  }

  /// 解析整数，兼容字符串和数字类型。
  static int _parse_int(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  /// 解析布尔值，兼容接口返回的 bool、数字和字符串格式。
  static bool _parse_bool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final String normalized_value =
        value?.toString().trim().toLowerCase() ?? '';
    return normalized_value == 'true' || normalized_value == '1';
  }

  /// 复制当前评论对象并修改部分字段。
  ///
  /// 用于点赞等操作后的状态更新。
  CommentData copy_with({
    int? id,
    int? like_count,
    bool? is_liked,
    bool? is_disliked,
    bool? is_deleted,
    List<CommentData>? replies,
    String? reply_to_nickname,
    bool? is_sending,
  }) {
    return CommentData(
      id: id ?? this.id,
      user_id: user_id,
      avatar: avatar,
      nickname: nickname,
      content: content,
      time: time,
      like_count: like_count ?? this.like_count,
      is_liked: is_liked ?? this.is_liked,
      is_disliked: is_disliked ?? this.is_disliked,
      is_deleted: is_deleted ?? this.is_deleted,
      replies: replies ?? this.replies,
      reply_to_nickname: reply_to_nickname ?? this.reply_to_nickname,
      parent_id: parent_id,
      score: score,
      paragraph_id: paragraph_id,
      paragraph_text: paragraph_text,
      is_sending: is_sending ?? this.is_sending,
    );
  }
}
