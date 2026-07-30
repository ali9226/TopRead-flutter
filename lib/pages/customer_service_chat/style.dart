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
  static final Color page_bg_color_light = hexToColor("#EDEDED");

  /// 页面背景色（夜间模式）。
  static final Color page_bg_color_dark = hexToColor("#111111");

  /// 消息气泡 - 用户发送背景色。
  static final Color bubble_user_bg = ColorConstants.themeColor;

  /// 消息气泡 - 用户发送文字颜色。
  static final Color bubble_user_text = ColorConstants.lightTextColor;

  /// 消息气泡 - 管理员发送背景色（日间模式）。
  static final Color bubble_admin_bg_light = hexToColor("#FFFFFF");

  /// 消息气泡 - 管理员发送背景色（夜间模式）。
  static final Color bubble_admin_bg_dark = hexToColor("#262626");

  /// 消息气泡 - 管理员发送文字颜色（日间模式）。
  static final Color bubble_admin_text_light = ColorConstants.lightTextColor;

  /// 消息气泡 - 管理员发送文字颜色（夜间模式）。
  static final Color bubble_admin_text_dark = hexToColor("#EEEEEE");

  /// 消息气泡最大宽度比例（相对屏幕宽度）。
  static const double bubble_max_width_ratio = 0.72;

  /// 宽屏设备上的消息气泡最大宽度。
  static const double bubble_max_width = 460;

  /// 消息气泡圆角。
  static const double bubble_radius = 10;

  /// 消息气泡内边距。
  static const double bubble_padding_h = 14;
  static const double bubble_padding_v = 10;

  /// 消息文字字号（CJK）。
  static const double message_font_size_cjk = 15.5;

  /// 消息文字字号（字母语系）。
  static const double message_font_size_alphabetic = 15;

  /// 消息文字行高（CJK）。
  static const double message_line_height_cjk = 1.38;

  /// 消息文字行高（字母语系）。
  static const double message_line_height_alphabetic = 1.42;

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
  static const double message_spacing = 14;

  /// 头像尺寸。
  static const double avatar_size = 36;

  /// 管理员头像内的 Logo 尺寸，为外框保留自然呼吸空间。
  static const double admin_avatar_logo_size = 30;

  /// 头像圆角。
  static const double avatar_radius = 18;

  /// 头像与气泡间距。
  static const double avatar_bubble_spacing = 8;

  /// 气泡箭头宽度。
  static const double bubble_arrow_width = 7;

  /// 气泡箭头高度。
  static const double bubble_arrow_height = 11;

  /// 气泡箭头距气泡顶部的距离。
  static const double bubble_arrow_top = 12;

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
  static const double input_font_size_cjk = InputBarStyle.font_size_cjk;

  /// 输入框字号（字母语系）。
  static const double input_font_size_alphabetic =
      InputBarStyle.font_size_alphabetic;

  /// 输入框圆角。
  static const double input_radius = InputBarStyle.field_radius;

  /// 输入框最小高度。
  static const double input_field_height = InputBarStyle.field_height;

  /// 输入框多行展开后的最大高度。
  static const double input_field_max_height = InputBarStyle.field_max_height;

  /// 输入框内部水平留白。
  static const double input_inner_padding = InputBarStyle.inner_padding;

  /// 输入框内部垂直留白。
  static const double input_content_padding_v =
      InputBarStyle.content_vertical_padding;

  /// 输入框文字行高。
  static const double input_line_height = InputBarStyle.text_line_height;

  /// 发送按钮颜色。
  static final Color send_button_color = ColorConstants.themeColor;

  /// 发送按钮文字颜色。
  static final Color send_button_text_color = ColorConstants.lightTextColor;

  /// 发送按钮字号（CJK）。
  static const double send_button_font_size_cjk =
      InputBarStyle.send_font_size_cjk;

  /// 发送按钮字号（字母语系）。
  static const double send_button_font_size_alphabetic =
      InputBarStyle.send_font_size_alphabetic;

  /// 发送按钮最小宽度（CJK）。
  static const double send_button_min_width_cjk =
      InputBarStyle.send_min_width_cjk;

  /// 发送按钮最小宽度（字母语系）。
  static const double send_button_min_width_alphabetic =
      InputBarStyle.send_min_width_alphabetic;

  /// 发送按钮高度。
  static const double send_button_height = InputBarStyle.send_height;

  /// 发送按钮圆角。
  static const double send_button_radius = InputBarStyle.send_radius;

  /// 发送按钮水平留白。
  static const double send_button_padding_h = InputBarStyle.send_padding_h;

  /// 发送按钮禁用背景色（日间模式）。
  static const Color send_disabled_bg_light =
      InputBarStyle.send_disabled_bg_light;

  /// 发送按钮禁用背景色（夜间模式）。
  static const Color send_disabled_bg_dark =
      InputBarStyle.send_disabled_bg_dark;

  /// 发送按钮禁用文字色（日间模式）。
  static const Color send_disabled_text_light =
      InputBarStyle.send_disabled_text_light;

  /// 发送按钮禁用文字色（夜间模式）。
  static const Color send_disabled_text_dark =
      InputBarStyle.send_disabled_text_dark;

  /// 功能按钮点击区域尺寸。
  static const double tool_button_size = InputBarStyle.tool_button_size;

  /// 功能图标显示尺寸。
  static const double tool_icon_size = InputBarStyle.tool_icon_size;

  /// 功能按钮颜色（日间模式）。
  static final Color tool_icon_color_light = hexToColor("#666666");

  /// 功能按钮颜色（夜间模式）。
  static final Color tool_icon_color_dark = hexToColor("#C7C7CC");

  /// 功能按钮激活颜色。
  static final Color tool_icon_active_color = ColorConstants.themeColor;

  /// 输入栏组件之间的间距。
  static const double input_action_spacing = 4;

  /// 表情面板每行数量。
  static const int emoji_columns = InputBarStyle.emoji_columns;

  /// 表情面板背景色（日间模式）。
  static final Color emoji_panel_bg_light = hexToColor("#F7F7F7");

  /// 表情面板背景色（夜间模式）。
  static final Color emoji_panel_bg_dark = hexToColor("#191919");

  /// 表情面板默认高度。
  static const double emoji_panel_default_height = 268;

  /// 表情面板切换动画时长。
  static const Duration emoji_panel_animation_duration = Duration(
    milliseconds: 220,
  );

  /// 表情网格水平留白。
  static const double emoji_panel_padding_h = 12;

  /// 表情网格顶部留白。
  static const double emoji_panel_padding_top = 12;

  /// 单个表情的点击区域边长。
  static const double emoji_item_size = 44;

  /// 表情文字字号。
  static const double emoji_font_size = 27;

  /// 预置表情列表。
  static const List<String> emoji_list = InputBarStyle.emoji_list;

  /// 分隔线颜色（日间模式）。
  static final Color divider_color_light = hexToColor("#E0E0E0");

  /// 分隔线颜色（夜间模式）。
  static final Color divider_color_dark = hexToColor("#2C2C2C");

  /// 空状态提示文字字号。
  static const double empty_font_size = 14;

  /// 空状态提示文字颜色。
  static final Color empty_text_color = hexToColor("#999999");

  /// 历史状态文字颜色（日间模式）。
  static final Color history_text_color_light = hexToColor("#A0A0A0");

  /// 历史状态文字颜色（夜间模式）。
  static final Color history_text_color_dark = hexToColor("#686868");

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

  /// 图片消息最大宽度比例。
  static const double image_max_width_ratio = 0.56;

  /// 图片消息最大宽度。
  static const double image_max_width = 240;

  /// 图片消息最大高度。
  static const double image_max_height = 300;

  /// 图片消息加载失败占位尺寸。
  static const double image_placeholder_size = 168;

  /// 图片消息圆角。
  static const double image_radius = 9;

  /// 时间分割线文字颜色。
  static final Color time_divider_color = hexToColor("#BBBBBB");

  /// 时间分割线文字字号。
  static const double time_divider_font_size = 11;
}
