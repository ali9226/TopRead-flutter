// ignore_for_file: constant_identifier_names
import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

/// 调试样式独立于游戏视觉，生产构建不会创建调试组件。
class QuestLayoutDebugStyle {
  static const double button_extent = LayoutConfig.compact_control_height;
  static const double icon_size = 18;
  static const double inset = LayoutConfig.space_4;
  static const double panel_width = 260;
  static const double panel_padding = LayoutConfig.space_8;
  static const double radius = LayoutConfig.radius_8;
  static const double stats_size = 10;
  static const double tile_size = 7;
  static const double line_height = 1.3;
  static const double stroke_width = .8;
  static const Color panel_color = ColorConstants.panel_color_dd091628;
  static const Color blocked_color = ColorConstants.blocked_color_ffffae7c;
  static const Color open_color = ColorConstants.open_color_ff7cffce;
}
