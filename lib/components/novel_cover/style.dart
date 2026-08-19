import 'package:flutter/material.dart';

/// 小说封面组件样式常量。
class NovelCoverStyle {
  // ========== 默认尺寸相关 ==========

  /// 外部没有传入宽度时，组件使用的默认宽度。
  static const double default_width = 96;

  /// 外部没有传入高度时，组件使用的默认高度。
  static const double default_height = 128;

  /// 外部没有传入圆角时，组件使用的默认圆角。
  static const double default_border_radius = 8;

  // ========== 骨架屏动画相关 ==========

  /// 骨架屏动画单次滑动时长（毫秒）。
  static const int skeleton_animation_duration_ms = 1200;

  /// 骨架屏高亮带的透明度停靠点。
  static const List<double> skeleton_gradient_stops = <double>[
    0.10,
    0.32,
    0.50,
    0.68,
    0.90,
  ];

  // ========== 日间主题颜色 ==========

  /// 日间主题骨架底色。
  static const Color light_skeleton_base_color = Color(0xFFE8ECF3);

  /// 日间主题骨架高亮色。
  static const Color light_skeleton_highlight_color = Color(0xFFF7F9FC);

  /// 日间主题默认兜底背景色。
  static const Color light_fallback_background_color = Color(0xFFF3F5F9);

  // ========== 夜间主题颜色 ==========

  /// 夜间主题骨架底色。
  static const Color dark_skeleton_base_color = Color(0xFF232B39);

  /// 夜间主题骨架高亮色。
  static const Color dark_skeleton_highlight_color = Color(0xFF384356);

  /// 夜间主题默认兜底背景色。
  static const Color dark_fallback_background_color = Color(0xFF1A2130);

  // ========== 默认封面背景相关 ==========

  /// 默认封面背景图基础地址。
  static const String fallback_cover_base_url =
      'http://obs.novel.obs.af-south-1.myhuaweicloud.com/novel/%E6%B5%B7%E6%8A%A5%E5%B0%81%E9%9D%A2';

  /// 默认封面背景图数量：1.png ~ 21.png。
  static const int fallback_cover_count = 21;

  /// 简介文字内边距。
  static const EdgeInsets description_padding = EdgeInsets.fromLTRB(
    12,
    12,
    12,
    12,
  );

  /// 大封面简介文字内边距。
  static const EdgeInsets large_description_padding = EdgeInsets.fromLTRB(
    15,
    16,
    15,
    16,
  );

  /// 小封面简介文字内边距。
  static const EdgeInsets compact_description_padding = EdgeInsets.fromLTRB(
    4,
    5,
    4,
    5,
  );

  /// 中等封面简介文字内边距。
  static const EdgeInsets medium_description_padding = EdgeInsets.fromLTRB(
    7,
    8,
    7,
    8,
  );

  /// 简介文字区域宽度占封面宽度的比例。
  static const double description_width_factor = 0.92;

  /// 大封面简介文字区域宽度占封面宽度的比例。
  static const double large_description_width_factor = 0.90;

  /// 小封面简介文字区域宽度占封面宽度的比例。
  static const double compact_description_width_factor = 0.96;

  /// 中等封面简介文字区域宽度占封面宽度的比例。
  static const double medium_description_width_factor = 0.94;

  /// 小封面宽度分界。
  static const double compact_cover_width = 56;

  /// 中等封面宽度分界。
  static const double medium_cover_width = 84;

  /// 大封面宽度分界。
  static const double large_cover_width = 132;

  /// 简介文字字号（CJK语言）。
  static const double description_font_size_cjk = 12;

  /// 简介文字字号（非CJK语言）。
  static const double description_font_size_alphabetic = 11;

  /// 大封面简介文字字号（CJK语言）。
  static const double large_description_font_size_cjk = 14;

  /// 大封面简介文字字号（非CJK语言）。
  static const double large_description_font_size_alphabetic = 12.6;

  /// 小封面简介文字字号（CJK语言）。
  static const double compact_description_font_size_cjk = 7.6;

  /// 小封面简介文字字号（非CJK语言）。
  static const double compact_description_font_size_alphabetic = 6.6;

  /// 中等封面简介文字字号（CJK语言）。
  static const double medium_description_font_size_cjk = 9.2;

  /// 中等封面简介文字字号（非CJK语言）。
  static const double medium_description_font_size_alphabetic = 8.2;

  /// 简介文字行高（CJK语言）。
  static const double description_line_height_cjk = 1.42;

  /// 简介文字行高（非CJK语言）。
  static const double description_line_height_alphabetic = 1.50;

  /// 大封面简介文字行高（CJK语言）。
  static const double large_description_line_height_cjk = 1.44;

  /// 大封面简介文字行高（非CJK语言）。
  static const double large_description_line_height_alphabetic = 1.52;

  /// 小封面简介文字行高（CJK语言）。
  static const double compact_description_line_height_cjk = 1.16;

  /// 小封面简介文字行高（非CJK语言）。
  static const double compact_description_line_height_alphabetic = 1.18;

  /// 中等封面简介文字行高（CJK语言）。
  static const double medium_description_line_height_cjk = 1.28;

  /// 中等封面简介文字行高（非CJK语言）。
  static const double medium_description_line_height_alphabetic = 1.34;

  /// 简介文字最大行数。
  static const int description_max_lines = 6;

  /// 大封面简介文字最大行数。
  static const int large_description_max_lines = 7;

  /// 小封面简介文字最大行数。
  static const int compact_description_max_lines = 5;

  /// 中等封面简介文字最大行数。
  static const int medium_description_max_lines = 5;

  /// 海报版式数量。
  static const int poster_variant_count = 6;

  /// 不展示遮罩层。
  static const int poster_overlay_none = 0;

  /// 深色整体渐变遮罩。
  static const int poster_overlay_dark_gradient = 1;

  /// 浅色整体渐变遮罩。
  static const int poster_overlay_light_gradient = 2;

  /// 顶部浅色遮罩。
  static const int poster_overlay_top_light = 3;

  /// 底部深色遮罩。
  static const int poster_overlay_bottom_dark = 4;

  /// 左侧浅色遮罩。
  static const int poster_overlay_left_light = 5;

  /// 深色遮罩浅透明度。
  static const double dark_overlay_low_opacity = 0.12;

  /// 深色遮罩中透明度。
  static const double dark_overlay_medium_opacity = 0.34;

  /// 深色遮罩高透明度。
  static const double dark_overlay_high_opacity = 0.52;

  /// 浅色遮罩浅透明度。
  static const double light_overlay_low_opacity = 0.10;

  /// 浅色遮罩中透明度。
  static const double light_overlay_medium_opacity = 0.34;

  /// 浅色遮罩高透明度。
  static const double light_overlay_high_opacity = 0.58;

  /// 文字颜色透明度。
  static const double description_text_opacity = 0.96;

  /// 海报深色文字。
  static const Color poster_dark_text_color = Color(0xFF182034);

  /// 海报暖色文字。
  static const Color poster_warm_text_color = Color(0xFF2A1A10);

  /// 文字阴影透明度。
  static const double text_shadow_opacity = 0.45;

  /// 浅色文字阴影透明度。
  static const double light_text_shadow_opacity = 0.70;

  /// 文字阴影向下偏移。
  static const double text_shadow_offset_y = 1;

  /// 文字阴影模糊半径。
  static const double text_shadow_blur_radius = 3;

  /// 小封面文字阴影模糊半径。
  static const double compact_text_shadow_blur_radius = 2;
}
