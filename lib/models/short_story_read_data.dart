// ignore_for_file: non_constant_identifier_names

/// 短篇小说阅读详情数据模型。
///
/// 对应 `novel/short_story_read` 接口返回的 content 对象。
class ShortStoryReadData {
  /// 唯一标识。
  final int id;

  /// 标题。
  final String title;

  /// 简介。
  final String introduction;

  /// 封面图片URL。
  final String cover_url;

  /// 正文内容文件地址。
  final String content_url;

  /// 阅读数。
  final int read_count;

  /// 评论数。
  final int comment_count;

  /// 点赞数。
  final int like_count;

  /// 收藏数。
  final int favorite_count;

  /// 评分。
  final String score;

  /// 分类标签列表。
  final List<String> category_list;

  /// 是否已点赞。
  final bool is_liked;

  /// 是否已收藏。
  final bool is_favorited;

  const ShortStoryReadData({
    required this.id,
    required this.title,
    required this.introduction,
    this.cover_url = '',
    required this.content_url,
    this.read_count = 0,
    this.comment_count = 0,
    this.like_count = 0,
    this.favorite_count = 0,
    this.score = '',
    this.category_list = const <String>[],
    this.is_liked = false,
    this.is_favorited = false,
  });

  /// 返回一个新的 [ShortStoryReadData]，仅替换传入的字段，其余保持不变。
  ShortStoryReadData copyWith({
    bool? is_liked,
    int? like_count,
    int? comment_count,
    bool? is_favorited,
    int? favorite_count,
  }) {
    return ShortStoryReadData(
      id: id,
      title: title,
      introduction: introduction,
      cover_url: cover_url,
      content_url: content_url,
      read_count: read_count,
      comment_count: comment_count ?? this.comment_count,
      like_count: like_count ?? this.like_count,
      favorite_count: favorite_count ?? this.favorite_count,
      score: score,
      category_list: category_list,
      is_liked: is_liked ?? this.is_liked,
      is_favorited: is_favorited ?? this.is_favorited,
    );
  }

  /// 从接口返回的 json 中解析业务对象。
  factory ShortStoryReadData.from_json(Map<String, dynamic> json) {
    return ShortStoryReadData(
      id: _to_int(json['id']),
      title: _to_string(json['title']),
      introduction: _to_string(json['introduction']),
      cover_url: _to_string(json['cover_url']),
      content_url: _to_string(json['content_url']),
      read_count: _to_int(json['read_count']),
      comment_count: _to_int(json['comment_count']),
      like_count: _to_int(json['like_count']),
      favorite_count: _to_int(json['favorite_count']),
      score: _to_string(json['score']),
      category_list: _parse_string_list(json['category_list']),
      is_liked: json['like'] == true || json['like'] == 1,
      is_favorited: json['favorite'] == true || json['favorite'] == 1,
    );
  }
}

List<String> _parse_string_list(dynamic raw) {
  if (raw is! List) return const <String>[];
  return raw.map((dynamic e) => e.toString()).toList();
}

int _to_int(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

String _to_string(dynamic value) {
  return value?.toString() ?? '';
}
