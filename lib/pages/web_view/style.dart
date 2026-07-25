// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';

/// WebView 页面样式配置。
///
/// 存放页面布局、颜色、文字样式等常量。
class Style {
  /// 加载进度条高度。
  static const double progress_bar_height = 3;

  /// 关闭按钮尺寸。
  static const double close_button_size = 40;

  /// 关闭按钮圆角半径。
  static const double close_button_radius = 20;

  /// 关闭按钮图标尺寸。
  static const double close_icon_size = 24;

  /// 关闭按钮距离顶部间距。
  static const double close_button_top_margin = 8;

  /// 关闭按钮距离左侧间距。
  static const double close_button_left_margin = 8;

  /// 关闭按钮背景透明度。
  static const double close_button_background_alpha = 0.50;

  /// 加载中区域尺寸。
  static const double loading_area_size = 40;

  /// 加载失败图标尺寸。
  static const double error_icon_size = 64;

  /// 加载失败标题字体大小。
  static const double error_title_font_size = 18;

  /// 加载失败描述字体大小。
  static const double error_description_font_size = 14;

  /// 加载失败标题与图标间距。
  static const double error_title_spacing = 16;

  /// 加载失败描述与标题间距。
  static const double error_description_spacing = 8;

  /// 重试按钮与描述间距。
  static const double retry_button_spacing = 24;

  /// 重试按钮水平内边距。
  static const double retry_button_horizontal_padding = 24;

  /// 重试按钮垂直内边距。
  static const double retry_button_vertical_padding = 12;

  /// 加载状态文字与圆圈间距。
  static const double loading_text_spacing = 12;

  /// 加载状态文字字体大小。
  static const double loading_text_font_size = 14;

  /// 日间模式加载遮罩背景色。
  static const Color loading_overlay_light_color = Color(0xFFFFFFFF);

  /// 夜间模式加载遮罩背景色。
  static const Color loading_overlay_dark_color = Color(0xFF12121C);

  /// 日间模式错误页面背景色。
  static const Color error_page_light_background = Color(0xFFFFFFFF);

  /// 夜间模式错误页面背景色。
  static const Color error_page_dark_background = Color(0xFF12121C);

  /// 日间模式错误图标颜色。
  static const Color error_icon_light_color = Color(0xFF999999);

  /// 夜间模式错误图标颜色。
  static const Color error_icon_dark_color = Color(0xFF68697E);

  /// 日间模式错误标题文字颜色。
  static const Color error_title_light_color = Color(0xFF333333);

  /// 夜间模式错误标题文字颜色。
  static const Color error_title_dark_color = Color(0xFFFFFFFF);

  /// 日间模式错误描述文字颜色。
  static const Color error_description_light_color = Color(0xFF999999);

  /// 夜间模式错误描述文字颜色。
  static const Color error_description_dark_color = Color(0xFF68697E);
}
