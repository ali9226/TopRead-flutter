import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

/// 骨架只定义占位比例和光扫材质；作品的实际布局尺寸来自对应组件样式。
class WorkDetailSkeletonStyle {
  const WorkDetailSkeletonStyle._();

  static const Duration sweep_duration = Duration(milliseconds: 1800);
  static const double radius = LayoutConfig.radius_6;
  static const double text_ink_ratio = 0.65;
  static const double title_last_line_ratio_cjk = 0.72;
  static const double title_last_line_ratio_alphabetic = 0.88;
  static const double name_width_cjk = 64;
  static const double name_width_alphabetic = 84;
  static const double follow_width_cjk = 44;
  static const double follow_width_alphabetic = 62;
  static const double heading_width_cjk = 68;
  static const double heading_width_alphabetic = 108;
  static const double short_synopsis_heading_width_cjk = 28;
  static const double short_synopsis_heading_width_alphabetic = 42;
  static const double review_action_width_cjk = 88;
  static const double review_action_width_alphabetic = 118;
  static const double value_width = 42;
  static const double label_width_cjk = 42;
  static const double label_width_alphabetic = 62;
  static const double synopsis_last_line_ratio = 0.72;
  static const double comment_last_line_ratio = 0.68;
  static const double small_gap = LayoutConfig.space_4;
  static const double comment_star_size = 10;
  static const double comment_name_width = 86;
  static const int preview_comment_count = 2;
  static const int comment_lines = 3;
  static const int synopsis_lines = 4;
  static const int title_lines = 2;
  static const int stat_count = 3;
  static const List<double> tag_widths_cjk = [46, 56, 46];
  static const List<double> tag_widths_alphabetic = [64, 82, 60];
  static const List<double> reading_line_ratios = [
    1,
    1,
    0.72,
    1,
    1,
    0.58,
    1,
    1,
    1,
    0.76,
  ];

  static const Color light_base = ColorConstants.light_base_ffe9e9e7;
  static const Color light_highlight = ColorConstants.light_highlight_fff5f5f3;
  static const Color dark_base = ColorConstants.dark_base_ff292d35;
  static const Color dark_highlight = ColorConstants.dark_highlight_ff363b44;
  static const Color hero_base =
      ColorConstants.components_back_to_top_button_style_tone_24ffffff;
  static const Color hero_highlight = ColorConstants.hero_highlight_42ffffff;
  static const List<Color> backdrop_colors = [
    ColorConstants.hero_highlight_ff393e48,
    ColorConstants.hero_highlight_ff24272e,
  ];
  static const List<double> sweep_stops = [0, 0.38, 0.5, 0.62, 1];
  static const double sweep_extent = 2.6;
}
