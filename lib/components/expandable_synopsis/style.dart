import 'package:flutter/material.dart';

/// 小说、短篇和漫画简介共用的卡片、文字与展开动画样式。
class ExpandableSynopsisStyle {
  const ExpandableSynopsisStyle._();
  static const double padding = 16;
  static const double radius = 16;
  static const double title_gap = 7;
  static const double action_extent = 44;
  static const double action_gap = 4;
  static const double title_font_size_cjk = 15;
  static const double title_font_size_alphabetic = 15;
  static const double accent_width = 4;
  static const double accent_height = 16;
  static const double accent_radius = 2;
  static const double accent_gap = 8;
  static const double toggle_size = 22;
  static const double font_size_cjk = 13;
  static const double font_size_alphabetic = 12.5;
  static const double line_height_cjk = 1.45;
  static const double line_height_alphabetic = 1.3;
  static const int collapsed_lines = 4;
  static const Duration expand_duration = Duration(milliseconds: 280);
  static const Duration collapse_duration = Duration(milliseconds: 240);
  static const Color accent_color = Color(0xFFFFCF18);
  static const Color background_dark = Color(0xFF1A1E2E);
  static const Color background_light = Colors.white;
  static const Color title_color_dark = Colors.white;
  static const Color title_color_light = Color(0xFF1A1A2E);
  static const Color text_color_dark = Color(0x99FFFFFF);
  static const Color text_color_light = Color(0xFF777985);
}
