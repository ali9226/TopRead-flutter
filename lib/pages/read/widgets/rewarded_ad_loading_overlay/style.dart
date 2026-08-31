import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

/// 激励视频等待层样式。
class RewardedAdLoadingOverlayStyle {
  RewardedAdLoadingOverlayStyle._();

  /// 透明遮罩颜色，保留阅读页上下文同时表明正在等待。
  static final Color barrier_color = Colors.black.withValues(alpha: 0.12);

  /// 转圈背景面板尺寸。
  static const double surface_size = 64;

  /// 转圈背景面板圆角。
  static const double surface_radius = 16;

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
