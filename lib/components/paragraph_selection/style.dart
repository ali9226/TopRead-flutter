// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';

/// 段落选区、操作菜单和段评数量气泡的统一样式。
class ParagraphSelectionStyle {
  const ParagraphSelectionStyle._();

  static const double menu_font_size_cjk = 12;
  static const double menu_font_size_alphabetic = 11;
  static const double menu_min_width_cjk = 66;
  static const double menu_min_width_alphabetic = 92;
  static const double menu_line_height_cjk = 1.3;
  static const double menu_line_height_alphabetic = 1.4;
  static const double menu_icon_size = 22;
  static const double menu_icon_spacing = 5;
  static const double menu_vertical_padding = 10;
  static const double menu_horizontal_padding = 12;
  static const double menu_radius = 10;
  static const double menu_elevation = 5;
  static const double menu_screen_margin = 10;
  static const double menu_anchor_gap = 8;
  static const double menu_arrow_width = 12;
  static const double menu_arrow_height = 6;

  static const double badge_font_size_cjk = 10;
  static const double badge_font_size_alphabetic = 10;
  static const double badge_line_height_cjk = 1.1;
  static const double badge_line_height_alphabetic = 1.2;
  static const double badge_min_width = 24;
  static const double badge_height = 20;
  static const double badge_horizontal_padding = 6;
  static const double badge_gap = 6;
  static const double badge_radius = 6;
  static const double badge_tail_size = 4;
  static const double badge_border_width = 1;
  static const double selection_opacity = 0.35;
  static const double drag_reveal_padding = 48;

  static Color menu_background(bool is_dark) =>
      is_dark ? ColorConstants.lightTextColor : ColorConstants.whiteColor;

  static Color menu_foreground(bool is_dark) => is_dark
      ? ColorConstants.lightBackgroundColor
      : ColorConstants.lightTextColor;

  static Color badge_color(bool is_dark) =>
      is_dark ? ColorConstants.nightTextColor : ColorConstants.hintColor;

  /// 数字排版与布局测量共用同一个样式，避免字号设置改变后气泡越界。
  static TextStyle badge_text_style({
    required bool is_dark,
    required bool is_cjk,
  }) => TextStyle(
    color: badge_color(is_dark),
    fontSize: is_cjk ? badge_font_size_cjk : badge_font_size_alphabetic,
    height: is_cjk ? badge_line_height_cjk : badge_line_height_alphabetic,
    fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
  );
}
