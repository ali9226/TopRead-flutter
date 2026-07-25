import 'package:flutter/material.dart';

/// 统计数据区块样式常量
class StatStyle {
  /// 数据面板顶部间距
  static const double stat_panel_top_spacing = 18;

  /// 数据面板圆角
  static const double stat_panel_radius = 18;

  /// 数据面板内边距
  static const EdgeInsets stat_panel_padding = EdgeInsets.fromLTRB(
    8,
    10,
    8,
    10,
  );

  /// 数据主数字字号
  static const double stat_major_font_size = 19;

  /// 数据单位字号
  static const double stat_minor_font_size = 10;

  /// 数据副标题顶部间距
  static const double stat_subtitle_top_spacing = 4;

  /// 数据副标题字号
  static const double stat_subtitle_font_size = 11;

  /// 数据副标题图标间距
  static const double stat_subtitle_icon_gap = 3;

  /// 数据副标题图标尺寸
  static const double stat_subtitle_icon_size = 9;

  /// 统计分割线宽度
  static const double stat_divider_width = 14;

  /// 统计分割线在夜间主题下的透明度
  static const double stat_divider_night_alpha = 0.08;

  /// 统计分割线在日间主题下的透明度
  static const double stat_divider_light_alpha = 0.04;

  /// 统计单位文案底部对齐偏移
  static const double stat_minor_bottom_padding = 3;

  /// 统计单位文案左侧偏移
  static const double stat_minor_left_padding = 2;

  /// 次要文字在夜间主题下的透明度
  static const double secondary_text_night_alpha = 0.64;
}
