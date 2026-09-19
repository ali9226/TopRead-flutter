// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';

/// 评论操作弹窗样式常量。
class CommentActionsStyle {
  const CommentActionsStyle._();

  // ==================== 弹窗 ====================

  /// 弹窗顶部圆角。
  static const double sheet_radius = 14;

  /// 间隔区域高度。
  static const double spacer_height = 8;

  // ==================== 按钮 ====================

  /// 按钮垂直内边距。
  static const double button_vertical_padding = 14;

  /// 按钮字号（CJK 语系）。
  static const double button_font_size_cjk = 17;

  /// 按钮字号（字母语系）。
  static const double button_font_size_alphabetic = 16;

  /// 副标题字号（CJK 语系）。
  static const double subtitle_font_size_cjk = 12;

  /// 副标题字号（字母语系）。
  static const double subtitle_font_size_alphabetic = 11;

  /// 副标题与主标题间距。
  static const double subtitle_spacing = 2;

  // ==================== 分隔线 ====================

  /// 分隔线高度。
  static const double separator_height = 0.5;

  /// 分隔线透明度。
  static const double separator_opacity = 0.3;

  /// 分隔线圆角（按钮区域）。
  static const double button_radius = 12;

  // ==================== 颜色（日间） ====================

  /// 弹窗背景色（日间）。
  static const Color background_light = Colors.white;

  /// 间隔区域背景色（日间）。
  static const Color spacer_light = Color(0xFFF2F2F7);

  /// 分隔线颜色（日间）。
  static const Color separator_light = Color(0xFFD1D1D6);

  // ==================== 颜色（夜间） ====================

  /// 弹窗背景色（夜间）。
  static const Color background_dark = Color(0xFF1C1C1E);

  /// 间隔区域背景色（夜间）。
  static const Color spacer_dark = Color(0xFF000000);

  /// 分隔线颜色（夜间）。
  static const Color separator_dark = Color(0xFF38383A);

  /// 副标题颜色（日间/夜间通用）。
  static const Color subtitle_color = Color(0xFF8E8E93);

  /// 获取按钮文字样式。
  static TextStyle button_text_style({
    required bool is_cjk,
    required Color color,
  }) => TextStyle(
    fontSize: is_cjk ? button_font_size_cjk : button_font_size_alphabetic,
    fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
    color: color,
  );

  /// 获取副标题文字样式。
  static TextStyle subtitle_text_style({
    required bool is_cjk,
  }) => TextStyle(
    fontSize: is_cjk ? subtitle_font_size_cjk : subtitle_font_size_alphabetic,
    fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
    color: subtitle_color,
  );

  // ==================== 举报弹窗 ====================

  /// 举报弹窗水平内边距。
  static const double report_horizontal_padding = 20;

  /// 举报弹窗标题字号（CJK 语系）。
  static const double report_title_font_size_cjk = 18;

  /// 举报弹窗标题字号（字母语系）。
  static const double report_title_font_size_alphabetic = 17;

  /// 举报弹窗标题与标签间距。
  static const double report_title_spacing = 8;

  /// 举报弹窗提示文字字号（CJK 语系）。
  static const double report_hint_font_size_cjk = 13;

  /// 举报弹窗提示文字字号（字母语系）。
  static const double report_hint_font_size_alphabetic = 12;

  /// 举报弹窗提示与标签间距。
  static const double report_hint_spacing = 16;

  /// 举报弹窗标签间距。
  static const double report_chip_spacing = 10;

  /// 举报弹窗空状态内边距。
  static const double report_empty_padding = 24;

  /// 举报弹窗空状态字号。
  static const double report_empty_font_size = 14;

  /// 举报弹窗标签区域与按钮间距。
  static const double report_chips_button_spacing = 20;

  /// 举报弹窗按钮高度。
  static const double report_button_height = 48;

  /// 举报弹窗按钮圆角。
  static const double report_button_radius = 12;

  /// 举报弹窗计数字号。
  static const double report_count_font_size = 14;
}