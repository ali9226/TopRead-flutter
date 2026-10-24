// ignore_for_file: constant_identifier_names

import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

/// TODO 漫画阅读弹窗沿用小说的白/深灰面板、金色交互与底部拖动条。
class ComicReadingPanelStyle {
  const ComicReadingPanelStyle._();
  static const double radius = LayoutConfig.radius_16;
  static const double padding = LayoutConfig.space_20;
  static const double gap = LayoutConfig.space_16;
  static const double section_gap = LayoutConfig.space_24;
  static const double title_cjk = 18;
  static const double title_alphabetic = 17;
  static const double text_cjk = 15;
  static const double text_alphabetic = 14;
  static const double max_height_ratio = 0.88;
  static const double max_width = 600;
  static const double brightness_min = 0.01;
  static const double brightness_small_icon = 16;
  static const double brightness_large_icon = 24;
  static const double target_height = 48;
  static const Color light_background = ColorConstants.whiteColor;
  static const Color dark_background = ColorConstants.components_reader_top_bar_style_tone;
  static const Color light_ink = ColorConstants.components_reader_top_bar_style_tone_ff1f1a12;
  static const Color light_muted = ColorConstants.components_reader_top_bar_style_tone_ff7a6a56;
}
