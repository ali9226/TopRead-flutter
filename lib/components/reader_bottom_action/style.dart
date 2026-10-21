// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:app/config/font_config.dart';
import 'package:app/util/language_util/index.dart';
import 'package:flutter/material.dart';

/// TODO 三种阅读器共用操作行几何，安全区只在整行下方保留一次。
class ReaderBottomActionStyle {
  static const double row_min_height = 60;
  static const double target = 48;
  static const double icon_size = 22;
  static const double label_gap = 4;
  static const double label_font_size_cjk = 11;
  static const double label_font_size_alphabetic = 11;
  static const double label_line_height = 1.2;
  static const double vertical_padding = 8;
  static const double horizontal_padding = 4;
  static const double radius = 8;

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
      dark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF7A6A56);
  static FontWeight get label_weight =>
      FontConfig.adjustedWeight(FontWeight.w400);
}
