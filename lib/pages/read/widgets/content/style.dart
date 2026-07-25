import 'package:flutter/material.dart';

/// 正文内容区块样式常量
class ContentStyle {
  /// 正文区块顶部间距
  static const double reading_top_spacing = 0;

  /// 正文容器圆角
  static const double reading_radius = 0;

  /// 正文容器内边距
  static const EdgeInsets reading_padding = EdgeInsets.fromLTRB(0, 18, 0, 32);

  /// 正文标题字号
  static const double reading_title_font_size = 22;

  /// 正文提示字号
  static const double reading_hint_font_size = 12;

  /// 正文段落顶部间距
  static const double reading_paragraph_top_spacing = 16;

  /// 正文字号
  static const double reading_paragraph_font_size = 17;

  /// 正文行高
  static const double reading_paragraph_height = 1.9;

  /// 正文段落底部间距
  static const double reading_paragraph_bottom_spacing = 18;

  /// 阅读提示标题与副标题的垂直间距
  static const double reading_hint_top_spacing = 6;

  /// 正文容器底部外边距
  static const double reading_container_bottom_margin = 8;

  /// 正文点击区域分段数量
  static const double reading_tap_block_count = 3;

  /// 正文点击区域中段上边界倍数（第 2 段起点）
  static const double reading_tap_middle_block_factor = 2;

  /// 点击中间区域时的调试日志文案
  static const String reading_middle_tap_debug_message = '显示上下的操作栏';

  /// 底部阅读进度遮罩建议高度（用于计算点击区域）
  static const double reading_mask_height = 96;

  /// 夜间模式下的正文文字颜色
  static const Color reading_text_color_dark = Color(0xE0FFFFFF); // white88

  /// 日间模式下的正文文字颜色
  static const Color reading_text_color_light = Color(0xFF3B3226);

  /// 夜间模式下的正文标题颜色
  static const Color reading_title_color_dark = Colors.white;

  /// 日间模式下的正文标题颜色
  static const Color reading_title_color_light = Color(0xFF1F1A12);

  /// 夜间模式下的正文提示颜色
  static const Color reading_hint_color_dark = Color(0xA3FFFFFF); // white64

  /// 日间模式下的正文提示颜色
  static const Color reading_hint_color_light = Color(0xFF7A6A56);

  /// 上一章加载中指示器的垂直内边距
  static const EdgeInsets loading_indicator_padding = EdgeInsets.symmetric(
    vertical: 32,
  );

  /// 上一章加载中指示器的图标尺寸
  static const double loading_indicator_icon_size = 16;

  /// 上一章加载中指示器的图标与文字间距
  static const double loading_indicator_icon_spacing = 8;

  /// 上一章加载中指示器的文字字号
  static const double loading_indicator_font_size = 14;

  /// 夜间模式下加载指示器的文字颜色
  static const Color loading_indicator_text_color_dark = Color(0xA3FFFFFF);

  /// 日间模式下加载指示器的文字颜色
  static const Color loading_indicator_text_color_light = Color(0xFF7A6A56);
}
