// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:flutter/material.dart';
import 'package:app/util/color_util.dart';
import 'package:app/config/font_config.dart';

/// 在线客服聊天弹窗样式常量。
class CustomerServiceSheetStyle {
    CustomerServiceSheetStyle._();

    /// 弹窗高度比例（屏幕高度的 90%）。
    static const double height_ratio = 0.9;

    /// 弹窗顶部圆角半径。
    static const double border_radius_top = 16;

    /// 弹窗顶部拖拽指示条的宽度。
    static const double drag_bar_width = 40;

    /// 弹窗顶部拖拽指示条的高度。
    static const double drag_bar_height = 4;

    /// 弹窗顶部拖拽指示条的圆角。
    static const double drag_bar_radius = 2;

    /// 拖拽指示条颜色（日间模式）。
    static final Color drag_bar_color_light = hexToColor("#E0E0E0");

    /// 拖拽指示条颜色（夜间模式）。
    static final Color drag_bar_color_dark = hexToColor("#3A3A4A");

    /// 弹窗背景色（日间模式）。
    static final Color background_color_light = hexToColor("#FFFFFF");

    /// 弹窗背景色（夜间模式）。
    static final Color background_color_dark = hexToColor("#1C1C2E");

    /// 顶部导航栏高度。
    static const double nav_bar_height = 52;

    /// 顶部导航栏标题字号。
    static final double nav_title_font_size_cjk = 17;
    static final double nav_title_font_size_alphabetic = 16;

    /// 顶部导航栏标题字重。
    static final FontWeight nav_title_font_weight = FontConfig.adjustedWeight(FontWeight.w600);

    /// 标题文字颜色（日间模式）。
    static final Color title_color_light = hexToColor("#222222");

    /// 标题文字颜色（夜间模式）。
    static final Color title_color_dark = hexToColor("#EEEEEE");

    /// 聊天列表背景色（日间模式）。
    static final Color chat_bg_color_light = hexToColor("#F5F5F5");

    /// 聊天列表背景色（夜间模式）。
    static final Color chat_bg_color_dark = hexToColor("#12121C");

    /// 消息气泡 - 用户发送背景色。
    static final Color bubble_user_bg = hexToColor("#FFD45A");

    /// 消息气泡 - 用户发送文字颜色。
    static final Color bubble_user_text = hexToColor("#222222");

    /// 消息气泡 - 管理员发送背景色（日间模式）。
    static final Color bubble_admin_bg_light = hexToColor("#FFFFFF");

    /// 消息气泡 - 管理员发送背景色（夜间模式）。
    static final Color bubble_admin_bg_dark = hexToColor("#2A2A3C");

    /// 消息气泡 - 管理员发送文字颜色（日间模式）。
    static final Color bubble_admin_text_light = hexToColor("#222222");

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
    static final FontWeight message_font_weight = FontConfig.adjustedWeight(FontWeight.w400);

    /// 时间戳文字字号。
    static const double time_font_size = 11;

    /// 时间戳文字颜色（日间模式）。
    static final Color time_color_light = hexToColor("#999999");

    /// 时间戳文字颜色（夜间模式）。
    static final Color time_color_dark = hexToColor("#666666");

    /// 消息间距。
    static const double message_spacing = 12;

    /// 头像尺寸。
    static const double avatar_size = 36;

    /// 头像圆角。
    static const double avatar_radius = 18;

    /// 头像与气泡间距。
    static const double avatar_bubble_spacing = 8;

    /// 输入栏高度。
    static const double input_bar_height = 56;

    /// 输入栏背景色（日间模式）。
    static final Color input_bar_bg_light = hexToColor("#F8F8F8");

    /// 输入栏背景色（夜间模式）。
    static final Color input_bar_bg_dark = hexToColor("#1A1A2A");

    /// 输入框背景色（日间模式）。
    static final Color input_field_bg_light = hexToColor("#FFFFFF");

    /// 输入框背景色（夜间模式）。
    static final Color input_field_bg_dark = hexToColor("#2A2A3C");

    /// 输入框文字颜色（日间模式）。
    static final Color input_text_color_light = hexToColor("#222222");

    /// 输入框文字颜色（夜间模式）。
    static final Color input_text_color_dark = hexToColor("#EEEEEE");

    /// 输入框提示文字颜色。
    static final Color input_hint_color = hexToColor("#999999");

    /// 输入框字号。
    static const double input_font_size = 15;

    /// 输入框圆角。
    static const double input_radius = 20;

    /// 发送按钮颜色。
    static final Color send_button_color = hexToColor("#FFD45A");

    /// 发送按钮文字颜色。
    static final Color send_button_text_color = hexToColor("#222222");

    /// 发送按钮字号。
    static const double send_button_font_size = 14;

    /// 功能按钮尺寸（表情、图片）。
    static const double tool_icon_size = 28;

    /// 功能按钮颜色（日间模式）。
    static final Color tool_icon_color_light = hexToColor("#666666");

    /// 功能按钮颜色（夜间模式）。
    static final Color tool_icon_color_dark = hexToColor("#999999");

    /// 表情面板高度。
    static const double emoji_panel_height = 240;

    /// 表情面板每行数量。
    static const int emoji_columns = 7;

    /// 表情面板背景色（日间模式）。
    static final Color emoji_panel_bg_light = hexToColor("#F8F8F8");

    /// 表情面板背景色（夜间模式）。
    static final Color emoji_panel_bg_dark = hexToColor("#1A1A2A");

    /// 预置表情列表。
    static const List<String> emoji_list = [
        '😀', '😂', '😍', '🤔', '😢', '😡', '👍',
        '👎', '❤️', '🎉', '🔥', '💯', '😊', '🙏',
        '😎', '🥺', '😤', '🤝', '💪', '✨', '🎊',
    ];

    /// 分隔线颜色（日间模式）。
    static final Color divider_color_light = hexToColor("#EEEEEE");

    /// 分隔线颜色（夜间模式）。
    static final Color divider_color_dark = hexToColor("#2A2A3C");

    /// 空状态提示文字字号。
    static const double empty_font_size = 14;

    /// 空状态提示文字颜色。
    static final Color empty_text_color = hexToColor("#999999");

    /// 加载指示器颜色。
    static final Color loading_color = hexToColor("#FFD45A");
}
