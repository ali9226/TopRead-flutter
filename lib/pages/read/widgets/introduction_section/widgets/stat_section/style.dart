import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';

/// 统计数据区块样式常量
class StatStyle {
  /// 数据面板顶部间距
  static const double stat_panel_top_spacing = LayoutConfig.space_18;

  /// 数据面板圆角
  static const double stat_panel_radius = LayoutConfig.radius_18;

  /// 数据面板内边距
  static const EdgeInsets stat_panel_padding = EdgeInsets.fromLTRB(
    LayoutConfig.space_8,
    LayoutConfig.space_10,
    LayoutConfig.space_8,
    LayoutConfig.space_10,
  );

  /// 数据主数字字号
  static const double stat_major_font_size = 19;

  /// 数据单位字号
  static const double stat_minor_font_size = 10;

  /// 数据副标题顶部间距
  static const double stat_subtitle_top_spacing = LayoutConfig.space_4;

  /// 数据副标题字号
  static const double stat_subtitle_font_size = 11;

  /// 数据副标题图标间距
  static const double stat_subtitle_icon_gap = LayoutConfig.space_3;

  /// 数据副标题图标尺寸
  static const double stat_subtitle_icon_size = 9;

  /// 统计分割线宽度
  static const double stat_divider_width = 14;

  /// 统计分割线在夜间主题下的透明度
  static const double stat_divider_night_alpha = 0.08;

  /// 统计分割线在日间主题下的透明度
  static const double stat_divider_light_alpha = 0.04;

  /// 统计单位文案底部对齐偏移
  static const double stat_minor_bottom_padding = LayoutConfig.space_3;

  /// 统计单位文案左侧偏移
  static const double stat_minor_left_padding = LayoutConfig.space_2;

  /// 次要文字在夜间主题下的透明度
  static const double secondary_text_night_alpha = 0.64;
  static const double hero_divider_width = 0.5;
  static const double hero_divider_height = 18;
  static const double hero_divider_alpha = 0.28;
  static const double hero_gap = LayoutConfig.space_5;
  static const double hero_icon_size = LayoutConfig.icon_small;
  static const double hero_icon_gap = LayoutConfig.space_3;
  static const double hero_label_gap = LayoutConfig.space_2;
  static const double hero_value_size_cjk = 14;
  static const double hero_value_size_alphabetic = 13;
  static const double hero_label_size_cjk = 10;
  static const double hero_label_size_alphabetic = 10;
  static const double hero_label_alpha = 0.78;
}
