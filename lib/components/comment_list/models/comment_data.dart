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
      is_liked: json['is_liked'] == true || json['is_liked'] == 1,
      replies: replies,
      reply_to_nickname: json['reply_to_nickname']?.toString(),
      parent_id: _parse_int(json['parent_id']),
      score: _parse_int(json['score']),
    );
  }

  /// 解析整数，兼容字符串和数字类型。
  static int _parse_int(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  /// 复制当前评论对象并修改部分字段。
  ///
  /// 用于点赞等操作后的状态更新。
  CommentData copy_with({
    int? like_count,
    bool? is_liked,
    List<CommentData>? replies,
    String? reply_to_nickname,
  }) {
    return CommentData(
      id: id,
      user_id: user_id,
      avatar: avatar,
      nickname: nickname,
      content: content,
      time: time,
      like_count: like_count ?? this.like_count,
      is_liked: is_liked ?? this.is_liked,
      replies: replies ?? this.replies,
      reply_to_nickname: reply_to_nickname ?? this.reply_to_nickname,
      parent_id: parent_id,
      score: score,
    );
  }
}
