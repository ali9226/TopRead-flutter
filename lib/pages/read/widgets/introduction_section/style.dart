import 'package:flutter/material.dart';
import 'package:app/config/layout_config.dart';
import 'package:app/config/color_config.dart';

/// 阅读页介绍区块样式常量
class IntroductionStyle {
  static const double content_horizontal_padding =
      LayoutConfig.page_horizontal_padding;

  /// 圆角纸面上移覆盖头图的装饰区域，真实布局同时扣除这段高度。
  static const double content_panel_overlap = 18;
  static const double content_panel_radius = 18;
  static const double content_bottom_spacing = 24;
  static const Color content_background_light = Color(0xFFF8F7F5);
  static final Color content_background_dark =
      ColorConstants.nightBackgroundColor;

  /// 顶部封面宽度
  static const double cover_width = 108;

  /// 顶部封面高度
  static const double cover_height = 144;

  /// 顶部封面圆角
  static const double cover_radius = 8;

  /// 标题顶部间距
  static const double title_top_spacing = 16;

  /// 标题字号
  static const double title_font_size = 22;

  /// 作者区顶部间距
  static const double author_top_spacing = 12;

  /// 统计面板顶部间距
  static const double stat_panel_top_spacing = 18;

  /// 标签区顶部间距
  static const double tag_section_top_spacing = 20;

  /// 简介区顶部间距
  static const double intro_top_spacing = 12;

  /// 评论区顶部间距
  static const double comment_top_spacing = 24;

  /// 夜间模式下的标题颜色
  static const Color title_color_dark = Colors.white;

  /// 日间模式下的标题颜色
  static const Color title_color_light = Color(0xFF1F1A12);
}
