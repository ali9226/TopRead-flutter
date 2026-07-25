// ignore_for_file: non_constant_identifier_names

/// 小说详情数据模型。
class NovelInfo {
  /// 小说唯一 id。
  final String id;

  /// 小说标题。
  final String title;

  /// 小说副标题。
  final String subtitle;

  // TODO 小说评分
  final int score;



  /// 作者 id。
  final String author_id;

  /// 来源类型。
  final int source_type;

  /// 用户是否关注作者
  final bool focus_on;

  /// 用户是否已点赞
  final bool is_liked;

  /// 用户是否已收藏
  final bool is_favorited;

  /// 发布状态。
  final int publish_status;

  /// 推荐状态。
  final int recommend_status;

  /// 排序值。
  final int sorting;

  /// 阅读量。
  final String read_count;

  /// 评论量。
  final String comment_count;

  /// 点赞量。
  final String like_count;

  /// 收藏量。
  final String favorite_count;

  /// 最新章节号。
  final int latest_chapter_no;

  /// 最新更新时间。
  final String latest_update_time;

  /// 备注。
  final String remark;

  /// 创建时间。
  final String create_time;

  /// 更新时间。
  final String update_time;

  /// 删除状态。
  final int remove_status;

  /// 删除时间。
  final String? remove_time;

  /// 作者名称。
  final String author_name;

  /// 作者头像。
  final String author_avatar;

  /// 语种相关信息。
  final NovelLanguageInfo language_info;

  /// 分类列表。
  final List<String> category_list;

  /// 评论列表。
  final List<NovelComment> comment_list;

  /// 章节信息。
  final NovelChapterInfo? chapter_info;

  NovelInfo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.score,
    required this.focus_on,
    this.is_liked = false,
    this.is_favorited = false,
    required this.author_id,
    required this.source_type,
    required this.publish_status,
    required this.recommend_status,
    required this.sorting,
    required this.read_count,
    required this.comment_count,
    required this.like_count,
    required this.favorite_count,
    required this.latest_chapter_no,
    required this.latest_update_time,
    required this.remark,
    required this.create_time,
    required this.update_time,
    required this.remove_status,
    this.remove_time,
    required this.author_name,
    required this.author_avatar,
    required this.language_info,
    required this.category_list,
    required this.comment_list,
    this.chapter_info,
  });

  factory NovelInfo.from_json(Map<String, dynamic> json) {
    return NovelInfo(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      author_id: json['author_id']?.toString() ?? '',
      focus_on: json['focus_on'] is bool
          ? json['focus_on']
          : false,
      is_liked: json['like'] == true,
      is_favorited: json['favorite'] == true,
      score: _parse_int(json['score']),
      source_type: _parse_int(json['source_type']),
      publish_status: _parse_int(json['publish_status']),
      recommend_status: _parse_int(json['recommend_status']),
      sorting: _parse_int(json['sorting']),
      read_count: json['read_count']?.toString() ?? '0',
      comment_count: json['comment_count']?.toString() ?? '0',
      like_count: json['like_count']?.toString() ?? '0',
      favorite_count: json['favorite_count']?.toString() ?? '0',
      latest_chapter_no: _parse_int(json['latest_chapter_no']),
      latest_update_time: json['latest_update_time']?.toString() ?? '',
      remark: json['remark']?.toString() ?? '',
      create_time: json['create_time']?.toString() ?? '',
      update_time: json['update_time']?.toString() ?? '',
      remove_status: _parse_int(json['remove_status']),
      remove_time: json['remove_time']?.toString(),
      author_name: json['author_name']?.toString() ?? '',
      author_avatar: json['author_avatar']?.toString() ?? '',
      language_info: NovelLanguageInfo.from_json(
          Map<String, dynamic>.from(json['language_info'] ?? {})),
      category_list: List<String>.from(json['category_list'] ?? []),
      comment_list: (json['comment_list'] as List? ?? [])
          .map((e) => NovelComment.from_json(Map<String, dynamic>.from(e)))
          .toList(),
      chapter_info: json['chapter_info'] != null
          ? NovelChapterInfo.from_json(
              Map<String, dynamic>.from(json['chapter_info']))
          : null,
    );
  }

  static int _parse_int(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}

