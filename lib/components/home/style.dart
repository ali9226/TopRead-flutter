import 'package:flutter/material.dart';
import 'package:app/config/layout_config.dart';

/// 首页样式常量。
class Style {
  /// 顶部工具栏高度。
  static const double top_toolbar_height = 58;

  /// 首页整体上下边距。
  static const double page_top_padding = 6;
  static const double page_bottom_padding = 28;

  /// 通过全局横向间距统一构建首页内容边距。
  static const EdgeInsets page_padding = EdgeInsets.fromLTRB(
    LayoutConfig.page_horizontal_padding,
    page_top_padding,
    LayoutConfig.page_horizontal_padding,
    page_bottom_padding,
  );

  /// 非吸顶头部到轮播图间距。
  static const double non_pinned_header_to_banner_gap = 8;

  /// 顶部渐变遮罩参数。
  static const double header_gradient_start_opacity = 0.90;
  static const double header_gradient_middle_opacity = 0.34;
  static const double header_gradient_height = 96;

  /// 顶部装饰光斑参数。
  static const double top_glow_one_top = -34;
  static const double top_glow_one_right = -22;
  static const double top_glow_one_size = 196;
  static const double top_glow_one_light_opacity = 0.10;
  static const double top_glow_one_dark_opacity = 0.08;

  static const double top_glow_two_top = 170;
  static const double top_glow_two_left = -46;
  static const double top_glow_two_size = 170;
  static const double top_glow_two_light_opacity = 0.06;
  static const double top_glow_two_dark_opacity = 0.05;

  /// 搜索框与区块间距。
  static const double search_entry_top_gap = 14;
  static const double section_gap = 18;

  /// 顶部搜索条高度。
  static const double top_search_entry_height = 38;

  /// 顶部搜索条圆角。
  static const double top_search_entry_radius = 20;

  /// 顶部搜索条内边距。
  static const EdgeInsets top_search_entry_padding = EdgeInsets.fromLTRB(
    14,
    0,
    14,
    0,
  );

  /// 顶部搜索条图标大小。
  static const double top_search_entry_icon_size = 18;

  /// 顶部搜索条图标与文字间距。
  static const double top_search_entry_gap = 5;

  /// 顶部搜索条提示文字字号。
  static const double top_search_entry_font_size = 13;

  /// 顶部搜索条最大宽度。
  static const double top_search_entry_max_width = 238;

