// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:app/config/layout_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/util/language_util/index.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

/// TODO 长篇与漫画共用顶部的颜色、点击区域、字号与弹性过渡参数。
class ReaderTopBarStyle {
  static const double target = LayoutConfig.touch_target_size;
  static const double icon = 22;
  static const double share_icon_size = 20;
  static const double spinner = 18;
  static const double stroke = 2;
  static const double horizontal_padding = LayoutConfig.space_8;
  static const double title_cjk = 14;
  static const double title_alphabetic = 13;
  static const double title_line_height = 1.3;
  static const double title_vertical_padding = LayoutConfig.space_12;
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
  static Color background(bool dark) => dark
      ? ColorConstants.components_reader_top_bar_style_tone
      : ColorConstants.whiteColor;
  static Color foreground(bool dark) => dark
      ? ColorConstants.whiteColor
      : ColorConstants.components_reader_top_bar_style_tone_ff1f1a12;
  static Color secondary(bool dark) => dark
      ? ColorConstants.components_reader_bottom_action_style_tone_b2ffffff
      : ColorConstants.components_reader_top_bar_style_tone_ff7a6a56;
  static Color share_icon_color(bool dark) => dark
      ? ColorConstants.components_fixed_bottom_navigation_style_tone_ffd0d4db
            .withValues(alpha: 0.82)
      : ColorConstants.components_cute_mascot_index_tone_ff1a1a1a;
  static Color border(bool dark) => dark
      ? ColorConstants.components_reader_top_bar_style_tone_ff21262d
      : ColorConstants.components_reader_top_bar_style_tone_ffeeeeee;
  static FontWeight get medium => FontConfig.adjustedWeight(FontWeight.w500);
}
