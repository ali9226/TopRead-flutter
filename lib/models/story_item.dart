/// 小说榜单项模型。
///
/// 用于首页榜单区域和各种书籍列表展示。
/// [category_text] 和 [heat_text] 为可选字段，
/// 有真实数据时由 [RecommendRankingItem] 映射填入，
/// 无数据时展示组件自行兜底。
class StoryItem {
  /// 唯一标识。
  final int id;

  /// 标题。
  final String title;

  /// 简介。
  final String introduction;

  /// 人气/热度描述（兼容旧的模拟数据字段）。
  final String popularity_count;

  /// 封面图地址。
  final String cover_url;

  /// 分类展示文本（如 "都市·悬疑"）。
  ///
  /// 为空时展示组件使用兜底分类文案。
  final String category_text;

  /// 热度展示文本（如 "7890万热度"）。
  ///
  /// 为空时展示组件使用 [popularity_count] 作为兜底。
  final String heat_text;

  /// 发布状态：1=连载中, 2=已完结, 3=下架, 4=短篇。
  ///
  /// 用于判断点击后跳转到普通阅读页还是短篇阅读页。
  final int publish_status;

  const StoryItem({
    required this.id,
    required this.title,
    this.introduction = '',
    required this.popularity_count,
    required this.cover_url,
    this.category_text = '',
    this.heat_text = '',
    this.publish_status = 0,
  });
}
