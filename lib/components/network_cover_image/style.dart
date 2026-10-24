import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

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
  static const double error_icon_size = LayoutConfig.icon_medium;

  /// 默认错误占位文字字号。
  static const double error_text_font_size = 12;

  /// 错误占位图标与文字间距。
  static const double error_content_gap = LayoutConfig.space_6;

  /// 错误占位的图标透明度。
  static const double error_icon_opacity = 0.72;

  /// 错误占位的文字透明度。
  static const double error_text_opacity = 0.78;

  /// 日间主题骨架底色。
  static const Color light_skeleton_base_color = ColorConstants.cover_skeleton_light_base;

  /// 日间主题骨架高亮色。
  static const Color light_skeleton_highlight_color = ColorConstants.pages_short_story_read_widgets_full_appbar_tone_fff7f9fc;

  /// 夜间主题骨架底色。
  static const Color dark_skeleton_base_color = ColorConstants.cover_skeleton_dark_base;

  /// 夜间主题骨架高亮色。
  static const Color dark_skeleton_highlight_color = ColorConstants.pages_short_story_read_widgets_full_appbar_tone;

  /// 日间主题错误占位背景色。
  static const Color light_error_background_color = ColorConstants.cover_fallback_light_bg;

  /// 夜间主题错误占位背景色。
  static const Color dark_error_background_color = ColorConstants.pages_bookshelf_widgets_bookshelf_grid_content_tone;

  /// 日间主题错误占位前景色。
  static const Color light_error_foreground_color = ColorConstants.light_error_foreground_color_ff97a3b6;

  /// 夜间主题错误占位前景色。
  static const Color dark_error_foreground_color = ColorConstants.dark_error_foreground_color_ffadb9cb;
}
