import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

/// 激励视频等待层样式。
class RewardedAdLoadingOverlayStyle {
  RewardedAdLoadingOverlayStyle._();

  /// 透明遮罩颜色，保留阅读页上下文同时表明正在等待。
  static final Color barrier_color = ColorConstants.util_dialog_show_bottom_tip_tone_1f222222;

  /// 转圈背景面板尺寸。
  static const double surface_size = 64;

  /// 转圈背景面板圆角。
  static const double surface_radius = LayoutConfig.radius_16;

  /// 转圈尺寸。
  static const double indicator_size = 28;

  /// 转圈线条宽度。
  static const double indicator_stroke_width = 2.6;

  /// 日间模式转圈面板颜色。
  static final Color surface_color_light = ColorConstants.whiteColor;

  /// 夜间模式转圈面板颜色。
  static final Color surface_color_dark = ColorConstants.backgroundColor;

  /// 转圈颜色。
  static final Color indicator_color = ColorConstants.themeColor;
}
