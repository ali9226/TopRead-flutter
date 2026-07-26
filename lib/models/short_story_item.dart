// ignore_for_file: non_constant_identifier_names

/// 短篇小说数据模型。
///
/// 对应 `novel/short_story` 接口返回的 content 数组中的单条记录。
class ShortStoryItem {
  /// 唯一标识。
  final int id;

  /// 作者ID。
  final int author_id;

  /// 作者名称。
  final String author_name;

  /// 作者头像URL。
  final String author_avatar;

  /// 标题。
  final String title;

  /// 简介（接口字段 introduction）。
  final String description;

  /// 封面图片URL。
  final String cover_url;

  /// 分类标签列表（接口字段 category_list）。
  final List<String> tags;

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

  /// 是否已点赞（接口字段 like）。
  final bool is_liked;

  /// 正文内容文件地址。
  final String content_url;

  /// 是否展开（默认收起状态）。
  final bool is_expanded;

  const ShortStoryItem({
    required this.id,
    this.author_id = 0,
    this.author_name = '',
    this.author_avatar = '',
    required this.title,
    required this.description,
    this.cover_url = '',
    required this.tags,
    this.read_count = 0,
    this.comment_count = 0,
    required this.like_count,
    this.favorite_count = 0,
    this.score = '',
    this.is_liked = false,
    this.content_url = '',
    this.is_expanded = false,
  });

  /// 返回一个新的 [ShortStoryItem]，仅替换传入的字段，其余保持不变。
  ShortStoryItem copyWith({
    bool? is_liked,
    int? like_count,
    bool? is_expanded,
  }) {
    return ShortStoryItem(
      id: id,
      author_id: author_id,
      author_name: author_name,
      author_avatar: author_avatar,
      title: title,
      description: description,
      cover_url: cover_url,
      tags: tags,
      read_count: read_count,
      comment_count: comment_count,
      like_count: like_count ?? this.like_count,
      favorite_count: favorite_count,
      score: score,
      is_liked: is_liked ?? this.is_liked,
      content_url: content_url,
      is_expanded: is_expanded ?? this.is_expanded,
    );
  }

  /// 从接口返回的单条 json 中解析业务对象。
  factory ShortStoryItem.from_json(Map<String, dynamic> json) {
    return ShortStoryItem(
      id: _to_int(json['id']),
      author_id: _to_int(json['author_id']),
      author_name: _to_string(json['author_name']),
      author_avatar: _to_string(json['author_avatar']),
      title: _to_string(json['title']),
      description: _to_string(json['introduction']),
      cover_url: _to_string(json['cover_url']),
      tags: _parse_string_list(json['category_list']),
      read_count: _to_int(json['read_count']),
      comment_count: _to_int(json['comment_count']),
      like_count: _to_int(json['like_count']),
      favorite_count: _to_int(json['favorite_count']),
      score: _to_string(json['score']),
      is_liked: json['like'] == true || json['like'] == 1,
      content_url: _to_string(json['content_url']),
    );
  }

  /// 批量解析接口返回数组。
  static List<ShortStoryItem> from_json_list(List<dynamic> json_list) {
    final List<ShortStoryItem> result = <ShortStoryItem>[];
    for (final dynamic item in json_list) {
      if (item is Map) {
        try {
          result.add(ShortStoryItem.from_json(Map<String, dynamic>.from(item)));
        } catch (_) {}
      }
    }
    return result;
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
