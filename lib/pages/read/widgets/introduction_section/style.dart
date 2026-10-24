import 'package:app/config/layout_config.dart';
import 'package:app/components/work_about_section/style.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

/// 阅读页介绍区块样式常量
class IntroductionStyle {
  static const double content_horizontal_padding =
      WorkAboutSectionStyle.horizontal_padding;

  /// 圆角纸面上移覆盖头图的装饰区域，真实布局同时扣除这段高度。
  static const double content_panel_overlap = 20;
  static const double content_panel_radius = LayoutConfig.radius_20;
  static const double content_bottom_spacing = LayoutConfig.space_24;
  static const Color content_background_light = ColorConstants.whiteColor;
  static final Color content_background_dark =
      ColorConstants.nightBackgroundColor;

  /// 顶部封面宽度
  static const double cover_width = 108;

  /// 顶部封面高度
  static const double cover_height = 144;

  /// 顶部封面圆角
  static const double cover_radius = LayoutConfig.radius_8;

  /// 标题顶部间距
  static const double title_top_spacing = LayoutConfig.space_16;

  /// 标题字号
  static const double title_font_size = 22;

  /// 作者区顶部间距
  static const double author_top_spacing = LayoutConfig.space_12;

  /// 统计面板顶部间距
  static const double stat_panel_top_spacing = LayoutConfig.space_18;

  /// 标签区顶部间距
  // 海报末尾已经绘制20dp圆角纸面，这里只补4dp形成24dp模块留白。
  static const double tag_section_top_spacing = LayoutConfig.space_4;

  /// 简介区顶部间距
  static const double intro_top_spacing = LayoutConfig.space_12;

  /// 评论区顶部间距
  static const double comment_top_spacing = LayoutConfig.space_24;

  /// 夜间模式下的标题颜色
  static const Color title_color_dark = ColorConstants.whiteColor;

  /// 日间模式下的标题颜色
  static const Color title_color_light =
      ColorConstants.components_reader_top_bar_style_tone_ff1f1a12;
}
