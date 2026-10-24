import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

/// 顶部返回按钮组件样式常量。
class BackButtonStyle {
  /// 按钮总点击区域尺寸。
  static const double button_size = LayoutConfig.compact_control_height;

  /// 背景圆圈的尺寸。
  static const double circle_size = 32;

  /// 图标尺寸。
  static const double icon_size = 18;

  /// 背景在夜间模式下的不透明度。
  static const double night_background_opacity = 0.15;

  /// 背景在日间模式下的不透明度。
  static const double light_background_opacity = 0.06;

  /// 图标在夜间模式下的颜色。
  static const Color night_icon_color = ColorConstants.whiteColor;

  /// 图标在日间模式下的颜色。
  static const Color light_icon_color = ColorConstants.pages_short_story_read_widgets_bottom_comment_bar_tone;
}