/// 小说语种信息。
class NovelLanguageInfo {
  final String id;
  final String novel_id;
  final int language_id;
  final String title;
  final String introduction;
  final int word_count;
  final int chapter_count;
  final String cover_url;
  final String seo_keywords;
  final String seo_description;
  final String create_time;
  final String update_time;

  NovelLanguageInfo({
    required this.id,
    required this.novel_id,
    required this.language_id,
    required this.title,
    required this.introduction,
    required this.word_count,
    required this.chapter_count,
    required this.cover_url,
    required this.seo_keywords,
    required this.seo_description,
    required this.create_time,
    required this.update_time,
  });

  factory NovelLanguageInfo.from_json(Map<String, dynamic> json) {
    return NovelLanguageInfo(
      id: json['id']?.toString() ?? '',
      novel_id: json['novel_id']?.toString() ?? '',
      language_id: _parse_int(json['language_id']),
      title: json['title']?.toString() ?? '',
      introduction: json['introduction']?.toString() ?? '',
      word_count: _parse_int(json['word_count']),
      chapter_count: _parse_int(json['chapter_count']),
      cover_url: json['cover_url']?.toString() ?? '',
      seo_keywords: json['seo_keywords']?.toString() ?? '',
      seo_description: json['seo_description']?.toString() ?? '',
      create_time: json['create_time']?.toString() ?? '',
      update_time: json['update_time']?.toString() ?? '',
    );
  }

  static int _parse_int(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}

/// 小说评论信息。
class NovelComment {
  final String id;
  final String user_id;
  final String novel_id;
  final String comment_content;
  final int remove_status;
  final String create_time;
  final String update_time;
  final int score;
  final String name;
  final String avatar_url;

  NovelComment({
    required this.id,
    required this.user_id,
    required this.novel_id,
    required this.comment_content,
    required this.remove_status,
    required this.create_time,
    required this.update_time,
    required this.score,
    required this.name,
    required this.avatar_url,
  });

  factory NovelComment.from_json(Map<String, dynamic> json) {
    return NovelComment(
      id: json['id']?.toString() ?? '',
      user_id: json['user_id']?.toString() ?? '',
      novel_id: json['novel_id']?.toString() ?? '',
      comment_content: json['comment_content']?.toString() ?? '',
      remove_status: _parse_int(json['remove_status']),
      create_time: json['create_time']?.toString() ?? '',
      update_time: json['update_time']?.toString() ?? '',
      score: _parse_int(json['score']),
      name: json['name']?.toString() ?? '',
      avatar_url: json['avatar_url']?.toString() ?? '',
    );
  }

  static int _parse_int(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}

/// 小说章节信息。
class NovelChapterInfo {
  final String id;
  final String novel_language_id;
  final int chapter_no;
  final String title;
  final int sorting;
  final String content_url;
  final int word_count;
  final int is_vip;
  final String? publish_time;
  final String create_time;
  final String update_time;
  final int remove_status;

  NovelChapterInfo({
    required this.id,
    required this.novel_language_id,
    required this.chapter_no,
    required this.title,
    required this.sorting,
    required this.content_url,
    required this.word_count,
    required this.is_vip,
    this.publish_time,
    required this.create_time,
    required this.update_time,
    required this.remove_status,
  });

  factory NovelChapterInfo.from_json(Map<String, dynamic> json) {
    return NovelChapterInfo(
      id: json['id']?.toString() ?? '',
      novel_language_id: json['novel_language_id']?.toString() ?? '',
      chapter_no: _parse_int(json['chapter_no']),
      title: json['title']?.toString() ?? '',
      sorting: _parse_int(json['sorting']),
      content_url: json['content_url']?.toString() ?? '',
      word_count: _parse_int(json['word_count']),
      is_vip: _parse_int(json['is_vip']),
      publish_time: json['publish_time']?.toString(),
      create_time: json['create_time']?.toString() ?? '',
      update_time: json['update_time']?.toString() ?? '',
      remove_status: _parse_int(json['remove_status']),
    );
  }

  static int _parse_int(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}
