import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';
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
  static const double tab_item_radius = LayoutConfig.radius_6;

  /// 相邻 Tab 骨架错开的动画进度。
  static const double tab_item_animation_delay = 0.1;

  /// Tab栏骨架项宽度列表（模拟不同标题长度）。
  static const List<double> tab_item_width_list = <double>[
    36.0,
    48.0,
    44.0,
    52.0,
    40.0,
    56.0,
  ];

  /// 骨架屏浅色模式底色。
  static const Color light_base_color = ColorConstants.components_reader_top_bar_style_tone_ffeeeeee;

  /// 骨架屏浅色模式高亮色。
  static const Color light_highlight_color = ColorConstants.config_color_config_tone_fff5f5f5;

  /// 骨架屏深色模式底色。
  static const Color dark_base_color = ColorConstants.components_cute_mascot_index_tone_ff2a2a2a;

  /// 骨架屏深色模式高亮色。
  static const Color dark_highlight_color = ColorConstants.components_cute_mascot_index_tone_ff3a3a3a;

  /// 骨架屏浅色模式背景色。
  static const Color light_background_color = ColorConstants.components_category_filter_category_filter_bar_tone_fff6f7fb;

  /// 骨架屏深色模式背景色。
  static const Color dark_background_color = ColorConstants.test_components_fullbleed_surfaces_test_tone;

  /// 骨架屏浅色模式面板背景色。
  static const Color light_panel_color = ColorConstants.whiteColor;

  /// 骨架屏深色模式面板背景色。
  static const Color dark_panel_color = ColorConstants.pages_home_widgets_tab_contents_recommend_tab_index_tone;
}
