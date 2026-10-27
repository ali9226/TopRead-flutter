import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

/// 小说、短篇和漫画简介共用的卡片、文字与展开动画样式。
class ExpandableSynopsisStyle {
  const ExpandableSynopsisStyle._();
  static const double embedded_title_size_cjk = 17;
  static const double embedded_title_size_alphabetic = 17;
  static const double embedded_title_height = 1.3;
  static const double embedded_title_gap = LayoutConfig.space_12;
  static const double embedded_font_size_cjk = 15;
  static const double embedded_font_size_alphabetic = 14.5;
  static const double embedded_line_height_cjk = 1.6;
  static const double embedded_line_height_alphabetic = 1.55;
  static const double embedded_action_size_cjk = 13;
  static const double embedded_action_size_alphabetic = 12.5;
  static const double embedded_toggle_size = 18;
  static const Color embedded_text_light =
      ColorConstants.embedded_text_light_ff5f626c;
  static const Color embedded_text_dark =
      ColorConstants.components_work_about_section_style_tone_ffb7bac4;

  /// 展开按钮的最小触控范围，漫画使用透明背景保留相同点按面积。
  static const double toggle_extent = LayoutConfig.compact_control_height;
  static const double toggle_icon_size = 18;
  static const double compact_toggle_icon_size = toggle_icon_size * 2 / 3;
  static const double toggle_top_gap = LayoutConfig.space_8;

  /// 漫画标题和双箭头略向上提，透明点按范围仍保留完整高度。
  static const double compact_title_lift = LayoutConfig.space_2;
  static const double compact_title_gap = LayoutConfig.space_8;
  static const double compact_accent_width = 3;
  static const double compact_accent_height = 11;
  static const double compact_accent_gap = LayoutConfig.space_6;
  static const double compact_toggle_top_gap = LayoutConfig.space_4;
  static const double compact_toggle_icon_lift = LayoutConfig.space_6;
  static const double compact_toggle_body_overlap = LayoutConfig.space_20;
  static const Color toggle_foreground = ColorConstants.lightTextColor;
  static const Color interaction_overlay = ColorConstants.transparent;

  /// 遮罩只覆盖最后一行附近，不改变四行正文的实际布局高度。
  static const double fade_line_ratio = 1.1;

  /// 渐变上沿进入末行，与贴近正文的双箭头衔接，首行保持完整可读。
  static const double compact_fade_line_ratio = 0.65;
  static const double fade_middle_alpha = 0.12;
  static const double fade_bottom_alpha = 0.96;
  static const List<double> fade_stops = [0, 0.25, 1];
  static const double padding = LayoutConfig.space_16;
  static const double radius = LayoutConfig.radius_16;
  static const double title_gap = LayoutConfig.space_7;
  static const double action_extent = LayoutConfig.compact_control_height;
  static const double action_gap = LayoutConfig.space_4;
  static const double title_font_size_cjk = 15;
  static const double title_font_size_alphabetic = 15;
  static const double accent_width = 4;
  static const double accent_height = 16;
  static const double accent_radius = LayoutConfig.radius_2;
  static const double accent_gap = LayoutConfig.space_8;
  static const double toggle_size = 22;
  static const double font_size_cjk = 13;
  static const double font_size_alphabetic = 12.5;
  static const double line_height_cjk = 1.45;
  static const double line_height_alphabetic = 1.3;
  static const int collapsed_lines = 4;
  static const Duration expand_duration = Duration(milliseconds: 280);
  static const Duration collapse_duration = Duration(milliseconds: 240);
  static const Color accent_color =
      ColorConstants.pages_comics_detail_style_tone_ffffcf18;
  static const Color background_dark =
      ColorConstants.pages_comics_detail_style_tone_ff1a1e2e;
  static const Color background_light = ColorConstants.whiteColor;
  static const Color title_color_dark = ColorConstants.whiteColor;
  static const Color title_color_light =
      ColorConstants.pages_comics_detail_style_tone_ff1a1a2e;
  static const Color text_color_dark =
      ColorConstants.components_load_more_footer_index_tone;
  static const Color text_color_light =
      ColorConstants.pages_comics_detail_style_tone_ff777985;
}
