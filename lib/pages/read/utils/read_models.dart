/// 阅读页详情数据模型。
class ReadDetail {
  /// 书籍 id。
  final int story_id;

  /// 书籍标题。
  final String title;

  /// 封面地址。
  final String cover_url;

  /// 作者ID（数据库中的真实作者ID，用于关注接口）。
  final int author_id;

  /// 作者头像地址。
  final String author_avatar_url;

  /// 作者名称。
  final String author_name;

  /// 是否关注作者。
  final bool focus_on;

  /// 评分整数部分。
  final String score_major_text;

  /// 评分单位文案。
  final String score_minor_text;

  /// 点评人数文案。
  final String review_count_text;

  /// 在读人数整数部分。
  final String reading_major_text;

  /// 在读人数单位文案。
  final String reading_minor_text;

  /// 在读副标题文案。
  final String reading_subtitle_text;

  /// 字数整数部分。
  final String word_count_major_text;

  /// 字数单位文案。
  final String word_count_minor_text;

  /// 字数副标题文案。
  final String word_count_subtitle_text;

  /// 标签列表。
  final List<String> tag_list;

  /// 简介内容。
  final String intro_text;

  /// 第一章标题。
  final String chapter_title;

  /// 热门评论列表。
  final List<ReadComment> comment_list;

  const ReadDetail({
    required this.story_id,
    required this.title,
    required this.cover_url,
    required this.author_id,
    required this.author_avatar_url,
    required this.author_name,
    required this.focus_on,
    required this.score_major_text,
    required this.score_minor_text,
    required this.review_count_text,
    required this.reading_major_text,
    required this.reading_minor_text,
    required this.reading_subtitle_text,
    required this.word_count_major_text,
    required this.word_count_minor_text,
    required this.word_count_subtitle_text,
    required this.tag_list,
    required this.intro_text,
    required this.chapter_title,
    required this.comment_list,
  });
}

/// 阅读页评论数据模型。
class ReadComment {
  /// 评论人头像地址。
  final String avatar_url;

  /// 评论人名称。
  final String user_name;

  /// 评论内容。
  final String content;

  /// 评论星级。
  final int star_count;

  /// 评论人用户ID，用于 CommentAvatar 生成 SVG 兜底头像。
  final int user_id;

  const ReadComment({
    required this.avatar_url,
    required this.user_name,
    required this.content,
    required this.star_count,
    required this.user_id,
  });
}
