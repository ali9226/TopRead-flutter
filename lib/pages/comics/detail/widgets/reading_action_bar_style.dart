// ignore_for_file: constant_identifier_names

import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

/// TODO 章节目录底部操作条的尺寸和颜色；安全区与定位由详情页负责。
class ComicReadingActionBarStyle {
  const ComicReadingActionBarStyle._();

  static const double radius = LayoutConfig.radius_40;
  static const double padding = LayoutConfig.space_6;
  static const double button_min_height = 50;
  static const double library_fraction = 0.38;
  static const double compact_width = 360;
  static const double book_icon_min_width = 390;
  static const double icon_size = LayoutConfig.icon_regular;
  static const double arrow_size = 30;
  static const double divider_height = 22;
  static const double gap = LayoutConfig.space_8;
  static const double button_padding_h = LayoutConfig.space_12;
  static const double button_padding_v = LayoutConfig.space_9;
  static const double font_size_cjk = 13;
  static const double font_size_alphabetic = 12.5;
  static const double compact_font_size_cjk = 12;
  static const double compact_font_size_alphabetic = 11.5;
  static const double chapter_font_size_cjk = 10;
  static const double chapter_font_size_alphabetic = 10;
  static const double text_height_cjk = 1.25;
  static const double text_height_alphabetic = 1.3;
  static const Duration transition = Duration(milliseconds: 180);
  static const Color ink = ColorConstants.night_sheet_gradient_start;
  static const Color arrow_background = ColorConstants.arrow_background_ff6f5003;
  static const Color night_surface = ColorConstants.night_surface_ff242630;
  static const List<Color> gradient = [
    ColorConstants.night_surface_fffff295,
    ColorConstants.night_surface_ffffdb27,
    ColorConstants.night_surface_ffffbc32,
  ];
}
