import 'package:flutter/material.dart';
import 'package:app/config/layout_config.dart';

/// 消息页样式常量。
class MessageStyle {
  /// 页面边距。
  static const double page_top_padding = LayoutConfig.space_16;
  static const double page_bottom_padding = LayoutConfig.space_24;
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
  static const double quick_stat_item_gap = LayoutConfig.space_10;
  static const EdgeInsets quick_stat_padding = EdgeInsets.fromLTRB(
    LayoutConfig.space_14,
    LayoutConfig.space_14,
    LayoutConfig.space_14,
    LayoutConfig.space_12,
  );

  /// 未登录占位视图参数。
  static const double no_login_icon_size = 180;
  static const double no_login_top_spacing = LayoutConfig.space_36;
  static const double no_login_icon_bottom_spacing = LayoutConfig.space_20;
  static const double no_login_title_bottom_spacing = LayoutConfig.space_10;
  static const double no_login_desc_bottom_spacing = LayoutConfig.space_24;
  static const double no_login_button_height =
      LayoutConfig.compact_control_height;
  static const double no_login_button_radius = LayoutConfig.card_radius;
  static const double no_login_button_horizontal_padding =
      LayoutConfig.space_18;
  static const double no_login_button_font_size = 15;
  static const double no_login_customer_service_top_spacing =
      LayoutConfig.space_28;

  /// 消息卡片参数。
  static const double card_radius = LayoutConfig.section_radius;
  static const double card_margin_bottom = LayoutConfig.space_12;
  static const EdgeInsets card_padding = EdgeInsets.fromLTRB(
    LayoutConfig.space_16,
    LayoutConfig.space_16,
    LayoutConfig.space_16,
    LayoutConfig.space_16,
  );

  /// 图标圆形底参数。
  static const double icon_wrap_size = 44;
  static const double icon_size = LayoutConfig.icon_compact;

  /// 小说封面参数。
  static const double cover_width = 45;
  static const double cover_height = 55;
  static const double cover_radius = LayoutConfig.radius_8;

  /// 标签参数。
  static const double badge_radius = LayoutConfig.radius_pill;
  static const EdgeInsets badge_padding = EdgeInsets.symmetric(
    horizontal: LayoutConfig.space_10,
    vertical: LayoutConfig.space_6,
  );
  static const double badge_font_size_cjk = 11;
  static const double badge_font_size_alphabetic = 11;
  static const double badge_max_width_ratio = 0.5;

  /// 封面和原图标共用角标，分组消息换为封面后仍能看到未读数量。
  static const double unread_badge_offset = -4;
  static const double unread_badge_min_size = 16;
  static const double unread_badge_radius = LayoutConfig.radius_10;
  static const double unread_badge_font_size = 10;
  static const int unread_badge_max_count = 99;
  static const EdgeInsets unread_badge_padding = EdgeInsets.symmetric(
    horizontal: LayoutConfig.space_5,
    vertical: LayoutConfig.space_1,
  );
}
