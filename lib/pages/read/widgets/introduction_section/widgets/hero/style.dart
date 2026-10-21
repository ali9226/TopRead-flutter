// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

/// TODO 小说简介海报与漫画简介采用一致的封面比例、暖金色与底部深色渐变。
class ReadIntroductionHeroStyle {
  const ReadIntroductionHeroStyle._();
  static const double max_content_width = 600;
  static const double cover_width_ratio = 0.313;
  static const double cover_max_width = 160;
  static const double cover_aspect_ratio = 1.49;
  static const double cover_radius = 12;
  static const double horizontal_inset_ratio = 0.049;
  static const double content_gap = 14;
  static const double content_bottom = 16;
  static const double backdrop_height_ratio = 0.34;
  static const double backdrop_max_height = 180;
  static const double nav_size = 44;
  static const double nav_visual_inset = 5;
  static const double nav_icon_size = 23;
  static const double nav_inset = 12;
  static const double nav_top = 8;
  static const double nav_content_gap = 16;
  static const double title_size_cjk = 23;
  static const double title_size_alphabetic = 25.5;
  static const double title_height_cjk = 1.2;
  static const double title_height_alphabetic = 1.08;
  static const double title_author_gap = 8;
  static const double author_stats_gap = 12;
  static const double scale_base_width = 430;
  static const double min_scale = 0.8;
  static const List<Color> scrim_colors = [
    Color(0x1A000000),
    Color(0x00000000),
    Color(0x00000000),
    Color(0xB3242428),
    Color(0xFF29292C),
  ];
  static const List<double> scrim_stops = [0, 0.12, 0.38, 0.64, 1];
  static const List<BoxShadow> cover_shadow = [
    BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const double action_radius = 26;
  static const double action_height = 44;
  static const double action_padding = 10;
  static const double action_vertical_padding = 8;
  static const double action_gap = 8;
  static const double action_icon = 20;
  static const double action_font_size = 12;
  static const double action_text_height = 1.2;
  static const List<Color> action_gradient = [
    Color(0xFFFFF38B),
    Color(0xFFFFDC20),
    Color(0xFFFFBA23),
  ];
}
