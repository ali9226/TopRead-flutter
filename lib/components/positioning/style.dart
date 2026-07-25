import 'package:flutter/material.dart';

/// 定位按钮样式常量。
class PositioningStyle {
  /// 按钮尺寸。
  static const double size = 44.0;

  /// 图标尺寸。
  static const double icon_size = 20.0;

  /// 圆角。
  static const double border_radius = 22.0;

  /// 阴影偏移。
  static const Offset shadow_offset = Offset(0, 2);

  /// 阴影模糊半径。
  static const double shadow_blur_radius = 8.0;

  /// 阴影扩散半径。
  static const double shadow_spread_radius = 0.0;

  /// 日间模式阴影颜色透明度。
  static const double shadow_opacity_light = 0.15;

  /// 夜间模式阴影颜色透明度。
  static const double shadow_opacity_dark = 0.3;

  /// 日间模式背景色。
  static const Color bg_light = Colors.white;

  /// 夜间模式背景色。
  static const Color bg_dark = Color(0xFF252836);

  /// 日间模式默认图标颜色。
  static const Color icon_color_light = Color(0xFF333333);

  /// 夜间模式默认图标颜色。
  static const Color icon_color_dark = Color(0xFFBBBBC0);

  /// 淡入淡出动画时长。
  static const Duration fade_duration = Duration(milliseconds: 200);
}
