// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';
import 'package:app/config/color_config.dart';

/// 在线客服聊天弹窗样式常量。
class CustomerServiceSheetStyle {
  CustomerServiceSheetStyle._();

  /// 弹窗高度比例（屏幕高度的 90%）。
  static const double height_ratio = 0.9;

  /// 弹窗顶部圆角半径。
  static const double border_radius_top = LayoutConfig.radius_16;

  /// 弹窗顶部拖拽指示条的宽度。
  static const double drag_bar_width = 40;

  /// 弹窗顶部拖拽指示条的高度。
  static const double drag_bar_height = 4;

  /// 弹窗顶部拖拽指示条的圆角。
  static const double drag_bar_radius = LayoutConfig.radius_2;

  /// 拖拽指示条颜色（日间模式）。
  static final Color drag_bar_color_light = ColorConstants.customer_service_sheet_style_drag_bar_color_light;

  /// 拖拽指示条颜色（夜间模式）。
  static final Color drag_bar_color_dark = ColorConstants.customer_service_sheet_style_drag_bar_color_dark;

  /// 弹窗背景色（日间模式）。
  static final Color background_color_light = ColorConstants.whiteColor;

  /// 弹窗背景色（夜间模式）。
  static final Color background_color_dark = ColorConstants.customer_service_sheet_style_background_color_dark;

  /// 顶部导航栏高度。
  static const double nav_bar_height = LayoutConfig.navigation_bar_height;

  /// 顶部导航栏标题字号。
  static final double nav_title_font_size_cjk = 17;
  static final double nav_title_font_size_alphabetic = 16;

  /// 顶部导航栏标题字重。
  static final FontWeight nav_title_font_weight = FontConfig.adjustedWeight(FontWeight.w600);

  /// 标题文字颜色（日间模式）。
  static final Color title_color_light = ColorConstants.lightTextColor;

  /// 标题文字颜色（夜间模式）。
  static final Color title_color_dark = ColorConstants.components_reader_top_bar_style_tone_ffeeeeee;

  /// 聊天列表背景色（日间模式）。
  static final Color chat_bg_color_light = ColorConstants.config_color_config_tone_fff5f5f5;

  /// 聊天列表背景色（夜间模式）。
  static final Color chat_bg_color_dark = ColorConstants.nightBackgroundColor;

  /// 消息气泡 - 用户发送背景色。
  static final Color bubble_user_bg = ColorConstants.message_type_accent_color_list;

  /// 消息气泡 - 用户发送文字颜色。
  static final Color bubble_user_text = ColorConstants.lightTextColor;

  /// 消息气泡 - 管理员发送背景色（日间模式）。
  static final Color bubble_admin_bg_light = ColorConstants.whiteColor;

  /// 消息气泡 - 管理员发送背景色（夜间模式）。
  static final Color bubble_admin_bg_dark = ColorConstants.customer_service_sheet_style_bubble_admin_bg_dark;

  /// 消息气泡 - 管理员发送文字颜色（日间模式）。
  static final Color bubble_admin_text_light = ColorConstants.lightTextColor;

  /// 消息气泡 - 管理员发送文字颜色（夜间模式）。
  static final Color bubble_admin_text_dark = ColorConstants.components_reader_top_bar_style_tone_ffeeeeee;

  /// 消息气泡最大宽度比例（相对屏幕宽度）。
  static const double bubble_max_width_ratio = 0.7;

  /// 消息气泡圆角。
  static const double bubble_radius = LayoutConfig.radius_12;

  /// 消息气泡内边距。
  static const double bubble_padding_h = LayoutConfig.space_14;
  static const double bubble_padding_v = LayoutConfig.space_10;

  /// 消息文字字号。
  static const double message_font_size = 15;

  /// 消息文字字重。
  static final FontWeight message_font_weight = FontConfig.adjustedWeight(FontWeight.w400);

  /// 时间戳文字字号。
  static const double time_font_size = 11;

  /// 时间戳文字颜色（日间模式）。
  static final Color time_color_light = ColorConstants.customer_service_sheet_style_time_color_light;

