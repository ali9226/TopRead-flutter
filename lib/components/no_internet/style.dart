import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

/// 无网络状态组件样式常量。
///
/// 统一管理无网络提示组件的字号、间距、尺寸等视觉参数。
class NoInternetStyle {
  // ==================== 图标 ====================

  /// 无网络图标尺寸。
  static const double icon_size = 140;

  /// 图标底部间距。
  static const double icon_bottom_spacing = LayoutConfig.space_16;

  // ==================== 文字 ====================

  /// 标题字号（CJK 语系）。
  static const double title_font_size_cjk = 18;

  /// 标题字号（非 CJK 语系）。
  static const double title_font_size_alphabetic = 16;

  /// 标题底部间距。
  static const double title_bottom_spacing = LayoutConfig.space_10;

  /// 描述字号（CJK 语系）。
  static const double desc_font_size_cjk = 14;

  /// 描述字号（非 CJK 语系）。
  static const double desc_font_size_alphabetic = 13;

  /// 描述文字行高。
  static const double desc_height = 1.5;

  /// 描述文字水平内边距。
  static const double desc_horizontal_padding = LayoutConfig.space_40;

  // ==================== 颜色 - 日间模式 ====================

  /// 图标着色（日间模式）。
  static const Color icon_light_color = ColorConstants.components_load_more_footer_index_tone_ffbbbbbb;

  /// 标题文字颜色（日间模式）。
  static const Color title_light_color = ColorConstants.components_paragraph_comment_sheet_style_tone_ff333333;

  /// 描述文字颜色（日间模式）。
  static const Color desc_light_color = ColorConstants.customer_service_sheet_style_time_color_light;

  // ==================== 颜色 - 夜间模式 ====================

  /// 图标着色（夜间模式）。
  static const Color icon_dark_color = ColorConstants.icon_dark_color_ff555555;

  /// 标题文字颜色（夜间模式）。
  static const Color title_dark_color = ColorConstants.components_category_filter_filter_popup_tone;

  /// 描述文字颜色（夜间模式）。
  static const Color desc_dark_color = ColorConstants.components_no_internet_cute_no_internet_cloud_tone_ff8b8b9e;

  // ==================== 动画 ====================

  /// 点击缩放动画时长。
  static const Duration tap_animation_duration = Duration(milliseconds: 120);

  /// 点击缩放比例。
  static const double tap_scale = 0.96;
}
