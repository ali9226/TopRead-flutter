import 'package:app/config/layout_config.dart';
import 'package:app/config/color_config.dart';
import 'package:flutter/material.dart';

/// 书评延续简介的纸面，以留白和细线区分层级，避免多重卡片阴影。
class CommentStyle {
  const CommentStyle._();
  static const double rule_width = .5;
  static const double heading_top_gap = LayoutConfig.space_24;
  static const double heading_bottom_gap = LayoutConfig.space_8;
  static const double heading_size_cjk = 20;
  static const double heading_size_alphabetic = 22;
  static const double heading_height_cjk = 1.35;
  static const double heading_height_alphabetic = 1.3;
  static const double count_gap = LayoutConfig.space_8;
  static const double count_size_cjk = 12;
  static const double count_size_alphabetic = 12;
  static const double header_action_gap = LayoutConfig.space_12;
  static const double action_extent = LayoutConfig.compact_control_height;
  static const double action_radius = LayoutConfig.radius_12;
  static const double action_padding = LayoutConfig.space_10;
  static const double action_size_cjk = 13;
  static const double action_size_alphabetic = 12.5;
  static const double action_icon_size = LayoutConfig.icon_small;
  static const double action_icon_gap = LayoutConfig.space_2;
  static const int preview_limit = 3;
  static const double empty_padding = LayoutConfig.space_24;
  static const double empty_icon_extent = 44;
  static const double empty_icon_size = LayoutConfig.icon_compact;
  static const double empty_gap = LayoutConfig.space_12;
  static const double empty_text_size_cjk = 14;
  static const double empty_text_size_alphabetic = 14;
  static const double empty_text_height_cjk = 1.65;
  static const double empty_text_height_alphabetic = 1.6;
  static Color ink(bool dark) =>
      dark ? ColorConstants.pages_read_widgets_introduction_section_widgets_comment_section_style_tone : ColorConstants.lightTextColor;
  static Color muted(bool dark) =>
      dark ? ColorConstants.pages_read_widgets_introduction_section_widgets_comment_section_style_tone_ffa5a7b7 : ColorConstants.pages_comics_detail_style_tone_ff777985;
  static Color rule(bool dark) =>
      dark ? ColorConstants.pages_read_widgets_introduction_section_widgets_comment_section_style_tone_ff2b2c3a : ColorConstants.pages_read_widgets_introduction_section_widgets_comment_section_style_tone_ffe9e9ee;
  static Color soft_surface(bool dark) =>
      dark ? ColorConstants.pages_read_widgets_introduction_section_widgets_comment_section_style_tone_ff1b1c29 : ColorConstants.components_work_hero_stats_style_tone_fff6f6f8;
}
