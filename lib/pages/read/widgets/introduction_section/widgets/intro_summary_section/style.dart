import 'package:flutter/material.dart';

/// 简介区块样式常量
class IntroSummaryStyle {
  /// 区块标题字号
  static const double section_title_font_size = 16;

  /// 简介内容顶部间距
  static const double intro_top_spacing = 12;

  /// 简介字号
  static const double intro_font_size = 13;

  /// 简介文案行高倍数
  static const double intro_line_height = 1.5;

  /// 简介文案右侧预留间距
  static const double intro_right_padding = 20;

  /// 更多文字字号
  static const double more_font_size = 12;

  /// 夜间模式下的正文颜色
  static const Color intro_text_color_dark = Color(0xA3FFFFFF); // white64

  /// 日间模式下的正文颜色
  static const Color intro_text_color_light = Color(0xFF7A6A56);

  /// 夜间模式下的标题颜色
  static const Color intro_title_color_dark = Colors.white;

  /// 日间模式下的标题颜色
  static const Color intro_title_color_light = Color(0xFF1F1A12);

  /// 更多按钮颜色
  static const Color more_button_color = Color(0xFF3D7DFF);
}
