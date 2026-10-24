import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

/// 标签区块样式常量
class TagStyle {
  /// 区块标题字号
  static const double section_title_font_size = 16;

  /// 标签区域左间距
  static const double tag_wrap_left_spacing = LayoutConfig.space_10;

  /// “标签”标题顶部微调偏移
  static const double tag_title_top_padding = LayoutConfig.space_4;

  /// 标签背景在夜间主题下的透明度
  static const double tag_background_night_alpha = 0.18;

  /// 标签背景在日间主题下的透明度
  static const double tag_background_light_alpha = 0.12;

  /// 标签横向间距
  static const double tag_spacing = LayoutConfig.space_6;

  /// 标签纵向间距
  static const double tag_run_spacing = LayoutConfig.space_6;

  /// 标签圆角
  static const double tag_radius = LayoutConfig.radius_pill;

  /// 标签横向内边距
  static const double tag_horizontal_padding = LayoutConfig.space_10;

  /// 标签纵向内边距
  static const double tag_vertical_padding = LayoutConfig.space_4;

  /// 标签字号
  static const double tag_font_size = 11;

  /// 夜间模式下的标签文字颜色
  static const Color tag_text_color_dark = ColorConstants.whiteColor;

  /// 日间模式下的标签文字颜色
  static const Color tag_text_color_light = ColorConstants.components_reader_top_bar_style_tone_ff7a6a56;
}
