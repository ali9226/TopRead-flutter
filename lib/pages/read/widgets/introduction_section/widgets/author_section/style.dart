import 'package:flutter/material.dart';

/// 作者信息区块样式常量
class AuthorStyle {
  /// 作者信息顶部间距
  static const double author_top_spacing = 12;

  /// 作者头像尺寸
  static const double author_avatar_size = 26;

  /// 作者名字号
  static const double author_name_font_size = 13;

  /// 关注标签左间距
  static const double follow_tag_left_spacing = 8;

  /// 作者头像与作者名字之间的间距
  static const double author_name_left_spacing = 8;

  /// 关注标签圆角
  static const double follow_tag_radius = 999;

  /// 关注标签横向内边距
  static const double follow_tag_horizontal_padding = 10;

  /// 关注标签纵向内边距
  static const double follow_tag_vertical_padding = 4;

  /// 关注标签字号
  static const double follow_tag_font_size = 12;

  /// 关注标签背景透明度
  static const double follow_tag_background_alpha = 0.16;

  /// 作者头像兜底背景透明度
  static const double author_avatar_fallback_background_alpha = 0.20;

  /// 夜间模式下的作者名颜色
  static const Color author_name_color_dark = Colors.white;

  /// 日间模式下的作者名颜色
  static const Color author_name_color_light = Color(0xFF1F1A12);

  /// 品牌主色 (蓝色)，用于头像背景和关注标签
  static const Color brand_color = Color(0xFF3D7DFF);
}
