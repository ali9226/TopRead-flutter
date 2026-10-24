// ignore_for_file: non_constant_identifier_names

import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

/// WebView 页面样式配置。
///
/// 存放页面布局、颜色、文字样式等常量。
class Style {
  /// 加载进度条高度。
  static const double progress_bar_height = 3;

  /// 关闭按钮尺寸。
  static const double close_button_size = 40;

  /// 关闭按钮圆角半径。
  static const double close_button_radius = LayoutConfig.radius_20;

  /// 关闭按钮图标尺寸。
  static const double close_icon_size = LayoutConfig.icon_regular;

  /// 关闭按钮距离顶部间距。
  static const double close_button_top_margin = LayoutConfig.space_8;

  /// 关闭按钮距离左侧间距。
  static const double close_button_left_margin = LayoutConfig.space_8;

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
  static const double error_title_spacing = LayoutConfig.space_16;

  /// 加载失败描述与标题间距。
  static const double error_description_spacing = LayoutConfig.space_8;

  /// 重试按钮与描述间距。
  static const double retry_button_spacing = LayoutConfig.space_24;

  /// 重试按钮水平内边距。
  static const double retry_button_horizontal_padding = LayoutConfig.space_24;

  /// 重试按钮垂直内边距。
  static const double retry_button_vertical_padding = LayoutConfig.space_12;

  /// 加载状态文字与圆圈间距。
  static const double loading_text_spacing = LayoutConfig.space_12;

  /// 加载状态文字字体大小。
  static const double loading_text_font_size = 14;

  /// 日间模式加载遮罩背景色。
  static const Color loading_overlay_light_color = ColorConstants.whiteColor;

  /// 夜间模式加载遮罩背景色。
  static const Color loading_overlay_dark_color = ColorConstants.nightBackgroundColor;

  /// 日间模式错误页面背景色。
  static const Color error_page_light_background = ColorConstants.whiteColor;

  /// 夜间模式错误页面背景色。
  static const Color error_page_dark_background = ColorConstants.nightBackgroundColor;

  /// 日间模式错误图标颜色。
  static const Color error_icon_light_color = ColorConstants.customer_service_sheet_style_time_color_light;

  /// 夜间模式错误图标颜色。
  static const Color error_icon_dark_color = ColorConstants.nightTextColor;

  /// 日间模式错误标题文字颜色。
  static const Color error_title_light_color = ColorConstants.components_paragraph_comment_sheet_style_tone_ff333333;

  /// 夜间模式错误标题文字颜色。
  static const Color error_title_dark_color = ColorConstants.whiteColor;

  /// 日间模式错误描述文字颜色。
  static const Color error_description_light_color = ColorConstants.customer_service_sheet_style_time_color_light;

  /// 夜间模式错误描述文字颜色。
  static const Color error_description_dark_color = ColorConstants.nightTextColor;
}
