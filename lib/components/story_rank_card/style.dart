/// 榜单小说条目卡片样式常量。
class StoryRankCardStyle {
  /// 封面宽度。
  static const double ranking_cover_width = 54;

  /// 封面高度。
  static const double ranking_cover_height = 64;

  /// 封面圆角。
  static const double ranking_cover_radius = 8;

  /// 封面与内容间距。
  static const double ranking_cover_to_content_gap = 5;

  /// 序号与内容间距。
  static const double ranking_index_to_content_gap = 5;

  /// 序号顶部边距。
  static const double ranking_index_top_spacing = 1;

  /// 序号字号。
  static const double ranking_index_font_size = 13;

  /// 标题字号。
  static const double ranking_title_font_size = 14;

  /// 标题行高。
  static const double ranking_title_height = 1.45;

  /// 人气字号。
  static const double ranking_popularity_font_size = 12;

  /// 人气区域高度。
  static const double ranking_popularity_height = 16;

  /// 标题容器高度。
  static const double ranking_title_container_height =
      ranking_cover_height - ranking_popularity_height;
}
