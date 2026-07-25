import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';

/// 阅读进度文本样式常量
class ProgressTextStyle {
  /// 进度条上方渐变区域高度
  static const double gradient_height = 40;

  /// 进度条容器高度
  static const double container_height = 30;

  /// 进度条容器底部安全区域补偿
  static const double container_bottom_inset = 0;

  /// 进度条文字左侧边距
  static const double text_left_spacing = 30;

  /// 进度条文字底部外边距
  static const double text_bottom_spacing = 10;

  /// 进度文字字号
  static const double font_size = 12;

  /// 进度文字字重
  static final FontWeight font_weight = FontConfig.adjustedWeight(
    FontWeight.w400,
  );

  /// 进度文字阴影模糊半径
  static const double shadow_blur_radius = 6;

  /// 进度文字阴影垂直偏移
  static const Offset shadow_offset = Offset(0, 1);

  /// 进度文字区域淡入淡出时长（毫秒）
  static const int opacity_animation_duration_ms = 220;

  /// 进度文字在夜间主题下的透明度
  static const double text_night_alpha = 0.92;

  /// 进度文字在日间主题下的透明度
  static const double text_light_alpha = 0.92;

  /// 阴影在夜间主题下的透明度
  static const double shadow_night_alpha = 0.45;

  /// 阴影在日间主题下的透明度
  static const double shadow_light_alpha = 0.12;

  /// 渐变透明端的 alpha
  static const double gradient_transparent_alpha = 0;

  /// 进度条文字右侧边距
  static const double reading_progress_right_spacing = 16;
}
