import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';

/// 选文海报的排版预算；选文可扩高，语境只使用剩余空间。
class SelectionPosterStyle {
  const SelectionPosterStyle._();

  static const double maximum_height = 1600;
  static const double measurement_safety = 1;
  static const int context_character_limit = 600;
  static const int selection_working_limit = 4096;
  static const double selection_head_ratio = 0.6;
  static const double truncation_font_size = 10;
  static const double truncation_line_height = 1.3;
  static const double context_line_height_cjk = 1.58;
  static const double context_line_height_alphabetic = 1.42;
  static const String omission = '…';
  static const String paragraph_gap = '\n\n';

  static TextStyle context_style(TextStyle style) =>
      style.copyWith(fontWeight: FontConfig.adjustedWeight(FontWeight.w400));

  static TextStyle selected_style(TextStyle style) =>
      style.copyWith(fontWeight: FontConfig.adjustedWeight(FontWeight.w600));
}
