/// 故事卡片数据模型。
///
/// 统一描述短篇小说阅读页面中每张卡片所需的数据，
/// 包括详情卡片（第一张）和列表卡片（后续）。
class StoryCardData {
  /// 小说 ID。
  final int id;

  /// 小说标题。
  final String title;

  /// 小说简介（用于列表卡片的摘要展示）。
  final String description;

  /// 小说正文内容（从远程 txt 文件加载）。
  final String content;

  /// 分类标签列表。
  final List<String> tags;

  /// 阅读数。
  final int read_count;

  /// 点赞数。
  final int like_count;

  /// 评论数。
  final int comment_count;

  /// 评分。
  final String score;

  /// 是否已点赞。
  final bool is_liked;

  /// 是否为第一个卡片（详情卡片）。
  ///
  /// 详情卡片默认展开，列表卡片默认收起。
  final bool is_first;

  const StoryCardData({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.tags,
    required this.read_count,
    required this.like_count,
    required this.comment_count,
    required this.score,
    required this.is_liked,
    required this.is_first,
  });
}