  /// 时间戳文字颜色（夜间模式）。
  static final Color time_color_dark = ColorConstants.customer_service_sheet_style_time_color_dark;

  /// 消息间距。
  static const double message_spacing = LayoutConfig.space_12;

  /// 头像尺寸。
  static const double avatar_size = 36;

  /// 头像圆角。
  static const double avatar_radius = LayoutConfig.radius_18;

  /// 头像与气泡间距。
  static const double avatar_bubble_spacing = LayoutConfig.space_8;

  /// 输入栏高度。
  static const double input_bar_height = 56;

  /// 输入栏背景色（日间模式）。
  static final Color input_bar_bg_light = ColorConstants.customer_service_sheet_style_input_bar_bg_light;

  /// 输入栏背景色（夜间模式）。
  static final Color input_bar_bg_dark = ColorConstants.customer_service_sheet_style_input_bar_bg_dark;

  /// 输入框背景色（日间模式）。
  static final Color input_field_bg_light = ColorConstants.whiteColor;

  /// 输入框背景色（夜间模式）。
  static final Color input_field_bg_dark = ColorConstants.customer_service_sheet_style_bubble_admin_bg_dark;

  /// 输入框文字颜色（日间模式）。
  static final Color input_text_color_light = ColorConstants.lightTextColor;

  /// 输入框文字颜色（夜间模式）。
  static final Color input_text_color_dark = ColorConstants.components_reader_top_bar_style_tone_ffeeeeee;

  /// 输入框提示文字颜色。
  static final Color input_hint_color = ColorConstants.customer_service_sheet_style_time_color_light;

  /// 输入框字号。
  static const double input_font_size = 15;

  /// 输入框圆角。
  static const double input_radius = LayoutConfig.radius_20;

  /// 发送按钮颜色。
  static final Color send_button_color = ColorConstants.message_type_accent_color_list;

  /// 发送按钮文字颜色。
  static final Color send_button_text_color = ColorConstants.lightTextColor;

  /// 发送按钮字号。
  static const double send_button_font_size = 14;

  /// 功能按钮尺寸（表情、图片）。
  static const double tool_icon_size = 28;

  /// 功能按钮颜色（日间模式）。
  static final Color tool_icon_color_light = ColorConstants.customer_service_sheet_style_time_color_dark;

  /// 功能按钮颜色（夜间模式）。
  static final Color tool_icon_color_dark = ColorConstants.customer_service_sheet_style_time_color_light;

  /// 表情面板高度。
  static const double emoji_panel_height = 240;

  /// 表情面板每行数量。
  static const int emoji_columns = 7;

  /// 表情面板背景色（日间模式）。
  static final Color emoji_panel_bg_light = ColorConstants.customer_service_sheet_style_input_bar_bg_light;

  /// 表情面板背景色（夜间模式）。
  static final Color emoji_panel_bg_dark = ColorConstants.customer_service_sheet_style_input_bar_bg_dark;

  /// 预置表情列表。
  static const List<String> emoji_list = [
    '😀',
    '😂',
    '😍',
    '🤔',
    '😢',
    '😡',
    '👍',
    '👎',
    '❤️',
    '🎉',
    '🔥',
    '💯',
    '😊',
    '🙏',
    '😎',
    '🥺',
    '😤',
    '🤝',
    '💪',
    '✨',
    '🎊',
  ];

  /// 分隔线颜色（日间模式）。
  static final Color divider_color_light = ColorConstants.components_reader_top_bar_style_tone_ffeeeeee;

  /// 分隔线颜色（夜间模式）。
  static final Color divider_color_dark = ColorConstants.customer_service_sheet_style_bubble_admin_bg_dark;

  /// 空状态提示文字字号。
  static const double empty_font_size = 14;

  /// 空状态提示文字颜色。
  static final Color empty_text_color = ColorConstants.customer_service_sheet_style_time_color_light;

  /// 加载指示器颜色。
  static final Color loading_color = ColorConstants.message_type_accent_color_list;
}
