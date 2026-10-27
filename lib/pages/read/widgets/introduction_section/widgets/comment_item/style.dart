import 'package:app/config/layout_config.dart';
import 'package:app/config/color_config.dart';
import 'package:flutter/material.dart';

/// 书评作者与正文分行排版，正文始终使用整行阅读宽度。
class CommentItemStyle {
  const CommentItemStyle._();
  static const double vertical_padding = LayoutConfig.space_20;
  static const double avatar_size = 36;
  static const double avatar_initial_size = 15;
  static const double avatar_fallback_icon_size = 18;
  static const double avatar_content_spacing = LayoutConfig.space_10;
  static const double name_font_size_cjk = 13;
  static const double name_font_size_alphabetic = 12.5;
  static const double name_line_height_cjk = 1.4;
  static const double name_line_height_alphabetic = 1.4;
  static const int name_max_lines = 2;
  static const double rating_top_gap = LayoutConfig.space_4;
  static const int rating_max = 5;
  static const double star_size = 10;
  static const double star_spacing = LayoutConfig.space_2;
  static const double body_top_gap = LayoutConfig.space_12;
  static const double text_font_size_cjk = 15;
  static const double text_font_size_alphabetic = 14.5;
  static const double text_line_height_cjk = 1.65;
  static const double text_line_height_alphabetic = 1.6;
  static const int collapsed_lines = 4;
  static const double toggle_extent = 40;
  static const double toggle_size_cjk = 12.5;
  static const double toggle_size_alphabetic = 12.5;
  static const double toggle_icon_size = LayoutConfig.icon_small;
  static const double toggle_icon_gap = LayoutConfig.space_3;
  static const double toggle_radius = LayoutConfig.radius_8;
  static const Duration toggle_duration = Duration(milliseconds: 220);
  static Color name_color(bool dark) => dark
      ? ColorConstants
            .pages_read_widgets_introduction_section_widgets_comment_item_style_tone
      : ColorConstants
            .pages_read_widgets_introduction_section_widgets_comment_item_style_tone_ff646773;
  static Color text_color(bool dark) => dark
      ? ColorConstants
            .pages_read_widgets_introduction_section_widgets_comment_item_style_tone_ffe1e2e9
      : ColorConstants.lightTextColor;
  static Color rating_color(bool dark) => ColorConstants.dangerColor;
  static Color empty_star_color(bool dark) => dark
      ? ColorConstants
            .pages_read_widgets_introduction_section_widgets_comment_item_style_tone_ff414352
      : ColorConstants
            .pages_read_widgets_introduction_section_widgets_comment_item_style_tone_ffdadbe2;
  static Color avatar_background(bool dark) => dark
      ? ColorConstants
            .pages_read_widgets_introduction_section_widgets_comment_item_style_tone_ff2b2930
      : ColorConstants
            .pages_read_widgets_introduction_section_widgets_comment_item_style_tone_fff3f0e8;
  static Color avatar_initial_color(bool dark) => dark
      ? ColorConstants
            .pages_read_widgets_introduction_section_widgets_comment_item_style_tone_ffe4d5aa
      : ColorConstants
            .pages_read_widgets_introduction_section_widgets_comment_item_style_tone_ff77643c;
}
