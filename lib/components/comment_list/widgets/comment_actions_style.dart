// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:app/config/layout_config.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';

/// 评论操作弹窗样式常量。
class CommentActionsStyle {
  const CommentActionsStyle._();

  // ==================== 弹窗 ====================

  /// 弹窗顶部圆角。
  static const double sheet_radius = LayoutConfig.radius_14;

  /// 间隔区域高度。
  static const double spacer_height = 8;

  // ==================== 按钮 ====================

  /// 按钮垂直内边距。
  static const double button_vertical_padding = LayoutConfig.space_14;

  /// 按钮字号（CJK 语系）。
  static const double button_font_size_cjk = 17;

  /// 按钮字号（字母语系）。
  static const double button_font_size_alphabetic = 16;

  /// 副标题字号（CJK 语系）。
  static const double subtitle_font_size_cjk = 12;

  /// 副标题字号（字母语系）。
  static const double subtitle_font_size_alphabetic = 11;

  /// 副标题与主标题间距。
  static const double subtitle_spacing = LayoutConfig.space_2;

  // ==================== 分隔线 ====================

  /// 分隔线高度。
  static const double separator_height = 0.5;

  /// 分隔线透明度。
  static const double separator_opacity = 0.3;

  /// 分隔线圆角（按钮区域）。
  static const double button_radius = LayoutConfig.radius_12;

  // ==================== 颜色（日间） ====================

  /// 弹窗背景色（日间）。
  static Color get background_light => ColorConstants.sheetBackground(false);

  /// 间隔区域背景色（日间）。
  static const Color spacer_light = ColorConstants.spacer_light_fff2f2f7;

  /// 分隔线颜色（日间）。
  static const Color separator_light = ColorConstants.separator_light_ffd1d1d6;

  // ==================== 颜色（夜间） ====================

  /// 弹窗背景色（夜间）。
  static Color get background_dark => ColorConstants.sheetBackground(true);

  /// 间隔区域背景色（夜间）。
  static const Color spacer_dark = ColorConstants.lightTextColor;

  /// 分隔线颜色（夜间）。
  static const Color separator_dark = ColorConstants.separator_dark_ff38383a;

  /// 副标题颜色（日间/夜间通用）。
  static const Color subtitle_color = ColorConstants.subtitle_color_ff8e8e93;

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
  static TextStyle subtitle_text_style({required bool is_cjk}) => TextStyle(
    fontSize: is_cjk ? subtitle_font_size_cjk : subtitle_font_size_alphabetic,
    fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
    color: subtitle_color,
  );

  // ==================== 举报弹窗 ====================

  /// 举报弹窗水平内边距。
  static const double report_horizontal_padding = LayoutConfig.space_20;

  /// 举报弹窗标题字号（CJK 语系）。
  static const double report_title_font_size_cjk = 18;

  /// 举报弹窗标题字号（字母语系）。
  static const double report_title_font_size_alphabetic = 17;

  /// 举报弹窗标题与标签间距。
  static const double report_title_spacing = LayoutConfig.space_8;

  /// 举报弹窗提示文字字号（CJK 语系）。
  static const double report_hint_font_size_cjk = 13;

  /// 举报弹窗提示文字字号（字母语系）。
  static const double report_hint_font_size_alphabetic = 12;

  /// 举报弹窗提示与标签间距。
  static const double report_hint_spacing = LayoutConfig.space_16;

  /// 举报弹窗标签间距。
  static const double report_chip_spacing = LayoutConfig.space_10;

  /// 举报弹窗空状态内边距。
  static const double report_empty_padding = LayoutConfig.space_24;

  /// 举报弹窗空状态字号。
  static const double report_empty_font_size = 14;

  /// 举报弹窗标签区域与按钮间距。
  static const double report_chips_button_spacing = LayoutConfig.space_20;

  /// 举报弹窗按钮高度。
  static const double report_button_height = LayoutConfig.button_height;

  /// 举报弹窗按钮圆角。
  static const double report_button_radius = LayoutConfig.radius_12;

  /// 举报弹窗计数字号。
  static const double report_count_font_size = 14;
}
