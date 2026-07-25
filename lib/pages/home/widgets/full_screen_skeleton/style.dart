import 'package:flutter/material.dart';
import 'package:app/config/layout_config.dart';

/// 首页全屏骨架屏样式常量。
///
/// 当首页分类数据正在加载时，展示全屏骨架屏，
/// 模拟首页完整的布局结构（头部、Tab栏、内容区域），
/// 让用户在数据加载期间看到页面整体框架，减少等待焦虑。
class FullScreenSkeletonStyle {
  /// 骨架屏动画时长。
  static const Duration animation_duration = Duration(milliseconds: 1500);

  /// Tab栏骨架高度（与真实 HomeTabBar 一致）。
  static const double tab_bar_height = 41.0;

  /// Tab栏骨架顶部偏移（与真实首页保持一致）。
  static const double tab_bar_top_offset = -5.0;

  /// Tab栏骨架项数量。
  static const int tab_item_count = 6;

  /// Tab栏骨架项间距（与真实 HomeTabBar 的 labelPadding 一致）。
  static const double tab_item_spacing = 24.0;

  /// Tab栏骨架项高度（与真实 Tab 文字行高一致）。
  static const double tab_item_height = 20.0;

  /// Tab栏骨架项圆角。
  static const double tab_item_radius = 6.0;

  /// Tab栏骨架项宽度列表（模拟不同标题长度）。
  static const List<double> tab_item_width_list = <double>[
    36.0,
    48.0,
    44.0,
    52.0,
    40.0,
    56.0,
  ];

  /// 内容区域左右内边距（与推荐页面的 ranking_margin 一致）。
  static const double content_horizontal_padding = 12.0;

  /// 榜单区域高度（与推荐页面的榜单区域一致）。
  /// tab_bar(56) + list_padding_top(5) + item_height(71) * 4 = 345
  static const double ranking_section_height = 345.0;

  /// 榜单区域圆角（与 LayoutConfig.card_radius 一致）。
  static const double ranking_section_radius = LayoutConfig.card_radius;

  /// 榜单 Tab 栏骨架高度（与 RankingSectionStyle.tab_bar_height 一致）。
  /// 20顶部间距 + 20骨架条高度 = 40
  static const double ranking_tab_bar_height = 40.0;

  /// 榜单列表项高度（与 RankingSectionStyle.item_height 一致）。
  static const double ranking_item_height = 71.0;

  /// 榜单列表项间距（与 RankingSectionStyle.row_gap 一致）。
  static const double ranking_item_spacing = 0.0;

  /// 榜单列表行数（与 RankingSectionStyle.rows_per_column 一致）。
  static const int ranking_row_count = 4;

  /// 榜单与推荐区域间距（与 RecommendTabStyle.recommend_top_spacing 一致）。
  static const double section_spacing = 10.0;

  /// 推荐卡片高度（模拟不同高度的瀑布流卡片）。
  static const List<double> card_height_list = <double>[
    200.0,
    240.0,
    180.0,
    220.0,
    190.0,
    230.0,
  ];

  /// 推荐卡片圆角（与 LayoutConfig.card_radius 一致）。
  static const double card_radius = LayoutConfig.card_radius;

  /// 推荐卡片间距（与 RecommendTabStyle.card_spacing 一致）。
  static const double card_spacing = 12.0;

  /// 推荐卡片标题骨架高度。
  static const double card_title_height = 14.0;

  /// 推荐卡片标题骨架圆角。
  static const double card_title_radius = 4.0;

  /// 推荐卡片副标题骨架高度。
  static const double card_subtitle_height = 10.0;

  /// 推荐卡片副标题骨架圆角。
  static const double card_subtitle_radius = 3.0;

  /// 推荐卡片底部内边距。
  static const double card_bottom_padding = 8.0;

  /// 骨架屏浅色模式底色。
  static const Color light_base_color = Color(0xFFEEEEEE);

  /// 骨架屏浅色模式高亮色。
  static const Color light_highlight_color = Color(0xFFF5F5F5);

  /// 骨架屏深色模式底色。
  static const Color dark_base_color = Color(0xFF2A2A2A);

  /// 骨架屏深色模式高亮色。
  static const Color dark_highlight_color = Color(0xFF3A3A3A);

  /// 骨架屏浅色模式背景色。
  static const Color light_background_color = Color(0xFFF6F7FB);

  /// 骨架屏深色模式背景色。
  static const Color dark_background_color = Color(0xFF0D1117);

  /// 骨架屏浅色模式面板背景色。
  static const Color light_panel_color = Colors.white;

  /// 骨架屏深色模式面板背景色。
  static const Color dark_panel_color = Color(0xFF171C28);

  /// 骨架屏渐变 stops。
  static const List<double> gradient_stops = <double>[
    0.0,
    0.35,
    0.5,
    0.65,
    1.0,
  ];
}
