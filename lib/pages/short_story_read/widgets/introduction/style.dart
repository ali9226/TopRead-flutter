// ignore_for_file: constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';

/// 短篇简介只定义业务元数据；海报、封面比例和完整标题由共享组件管理。
class ShortStoryIntroductionStyle {
  static const double author_font_cjk = 14;
  static const double author_font_alphabetic = 13;
  static const double line_height_cjk = 1.4;
  static const double line_height_alphabetic = 1.5;
  static const Color backdrop_placeholder =
      ColorConstants.backdrop_placeholder_dark;
  static const int synopsis_collapsed_lines = 2;
  static const double synopsis_padding_h = LayoutConfig.space_16;
  static const double synopsis_padding_v = LayoutConfig.space_12;
  static const double synopsis_heading_gap = LayoutConfig.space_2;
  static const double synopsis_title_size_cjk = 12;
  static const double synopsis_title_size_alphabetic = 12;
  static const double synopsis_title_height = 1.3;
  static const double synopsis_size_cjk = 14;
  static const double synopsis_size_alphabetic = 13.5;
  static const double synopsis_height_cjk = 1.6;
  static const double synopsis_height_alphabetic = 1.55;
  static const double synopsis_fade_line_ratio = 0.35;
  static const Color synopsis_foreground = ColorConstants.whiteColor;
  static const Color synopsis_heading =
      ColorConstants.components_load_more_footer_index_tone_bfffffff;

  static Color foreground(bool is_dark, bool on_hero) => on_hero
      ? ColorConstants.whiteColor
      : is_dark
      ? ColorConstants.whiteColor
      : ColorConstants.lightTextColor;
}
