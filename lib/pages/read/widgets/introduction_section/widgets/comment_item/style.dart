import 'package:flutter/material.dart';

/// 书评项样式常量。
///
/// 极简无背景布局，精致排版。
class CommentItemStyle {
  /// 评论项内边距。
  static const EdgeInsets item_padding = EdgeInsets.symmetric(vertical: 12);

  /// 头像尺寸。
  static const double avatar_size = 34;

  /// 头像与内容区域的间距。
  static const double avatar_content_spacing = 12;

  /// 昵称字号。
  static const double name_font_size = 13;

  /// 昵称与正文的间距。
  static const double header_text_spacing = 6;

  /// 昵称与星级的间距。
  static const double name_star_spacing = 8;

  /// 星级圆点尺寸。
  static const double star_dot_size = 4;

  /// 星级圆点间距。
  static const double star_dot_spacing = 3;

  /// 空星级透明度。
  static const double star_empty_alpha = 0.2;

  /// 正文字号（CJK 语系）。
  static const double text_font_size_cjk = 14.5;

  /// 正文字号（字母语系）。
  static const double text_font_size_alphabetic = 14;

  /// 正文行高（CJK 语系）。
  static const double text_line_height_cjk = 1.55;

  /// 正文行高（字母语系）。
  static const double text_line_height_alphabetic = 1.6;

  /// 分割线内边距（左侧与内容对齐）。
  static const EdgeInsets divider_padding = EdgeInsets.only(
    left: avatar_size + avatar_content_spacing,
  );

  /// 分割线粗细。
  static const double divider_thickness = 0.5;

  /// 日间昵称颜色。
  static const Color name_color_light = Color(0xFF6B5E4E);

  /// 夜间昵称颜色。
  static const Color name_color_dark = Color(0xFFA89E90);

  /// 日间正文颜色。
  static const Color text_color_light = Color(0xFF2B2620);

  /// 夜间正文颜色。
  static const Color text_color_dark = Color(0xFFD8D2CA);

  /// 日间分割线颜色。
  static const Color divider_color_light = Color(0xFFE8E2DA);

  /// 夜间分割线颜色。
  static const Color divider_color_dark = Color(0xFF2A3040);

  /// 日间星级颜色。
  static const Color star_color_light = Color(0xFFD4A853);

  /// 夜间星级颜色。
  static const Color star_color_dark = Color(0xFFB8965A);
}
