// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:app/config/font_config.dart';
import 'package:app/util/language_util/index.dart';
import 'package:flutter/material.dart';

/// TODO 长篇与漫画共用顶部的颜色、点击区域、字号与弹性过渡参数。
class ReaderTopBarStyle {
  static const double target = 48;
  static const double icon = 22;
  static const double spinner = 18;
  static const double stroke = 2;
  static const double horizontal_padding = 8;
  static const double title_cjk = 14;
  static const double title_alphabetic = 13;
  static const double title_line_height = 1.3;
  static const double title_vertical_padding = 12;
  static const Duration elastic_duration = Duration(milliseconds: 400);
  static const Duration visibility_duration = Duration(milliseconds: 240);
  static const double elastic_begin = 0.6;

  static double title_size(BuildContext context) =>
      LanguageUtil.is_cjk_language(Localizations.localeOf(context).languageCode)
      ? title_cjk
      : title_alphabetic;
  static double toolbar_height(BuildContext context) =>
      (MediaQuery.textScalerOf(context).scale(title_size(context)) *
                  title_line_height +
              title_vertical_padding)
          .clamp(target, double.infinity);
  static bool reduce_motion(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ||
      MediaQuery.accessibleNavigationOf(context);
  static Color background(bool dark) =>
      dark ? const Color(0xFF161B22) : Colors.white;
  static Color foreground(bool dark) =>
      dark ? Colors.white : const Color(0xFF1F1A12);
  static Color secondary(bool dark) =>
      dark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF7A6A56);
  static Color border(bool dark) =>
      dark ? const Color(0xFF21262D) : const Color(0xFFEEEEEE);
  static FontWeight get medium => FontConfig.adjustedWeight(FontWeight.w500);
}
