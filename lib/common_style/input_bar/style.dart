import 'package:flutter/material.dart';

/// 输入栏共享样式常量。
///
/// 评论弹窗和在线客服页面共用的输入栏视觉参数。
/// 修改此文件会同时影响两个页面的输入栏外观。
class InputBarStyle {
  InputBarStyle._();

  // ==================== 输入栏整体 ====================

  /// 输入栏水平内边距。
  static const double padding_h = 8;

  /// 输入栏垂直内边距。
  static const double padding_v = 6;

  /// 输入栏背景色（日间模式），与评论面板背景色保持一致。
  static const Color bar_bg_light = Color(0xFFFFFFFF);

  /// 输入栏背景色（夜间模式），与评论面板背景色保持一致。
  static const Color bar_bg_dark = Color(0xFF191919);

  // ==================== 输入框 ====================

  /// 输入框高度（单行）。
  static const double field_height = 36;

  /// 输入框最大高度（多行展开时）。
  static const double field_max_height = 104;

  /// 输入框圆角半径。
  static const double field_radius = 20;

  /// 输入框背景色（日间模式），与回复区域背景色一致。
  static const Color field_bg_light = Color(0xFFF7F7F7);

  /// 输入框背景色（夜间模式），与回复区域背景色一致。
  static const Color field_bg_dark = Color(0xFF232323);

  /// 输入框字号（CJK 语系）。
  static const double font_size_cjk = 15;

  /// 输入框字号（字母语系）。
  static const double font_size_alphabetic = 14;

  /// 输入框内水平内边距。
  static const double inner_padding = 12;

  /// 输入框内垂直内边距（编辑模式下 TextField 的 contentPadding）。
  static const double content_vertical_padding = 9;

  /// 输入框文字行高。
  static const double text_line_height = 1.4;

  /// 输入框光标宽度。
  static const double cursor_width = 2;

  /// 输入框与右侧按钮的间距。
  static const double action_spacing = 8;

  // ==================== 发送按钮 ====================

  /// 发送按钮高度（与输入框等高）。
  static const double send_height = 36;

  /// 发送按钮最小宽度（CJK 语系）。
  static const double send_min_width_cjk = 52;

  /// 发送按钮最小宽度（字母语系）。
  static const double send_min_width_alphabetic = 64;

  /// 发送按钮圆角半径。
  static const double send_radius = 18;

  /// 发送按钮水平内边距。
  static const double send_padding_h = 12;

  /// 发送按钮字号（CJK 语系）。
  static const double send_font_size_cjk = 14;

  /// 发送按钮字号（字母语系）。
  static const double send_font_size_alphabetic = 13;

  /// 发送按钮禁用状态背景色（日间模式）。
  static const Color send_disabled_bg_light = Color(0xFFE8E8E8);

  /// 发送按钮禁用状态背景色（夜间模式）。
  static const Color send_disabled_bg_dark = Color(0xFF3A3A3A);

  /// 发送按钮禁用状态文字色（日间模式）。
  static const Color send_disabled_text_light = Color(0xFFB2B2B2);

  /// 发送按钮禁用状态文字色（夜间模式）。
  static const Color send_disabled_text_dark = Color(0xFF666666);

  // ==================== 功能按钮（表情、图片等） ====================

  /// 功能按钮点击区域尺寸。
  static const double tool_button_size = 40;

  /// 功能图标显示尺寸（表情、键盘、图片等）。
  static const double tool_icon_size = 28;

  // ==================== 表情面板 ====================

  /// 表情面板每行数量。
  static const int emoji_columns = 7;

  /// 表情面板背景色（日间模式）。
  static const Color emoji_panel_bg_light = Color(0xFFF5F5F5);

  /// 表情面板背景色（夜间模式）。
  static const Color emoji_panel_bg_dark = Color(0xFF1A1A2A);

  /// 预置表情列表。
  static const List<String> emoji_list = [
    '😀', '😂', '😍', '🤔', '😢', '😡', '👍',
    '👎', '❤️', '🎉', '🔥', '💯', '😊', '🙏',
    '😎', '🥺', '😤', '🤝', '💪', '✨', '🎊',
  ];
}
