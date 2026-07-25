import 'package:flutter/material.dart';
import 'package:app/config/layout_config.dart';

/// 消息页样式常量。
class MessageStyle {
  /// 页面边距。
  static const double page_top_padding = 16;
  static const double page_bottom_padding = 24;
  static const EdgeInsets page_padding = EdgeInsets.fromLTRB(
    LayoutConfig.page_horizontal_padding,
    page_top_padding,
    LayoutConfig.page_horizontal_padding,
    page_bottom_padding,
  );

  /// 顶部渐变遮罩参数。
  static const double header_gradient_height = 90;
  static const double header_gradient_start_opacity = 0.82;
  static const double header_gradient_middle_opacity = 0.24;

  /// 头部标题字号。
  static const double title_size = 24;

  /// 背景装饰参数。
  static const double decor_circle_one_top = -70;
  static const double decor_circle_one_right = -38;
  static const double decor_circle_one_size = 210;
  static const double decor_circle_two_top = 138;
  static const double decor_circle_two_left = -44;
  static const double decor_circle_two_size = 164;

  /// 概览统计卡参数。
  static const double quick_stat_radius = LayoutConfig.section_radius;
  static const double quick_stat_height = 102;
  static const double quick_stat_item_gap = 10;
  static const EdgeInsets quick_stat_padding = EdgeInsets.fromLTRB(
    14,
    14,
    14,
    12,
  );

  /// 未登录占位视图参数。
  static const double no_login_icon_size = 180;
  static const double no_login_top_spacing = 36;
  static const double no_login_icon_bottom_spacing = 20;
  static const double no_login_title_bottom_spacing = 10;
  static const double no_login_desc_bottom_spacing = 24;
  static const double no_login_button_height = 44;
  static const double no_login_button_radius = LayoutConfig.card_radius;
  static const double no_login_button_horizontal_padding = 18;
  static const double no_login_button_font_size = 15;
  static const double no_login_customer_service_top_spacing = 28;

  /// 消息卡片参数。
  static const double card_radius = LayoutConfig.section_radius;
  static const double card_margin_bottom = 12;
  static const EdgeInsets card_padding = EdgeInsets.fromLTRB(16, 16, 16, 16);

  /// 图标圆形底参数。
  static const double icon_wrap_size = 44;
  static const double icon_size = 22;

  /// 小说封面参数。
  static const double cover_width = 45;
  static const double cover_height = 55;
  static const double cover_radius = 8;

  /// 标签参数。
  static const double badge_radius = 999;
  static const EdgeInsets badge_padding = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 6,
  );
}
