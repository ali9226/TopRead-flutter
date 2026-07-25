import 'package:flutter/material.dart';

/// 无网络状态组件样式常量。
///
/// 统一管理无网络提示组件的字号、间距、尺寸等视觉参数。
class NoInternetStyle {
  // ==================== 图标 ====================

  /// 无网络图标尺寸。
  static const double icon_size = 140;

  /// 图标底部间距。
  static const double icon_bottom_spacing = 16;

  // ==================== 文字 ====================

  /// 标题字号（CJK 语系）。
  static const double title_font_size_cjk = 18;

  /// 标题字号（非 CJK 语系）。
  static const double title_font_size_alphabetic = 16;

  /// 标题底部间距。
  static const double title_bottom_spacing = 10;

  /// 描述字号（CJK 语系）。
  static const double desc_font_size_cjk = 14;

  /// 描述字号（非 CJK 语系）。
  static const double desc_font_size_alphabetic = 13;

  /// 描述文字行高。
  static const double desc_height = 1.5;

  /// 描述文字水平内边距。
  static const double desc_horizontal_padding = 40;

  // ==================== 颜色 - 日间模式 ====================

  /// 图标着色（日间模式）。
  static const Color icon_light_color = Color(0xFFBBBBBB);

  /// 标题文字颜色（日间模式）。
  static const Color title_light_color = Color(0xFF333333);

  /// 描述文字颜色（日间模式）。
  static const Color desc_light_color = Color(0xFF999999);

  // ==================== 颜色 - 夜间模式 ====================

  /// 图标着色（夜间模式）。
  static const Color icon_dark_color = Color(0xFF555555);

  /// 标题文字颜色（夜间模式）。
  static const Color title_dark_color = Color(0xFFE8E8EA);

  /// 描述文字颜色（夜间模式）。
  static const Color desc_dark_color = Color(0xFF8B8B9E);

  // ==================== 动画 ====================

  /// 点击缩放动画时长。
  static const Duration tap_animation_duration = Duration(milliseconds: 120);

  /// 点击缩放比例。
  static const double tap_scale = 0.96;
}
