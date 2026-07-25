import 'package:flutter/material.dart';

/// 网络封面图片组件样式常量。
///
/// 该文件只负责管理网络封面图在加载中、加载失败时会复用到的样式参数，
/// 目的是避免在多个组件内部散落硬编码，后续统一调整动画节奏和视觉细节时更容易维护。
class NetworkCoverImageStyle {
  /// 骨架屏动画单次滑动时长。
  static const int skeleton_animation_duration_ms = 1200;

  /// 骨架屏渐变开始位置。
  static const Alignment skeleton_gradient_begin = Alignment(-1.6, -0.3);

  /// 骨架屏渐变结束位置。
  static const Alignment skeleton_gradient_end = Alignment(1.6, 0.3);

  /// 骨架屏高亮带的透明度停靠点。
  static const List<double> skeleton_gradient_stops = <double>[
    0.10,
    0.32,
    0.50,
    0.68,
    0.90,
  ];

  /// 默认错误占位图标尺寸。
  static const double error_icon_size = 20;

  /// 默认错误占位文字字号。
  static const double error_text_font_size = 12;

  /// 错误占位图标与文字间距。
  static const double error_content_gap = 6;

  /// 错误占位的图标透明度。
  static const double error_icon_opacity = 0.72;

  /// 错误占位的文字透明度。
  static const double error_text_opacity = 0.78;

  /// 日间主题骨架底色。
  static const Color light_skeleton_base_color = Color(0xFFE8ECF3);

  /// 日间主题骨架高亮色。
  static const Color light_skeleton_highlight_color = Color(0xFFF7F9FC);

  /// 夜间主题骨架底色。
  static const Color dark_skeleton_base_color = Color(0xFF232B39);

  /// 夜间主题骨架高亮色。
  static const Color dark_skeleton_highlight_color = Color(0xFF384356);

  /// 日间主题错误占位背景色。
  static const Color light_error_background_color = Color(0xFFF3F5F9);

  /// 夜间主题错误占位背景色。
  static const Color dark_error_background_color = Color(0xFF1A2130);

  /// 日间主题错误占位前景色。
  static const Color light_error_foreground_color = Color(0xFF97A3B6);

  /// 夜间主题错误占位前景色。
  static const Color dark_error_foreground_color = Color(0xFFADB9CB);
}
