import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

/// 作者信息区块样式常量
class AuthorStyle {
  /// 作者信息顶部间距
  static const double author_top_spacing = LayoutConfig.space_12;

  /// 作者头像尺寸
  static const double author_avatar_size = 26;

  /// 作者名字号
  static const double author_name_size_cjk = 13;
  static const double author_name_size_alphabetic = 12.5;
  static const double author_name_height_cjk = 1.4;
  static const double author_name_height_alphabetic = 1.5;
  static const double inline_min_width_cjk = 240;
  static const double inline_min_width_alphabetic = 260;
  static const double follow_tag_top_spacing = LayoutConfig.space_8;

  /// 关注标签左间距
  static const double follow_tag_left_spacing = LayoutConfig.space_8;

  /// 作者头像与作者名字之间的间距
  static const double author_name_left_spacing = LayoutConfig.space_8;

  /// 关注标签圆角
  static const double follow_tag_radius = LayoutConfig.radius_pill;

  /// 关注标签横向内边距
  static const double follow_tag_horizontal_padding = LayoutConfig.space_10;

  /// 关注标签纵向内边距
  static const double follow_tag_vertical_padding = LayoutConfig.space_4;

  /// 关注标签字号
  static const double follow_tag_font_size = 12;

  /// 关注标签背景透明度
  static const double follow_tag_background_alpha = 0.16;

  /// 作者头像兜底背景透明度
  static const double author_avatar_fallback_background_alpha = 0.20;

  /// 夜间模式下的作者名颜色
  static const Color author_name_color_dark = ColorConstants.whiteColor;

  /// 日间模式下的作者名颜色
  static const Color author_name_color_light = ColorConstants.components_reader_top_bar_style_tone_ff1f1a12;

  /// 品牌主色 (蓝色)，用于头像背景和关注标签
  static const Color brand_color = ColorConstants.pages_read_widgets_read_directory_sheet_widgets_book_detail_header_tone;
  static const double hero_follow_width_ratio = 0.42;
  static const double hero_name_size_cjk = 13;
  static const double hero_name_size_alphabetic = 12;
}
