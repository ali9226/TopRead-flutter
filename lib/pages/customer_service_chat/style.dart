// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:flutter/material.dart';
import 'package:app/util/color_util.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/common_style/input_bar/style.dart';

/// 在线客服聊天页面样式常量。
///
/// 底部输入栏样式来自 [InputBarStyle]，与评论弹窗保持一致。
class CustomerServiceChatStyle {
  CustomerServiceChatStyle._();

  /// 顶部导航栏高度。
  static const double nav_bar_height = 52;

  /// 顶部导航栏标题字号（CJK）。
  static const double nav_title_font_size_cjk = 17;

  /// 顶部导航栏标题字号（字母语系）。
  static const double nav_title_font_size_alphabetic = 16;

  /// 顶部导航栏标题字重。
  static final FontWeight nav_title_font_weight = FontConfig.adjustedWeight(
    FontWeight.w500,
  );

  /// 标题文字颜色（日间模式）。
  static final Color title_color_light = ColorConstants.lightTextColor;

  /// 标题文字颜色（夜间模式）。
  static final Color title_color_dark = hexToColor("#EEEEEE");

  /// 导航栏背景色（日间模式）。
  static final Color nav_bg_color_light = hexToColor("#FFFFFF");

  /// 导航栏背景色（夜间模式）。
  static const Color nav_bg_color_dark = InputBarStyle.bar_bg_dark;

  /// 页面背景色（日间模式）。
  static final Color page_bg_color_light = hexToColor("#F5F5F5");

  /// 页面背景色（夜间模式）。
  static final Color page_bg_color_dark = hexToColor("#12121C");

  /// 消息气泡 - 用户发送背景色。
  static final Color bubble_user_bg = ColorConstants.themeColor;

  /// 消息气泡 - 用户发送文字颜色。
  static final Color bubble_user_text = ColorConstants.lightTextColor;

  /// 消息气泡 - 管理员发送背景色（日间模式）。
  static final Color bubble_admin_bg_light = hexToColor("#FFFFFF");

  /// 消息气泡 - 管理员发送背景色（夜间模式）。
  static final Color bubble_admin_bg_dark = hexToColor("#2A2A3C");

  /// 消息气泡 - 管理员发送文字颜色（日间模式）。
  static final Color bubble_admin_text_light = ColorConstants.lightTextColor;

  /// 消息气泡 - 管理员发送文字颜色（夜间模式）。
  static final Color bubble_admin_text_dark = hexToColor("#EEEEEE");

  /// 消息气泡最大宽度比例（相对屏幕宽度）。
  static const double bubble_max_width_ratio = 0.7;

  /// 消息气泡圆角。
  static const double bubble_radius = 12;

  /// 消息气泡内边距。
  static const double bubble_padding_h = 14;
  static const double bubble_padding_v = 10;

  /// 消息文字字号。
  static const double message_font_size = 15;

  /// 消息文字字重。
  static final FontWeight message_font_weight = FontConfig.adjustedWeight(
    FontWeight.w400,
  );

  /// 气泡内时间字号。
  static const double message_time_font_size = 10;

  /// 气泡内时间字重。
  static final FontWeight message_time_font_weight = FontConfig.adjustedWeight(
    FontWeight.w400,
  );

  /// 消息内容与时间的垂直间距。
  static const double message_time_spacing = 5;

  /// 图片消息时间标签距边缘的距离。
  static const double image_time_inset = 6;

  /// 图片消息时间标签内边距。
  static const double image_time_padding_h = 5;
  static const double image_time_padding_v = 3;

  /// 图片消息时间标签圆角。
  static const double image_time_radius = 5;

  /// 消息间距。
  static const double message_spacing = 12;

  /// 头像尺寸。
  static const double avatar_size = 36;

  /// 头像圆角。
  static const double avatar_radius = 18;

  /// 头像与气泡间距。
  static const double avatar_bubble_spacing = 8;

  /// 气泡箭头宽度。
  static const double bubble_arrow_width = 10;

  /// 气泡箭头高度。
  static const double bubble_arrow_height = 14;

  /// 气泡箭头尖角圆角。
  static const double bubble_arrow_corner_radius = 3;

