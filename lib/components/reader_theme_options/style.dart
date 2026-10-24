// ignore_for_file: constant_identifier_names

import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

/// 小说与漫画统一使用的日夜胶囊规格。
class ReaderThemeOptionsStyle {
  static const double label_cjk = 15;
  static const double label_alphabetic = 14;
  static const double option_cjk = 13;
  static const double option_alphabetic = 13;
  static const double label_gap = LayoutConfig.space_16;
  static const double option_gap = LayoutConfig.space_10;
  static const double min_height = 36;
  static const double radius = LayoutConfig.radius_18;
  static const double border_width = 1.5;
  static const double padding = LayoutConfig.space_8;
  static const Color day_ink = ColorConstants.components_paragraph_comment_sheet_style_tone_ff333333;
  static const Color night_surface = ColorConstants.components_cute_mascot_index_tone_ff1a1a1a;
}
