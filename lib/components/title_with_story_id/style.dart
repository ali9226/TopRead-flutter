import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';

/// 标题 + 小说 ID 徽标组件样式常量。
///
/// 统一管理胶囊徽标尺寸、双色文字层级、发丝描边、按压反馈与复制成功反馈，
/// 避免魔法数字散落各处。
class TitleWithStoryIdStyle {
  /// 徽标左侧与标题文字的间距。
  static const double badge_left_spacing = LayoutConfig.space_6;

  /// 徽标水平内边距（胶囊左右留白）。
  static const double badge_padding_horizontal = LayoutConfig.space_8;

  /// 徽标垂直内边距（胶囊上下留白）。
  static const double badge_padding_vertical = 3.5;

  /// 徽标圆角（取大值形成胶囊形，视觉更轻盈现代）。
  static const double badge_border_radius = LayoutConfig.radius_pill;

  /// 徽标描边宽度（接近发丝线的细描边）。
  static const double badge_border_width = 1;

  /// 静息态描边透明度（极弱，只勾勒轮廓不抢标题）。
  static const double badge_border_alpha = 0.14;

  /// 按压态描边透明度（加深以强化按压反馈）。
  static const double badge_pressed_border_alpha = 0.22;

  /// 静息态背景透明度（若隐若现的轻填充）。
  static const double badge_background_alpha = 0.06;

  /// 按压态背景透明度（加深以强化按压反馈）。
  static const double badge_pressed_background_alpha = 0.12;

  /// "ID" 前缀文字透明度（弱化为标签层级）。
  static const double badge_prefix_alpha = 0.45;

  /// ID 数字文字透明度（比前缀更实，保证一眼可读）。
  static const double badge_number_alpha = 0.8;

  /// 图标透明度（弱化为辅助层级）。
  static const double badge_icon_alpha = 0.4;

  /// 分隔线透明度。
  static const double badge_divider_alpha = 0.12;

  /// 分隔线宽度。
  static const double badge_divider_width = 1;

  /// 分隔线高度。
  static const double badge_divider_height = 10;

  /// "ID" 前缀字号（CJK 语系）。
  static const double badge_prefix_font_size_cjk = 10;

  /// "ID" 前缀字号（拉丁语系）。
  static const double badge_prefix_font_size_alphabetic = 9.5;

  /// ID 数字字号（CJK 语系）。
  static const double badge_number_font_size_cjk = 11;

  /// ID 数字字号（拉丁语系）。
  static const double badge_number_font_size_alphabetic = 10.5;

  /// "ID" 前缀与数字之间的间距。
  static const double badge_prefix_spacing = LayoutConfig.space_3;

  /// 数字与分隔线、分隔线与图标之间的间距。
  static const double badge_divider_spacing = LayoutConfig.space_4;

  /// 图标尺寸。
  static const double badge_icon_size = 12;

  /// "ID" 前缀字距（轻微拉开，增强标签感）。
  static const double badge_prefix_letter_spacing = 0.4;

  /// ID 数字字距（轻微拉开，避免数字粘连）。
  static const double badge_number_letter_spacing = 0.2;

  /// "ID" 前缀字重。
  static final FontWeight badge_prefix_font_weight = FontConfig.adjustedWeight(FontWeight.w500);

  /// ID 数字字重（比前缀重一档，形成主次层级）。
  static final FontWeight badge_number_font_weight = FontConfig.adjustedWeight(FontWeight.w600);

  /// 按压时的整体缩放比例（模拟 iOS 轻按回弹）。
  static const double pressed_scale = 0.94;

  /// 按压缩放动画时长。
  static const Duration press_duration = Duration(milliseconds: 90);

  /// 背景/描边颜色过渡动画时长。
  static const Duration color_animation_duration = Duration(milliseconds: 160);

  /// 复制成功图标切换动画时长。
  static const Duration icon_switch_duration = Duration(milliseconds: 180);

  /// 复制成功后成功图标停留时长，随后回退为复制图标。
  static const Duration copied_state_duration = Duration(milliseconds: 1400);

  /// 复制成功图标颜色（成功绿，对应 ColorConstants.successColor）。
  static final Color copied_icon_color = ColorConstants.successColor;

  /// 替换封面按钮左侧间距。
  static const double replace_button_left_spacing = LayoutConfig.space_6;

  /// 替换封面按钮水平内边距。
  static const double replace_button_padding_horizontal = LayoutConfig.space_8;

  /// 替换封面按钮垂直内边距。
  static const double replace_button_padding_vertical = 3.5;

  /// 替换封面按钮圆角（胶囊形）。
  static const double replace_button_border_radius = LayoutConfig.radius_pill;

  /// 替换封面按钮描边宽度。
  static const double replace_button_border_width = 1;

  /// 替换封面按钮静息态描边透明度。
  static const double replace_button_border_alpha = 0.18;

  /// 替换封面按钮按压态描边透明度。
  static const double replace_button_pressed_border_alpha = 0.28;

  /// 替换封面按钮静息态背景透明度。
  static const double replace_button_background_alpha = 0.1;

  /// 替换封面按钮按压态背景透明度。
  static const double replace_button_pressed_background_alpha = 0.18;

  /// 替换封面按钮文字/图标透明度。
  static const double replace_button_content_alpha = 0.7;

  /// 替换封面按钮字号。
  static const double replace_button_font_size = 11;

  /// 替换封面按钮字距。
  static const double replace_button_letter_spacing = 0.2;

  /// 替换封面按钮字重。
  static final FontWeight replace_button_font_weight =
      FontConfig.adjustedWeight(FontWeight.w500);

  /// 替换封面按钮图标尺寸。
  static const double replace_button_icon_size = 12;

  /// 替换封面按钮图标与文字间距。
  static const double replace_button_icon_spacing = LayoutConfig.space_3;

  /// 替换封面按钮加载圈线宽。
  static const double replace_button_loading_stroke_width = 1.5;
}
