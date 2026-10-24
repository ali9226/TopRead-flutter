// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:app/config/layout_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/util/language_util/index.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

/// TODO 三种阅读器共用操作行几何，安全区只在整行下方保留一次。
class ReaderBottomActionStyle {
  static const double row_min_height = 60;
  static const double target = LayoutConfig.touch_target_size;
  static const double icon_size = LayoutConfig.icon_compact;
  static const double label_gap = LayoutConfig.space_4;
  static const double label_font_size_cjk = 11;
  static const double label_font_size_alphabetic = 11;
  static const double label_line_height = 1.2;
  static const double vertical_padding = LayoutConfig.space_8;
  static const double horizontal_padding = LayoutConfig.space_4;
  static const double radius = LayoutConfig.radius_8;

  static double label_size(BuildContext context) =>
      LanguageUtil.is_cjk_language(Localizations.localeOf(context).languageCode)
      ? label_font_size_cjk
      : label_font_size_alphabetic;
  static double row_height(BuildContext context) =>
      (vertical_padding * 2 +
              icon_size +
              label_gap +
              MediaQuery.textScalerOf(context).scale(label_size(context)) *
                  label_line_height)
          .clamp(row_min_height, double.infinity);
  static double safe_bottom(BuildContext context) =>
      MediaQuery.viewPaddingOf(context).bottom;
  static Color foreground(bool dark) =>
      dark ? ColorConstants.components_reader_bottom_action_style_tone_b2ffffff : ColorConstants.components_reader_top_bar_style_tone_ff7a6a56;
  static FontWeight get label_weight =>
      FontConfig.adjustedWeight(FontWeight.w400);
}
