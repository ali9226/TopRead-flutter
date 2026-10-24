// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';

/// 漫画卡片通过细描边建立轮廓，单层低强度投影只补充纸面层次。
class ComicSurfaceStyle {
  const ComicSurfaceStyle._();

  static const double card_radius = LayoutConfig.radius_14;
  static const double border_width = 0.7;
  static const double selected_border_width = 1;
  static const double border_alpha_light = 0.07;
  static const double border_alpha_dark = 0.09;
  static const double selected_border_alpha = 0.45;
  static const double shadow_alpha = 0.035;
  static const double shadow_blur = 12;
  static const Offset shadow_offset = Offset(0, 3);

  static Color background(bool dark) =>
      dark ? ColorConstants.nightHighlightColor : ColorConstants.whiteColor;

  static BorderSide border(bool dark, {bool selected = false}) => BorderSide(
    color: selected
        ? ColorConstants.dangerColor.withValues(alpha: selected_border_alpha)
        : (dark ? ColorConstants.whiteColor : ColorConstants.lightTextColor)
              .withValues(alpha: dark ? border_alpha_dark : border_alpha_light),
    width: selected ? selected_border_width : border_width,
  );

  static List<BoxShadow> shadows(bool dark) => dark
      ? const []
      : [
          BoxShadow(
            color: ColorConstants.shadowColor.withValues(alpha: shadow_alpha),
            blurRadius: shadow_blur,
            offset: shadow_offset,
          ),
        ];
}