  /// 气泡额外留白（左右两侧）。
  static const double bubble_extra_padding = 60;

  /// 消息列表内边距。
  static const double list_padding_h = 12;
  static const double list_padding_v = 12;

  // ==================== 输入栏（引用 InputBarStyle） ====================
  //
  // 以下常量统一从 InputBarStyle 获取，确保在线客服与评论弹窗样式一致。
  // 如需调整输入栏外观，请修改 app/lib/config/input_bar_style.dart。

  /// 输入栏水平内边距。
  static const double input_bar_padding_h = InputBarStyle.padding_h;

  /// 输入栏垂直内边距。
  static const double input_bar_padding_v = InputBarStyle.padding_v;

  /// 输入栏背景色（日间模式）。
  static const Color input_bar_bg_light = InputBarStyle.bar_bg_light;

  /// 输入栏背景色（夜间模式）。
  static const Color input_bar_bg_dark = InputBarStyle.bar_bg_dark;

  /// 输入框背景色（日间模式）。
  static const Color input_field_bg_light = InputBarStyle.field_bg_light;

  /// 输入框背景色（夜间模式）。
  static const Color input_field_bg_dark = InputBarStyle.field_bg_dark;

  /// 输入框文字颜色（日间模式）。
  static final Color input_text_color_light = ColorConstants.lightTextColor;

  /// 输入框文字颜色（夜间模式）。
  static final Color input_text_color_dark = hexToColor("#EEEEEE");

  /// 输入框提示文字颜色。
  static final Color input_hint_color = hexToColor("#999999");

  /// 输入框字号。
  static const double input_font_size = InputBarStyle.font_size_cjk;

  /// 输入框圆角。
  static const double input_radius = InputBarStyle.field_radius;

  /// 发送按钮颜色。
  static final Color send_button_color = ColorConstants.themeColor;

  /// 发送按钮文字颜色。
  static final Color send_button_text_color = ColorConstants.lightTextColor;

  /// 发送按钮字号。
  static const double send_button_font_size = InputBarStyle.send_font_size_cjk;

  /// 功能按钮点击区域尺寸。
  static const double tool_button_size = InputBarStyle.tool_button_size;

  /// 功能图标显示尺寸。
  static const double tool_icon_size = InputBarStyle.tool_icon_size;

  /// 功能按钮颜色（日间模式）。
  static final Color tool_icon_color_light = hexToColor("#666666");

  /// 功能按钮颜色（夜间模式）。
  static final Color tool_icon_color_dark = hexToColor("#999999");

  /// 表情面板每行数量。
  static const int emoji_columns = InputBarStyle.emoji_columns;

  /// 表情面板背景色（日间模式）。
  static final Color emoji_panel_bg_light = InputBarStyle.emoji_panel_bg_light;

  /// 表情面板背景色（夜间模式）。
  static final Color emoji_panel_bg_dark = InputBarStyle.emoji_panel_bg_dark;

  /// 预置表情列表。
  static const List<String> emoji_list = InputBarStyle.emoji_list;

  /// 分隔线颜色（日间模式）。
  static final Color divider_color_light = hexToColor("#E0E0E0");

  /// 分隔线颜色（夜间模式）。
  static final Color divider_color_dark = hexToColor("#2A2A3C");

  /// 空状态提示文字字号。
  static const double empty_font_size = 14;

  /// 空状态提示文字颜色。
  static final Color empty_text_color = hexToColor("#999999");

  /// 加载指示器颜色。
  static final Color loading_color = ColorConstants.themeColor;

  /// 靠近历史顶部时提前触发加载的距离。
  static const double history_load_threshold = 240;

  /// 顶部历史状态区固定高度，状态切换时不改变列表几何尺寸。
  static const double history_status_height = 40;

  /// 预构建视口外消息的距离，减少快速滚动时的白屏。
  static const double list_cache_extent = 640;

  /// 跟随到最新消息的动画时长。
  static const Duration scroll_animation_duration = Duration(milliseconds: 180);

  /// 时间分割线文字颜色。
  static final Color time_divider_color = hexToColor("#BBBBBB");

  /// 时间分割线文字字号。
  static const double time_divider_font_size = 11;
}