  /// 首页搜索入口尺寸。
  static const double search_entry_height = 52;
  static const double search_entry_radius = 26;
  static const double search_entry_icon_size = 22;
  static const double search_entry_hint_font_size = 14;
  static const double search_entry_hint_font_weight = 700;
  static const double search_entry_blur_radius = 20;
  static const double search_entry_border_width = 1.2;
  static const EdgeInsets search_entry_padding = EdgeInsets.fromLTRB(
    18,
    0,
    18,
    0,
  );
  static const EdgeInsets search_entry_icon_holder_padding = EdgeInsets.all(7);
  static const double search_entry_icon_holder_radius = 14;
  static const double search_entry_icon_text_gap = 10;
  static const double search_entry_suffix_font_size = 12;
  static const EdgeInsets search_entry_suffix_padding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  );
  static const double search_entry_suffix_radius = 999;

  /// 轮播图样式参数。
  static const double banner_height = 206;
  static const double banner_radius = 26;
  static const EdgeInsets banner_padding = EdgeInsets.fromLTRB(20, 20, 20, 20);
  static const double banner_badge_font_size = 12;
  static const double banner_badge_horizontal_padding = 10;
  static const double banner_badge_vertical_padding = 6;
  static const double banner_badge_radius = 999;
  static const double banner_title_font_size = 26;
  static const double banner_title_height = 1.08;
  static const double banner_subtitle_font_size = 13;
  static const double banner_subtitle_height = 1.35;
  static const double banner_highlight_font_size = 13;
  static const double banner_highlight_horizontal_padding = 14;
  static const double banner_highlight_vertical_padding = 8;
  static const double banner_highlight_radius = 18;
  static const double banner_decoration_circle_size = 144;
  static const double banner_decoration_circle_top = -30;
  static const double banner_decoration_circle_right = -22;
  static const double banner_title_top_spacing = 8;
  static const double banner_highlight_top_spacing = 14;

  /// 首页轮播图骨架屏样式参数。
  static const int banner_skeleton_animation_duration_ms = 1200;
  static const Alignment banner_skeleton_gradient_begin = Alignment(-1.6, -0.3);
  static const Alignment banner_skeleton_gradient_end = Alignment(1.6, 0.3);
  static const List<double> banner_skeleton_gradient_stops = <double>[
    0.10,
    0.32,
    0.50,
    0.68,
    0.90,
  ];
  static const Color banner_skeleton_light_base_color = Color(0xFFE9EDF4);
  static const Color banner_skeleton_light_highlight_color = Color(0xFFF8FAFD);
  static const Color banner_skeleton_dark_base_color = Color(0xFF222A39);
  static const Color banner_skeleton_dark_highlight_color = Color(0xFF374255);
  static const double banner_skeleton_badge_width = 64;
  static const double banner_skeleton_badge_height = 24;
  static const double banner_skeleton_badge_radius = 999;
  static const double banner_skeleton_title_width = 146;
  static const double banner_skeleton_title_height = 28;
  static const double banner_skeleton_subtitle_width = 188;
  static const double banner_skeleton_subtitle_height = 14;
  static const double banner_skeleton_highlight_width = 112;
  static const double banner_skeleton_highlight_height = 34;
  static const double banner_skeleton_line_radius = 999;

  /// Tab 区块样式参数。
  static const double tab_container_radius = 24;
  static const double tab_decoration_glow_one_top = -26;
  static const double tab_decoration_glow_one_left = -20;
  static const double tab_decoration_glow_one_size = 108;
  static const double tab_decoration_glow_two_top = 154;
  static const double tab_decoration_glow_two_right = -34;
  static const double tab_decoration_glow_two_size = 124;
  static const double tab_decoration_ring_top = 18;
  static const double tab_decoration_ring_right = 18;
  static const double tab_decoration_ring_size = 86;
  static const double tab_decoration_capsule_bottom = 28;
  static const double tab_decoration_capsule_left = 18;
  static const double tab_decoration_capsule_width = 68;
  static const double tab_decoration_capsule_height = 16;
  static const double tab_bar_radius = 16;
  static const double tab_bar_height = 44;
  static const double tab_view_height = 430;
  static const EdgeInsets tab_bar_margin = EdgeInsets.fromLTRB(10, 10, 10, 6);
  static const double tab_bar_left_block_width = 10;
  static const double tab_bar_left_spacing = 10;
  static const double tab_bar_trailing_spacing = 28;
  static const EdgeInsets tab_label_padding = EdgeInsets.zero;
  static const double tab_label_horizontal_margin = 5;
  static const double tab_label_font_size = 13;
  static const double tab_selected_font_scale = 1.33;
  static const double tab_selected_font_size =
      tab_label_font_size * tab_selected_font_scale;
  static const int tab_animation_duration_ms = 220;
  static const double tab_indicator_height = 3;
  static const EdgeInsets tab_indicator_padding = EdgeInsets.symmetric(
    horizontal: 8,
  );
  static const double tab_indicator_bottom_offset = 3;

  /// 右侧“更多”区域样式参数。
  static const double tab_more_gradient_width = 20;
  static const double tab_more_right_radius = tab_container_radius;
  static const double tab_more_text_left_spacing = 0;
  static const double tab_more_icon_size = 12;
  static const double tab_more_content_gap = 4;
  static const EdgeInsets tab_more_button_padding = EdgeInsets.symmetric(
    horizontal: 10,
  );
  static const EdgeInsets tab_more_text_button_padding = EdgeInsets.symmetric(
    horizontal: 2,
  );
  static const double tab_more_font_size = tab_label_font_size;

  /// 榜单整体骨架屏样式参数。
  static const double ranking_skeleton_tab_height = 16;
  static const double ranking_skeleton_tab_radius = 999;
  static const double ranking_skeleton_tab_width = 52;
  static const double ranking_skeleton_tab_active_width = 64;
  static const double ranking_skeleton_tab_gap = 12;
  static const double ranking_skeleton_more_width = 44;
  static const double ranking_skeleton_more_height = 16;
  static const double ranking_skeleton_more_right_spacing = 12;
  static const double ranking_skeleton_cover_gap = 5;
  static const double ranking_skeleton_line_radius = 999;
  static const double ranking_skeleton_title_line_width = 88;
  static const double ranking_skeleton_subtitle_line_width = 64;
  static const double ranking_skeleton_title_line_height = 12;
  static const double ranking_skeleton_subtitle_line_height = 10;
  static const double ranking_skeleton_text_top_spacing = 8;
  static const double ranking_skeleton_text_line_gap = 8;
  static const double ranking_skeleton_more_line_width = 76;
  static const double ranking_skeleton_more_line_height = 14;
  static const int ranking_skeleton_animation_duration_ms = 1200;
  static const List<double> ranking_skeleton_gradient_stops = <double>[
    0.10,
    0.32,
    0.50,
    0.68,
    0.90,
  ];
  static const Color ranking_skeleton_light_base_color = Color(0xFFE9EDF4);
  static const Color ranking_skeleton_light_highlight_color = Color(0xFFF8FAFD);
  static const Color ranking_skeleton_dark_base_color = Color(0xFF222A39);
  static const Color ranking_skeleton_dark_highlight_color = Color(0xFF374255);

  /// 榜单宫格区域内边距。
  static const EdgeInsets story_list_padding = EdgeInsets.fromLTRB(
    10,
    20,
    10,
    0,
  );

  /// 榜单宫格布局参数。
  static const int ranking_cross_axis_count = 2;
  static const int ranking_row_count = 4;
  static const double ranking_column_spacing = 10;
  static const double ranking_row_spacing = 7;
  static const double ranking_item_height = 80;
  static const double ranking_cover_width = 54;
  static const double ranking_cover_height = 64;
  static const double ranking_cover_radius = LayoutConfig.tag_radius;
  static const double ranking_cover_to_content_gap = 5;
  static const double ranking_index_to_content_gap = 5;
  static const double ranking_index_top_spacing = 1;
  static const double ranking_index_font_size = 13;
  static const double ranking_title_font_size = 14;
  static const double ranking_title_height = 1.45;
  static const double ranking_popularity_font_size = 12;
  static const double ranking_popularity_height = 16;
  static const double ranking_title_container_height =
      ranking_cover_height - ranking_popularity_height;
  static const double ranking_grid_height =
      ranking_item_height * ranking_row_count +
      ranking_row_spacing * (ranking_row_count - 1);
  static const double ranking_more_top_spacing = 15;
  static const double ranking_more_font_size = 13;
  static const double ranking_more_icon_size = 12;
  static const double ranking_more_icon_gap = 4;
  static const double ranking_more_underline_gap = 2;
  static const double ranking_more_bottom_spacing = 20;
  static const double ranking_more_opacity = 0.4;

  /// 返回顶部按钮显示阈值。
  static const double back_to_top_show_threshold = 120;

  /// ========== 新版首页布局参数 ==========

  /// 搜索栏与分类标签栏之间的间距。
  static const double search_to_category_gap = 4;

  /// 分类标签栏与榜单区域之间的间距。
  static const double category_to_ranking_gap = 8;

  /// 榜单区域与书籍推荐列表之间的间距。
  static const double ranking_to_book_list_gap = 12;

  /// 榜单网格列间距。
  static const double ranking_grid_column_spacing = 10;

  /// 榜单网格行间距。
  static const double ranking_grid_row_spacing = 0;
}
