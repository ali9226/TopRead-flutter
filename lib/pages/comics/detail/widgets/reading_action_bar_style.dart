// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

/// TODO 章节目录底部操作条的尺寸和颜色；安全区与定位由详情页负责。
class ComicReadingActionBarStyle {
  const ComicReadingActionBarStyle._();

  static const double radius = 40;
  static const double padding = 6;
  static const double button_min_height = 50;
  static const double library_fraction = 0.38;
  static const double compact_width = 360;
  static const double book_icon_min_width = 390;
  static const double icon_size = 24;
  static const double arrow_size = 30;
  static const double divider_height = 22;
  static const double gap = 8;
  static const double button_padding_h = 12;
  static const double button_padding_v = 9;
  static const double font_size_cjk = 13;
  static const double font_size_alphabetic = 12.5;
  static const double compact_font_size_cjk = 12;
  static const double compact_font_size_alphabetic = 11.5;
  static const double chapter_font_size_cjk = 10;
  static const double chapter_font_size_alphabetic = 10;
  static const double text_height_cjk = 1.25;
  static const double text_height_alphabetic = 1.3;
  static const Duration transition = Duration(milliseconds: 180);
  static const Color ink = Color(0xFF171B28);
  static const Color arrow_background = Color(0xFF6F5003);
  static const Color night_surface = Color(0xFF242630);
  static const List<Color> gradient = [
    Color(0xFFFFF295),
    Color(0xFFFFDB27),
    Color(0xFFFFBC32),
  ];
}
