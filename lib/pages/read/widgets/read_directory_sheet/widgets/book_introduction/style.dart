import 'dart:math' as math;

import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';

/// TODO 目录详情使用连续纸面、轻量分类和自然段落，尺寸与主题集中管理。
class DirectoryBookIntroductionStyle {
  const DirectoryBookIntroductionStyle._();

  static const double content_max_width = 680;
  static const double horizontal_padding = LayoutConfig.space_24;
  static const double top_padding = LayoutConfig.space_24;
  static const double bottom_padding = LayoutConfig.space_40;
  static const double genres_heading_gap = LayoutConfig.space_12;
  static const double genres_bottom_gap = LayoutConfig.space_24;
  static const double section_gap = LayoutConfig.space_24;
  static const double heading_body_gap = LayoutConfig.space_12;
  static const double paragraph_gap = LayoutConfig.space_16;
  static const double divider_height = .5;
  static const double tag_spacing = LayoutConfig.space_8;
  static const double tag_run_spacing = LayoutConfig.space_8;
  static const double tag_padding_h = LayoutConfig.space_10;
  static const double tag_padding_v = LayoutConfig.space_6;
  static const double tag_radius = LayoutConfig.radius_8;
  static const double tag_border_width = .5;
  static const double genre_heading_size_cjk = 13;
  static const double genre_heading_size_alphabetic = 12.5;
  static const double genre_heading_height_cjk = 1.4;
  static const double genre_heading_height_alphabetic = 1.4;
  static const double heading_size_cjk = 18;
  static const double heading_size_alphabetic = 18;
  static const double heading_height_cjk = 1.35;
  static const double heading_height_alphabetic = 1.3;
  static const double body_size_cjk = 15;
  static const double body_size_alphabetic = 15;
  static const double body_height_cjk = 1.8;
  static const double body_height_alphabetic = 1.7;
  static const double tag_size_cjk = 12;
  static const double tag_size_alphabetic = 12;
  static const double tag_height_cjk = 1.35;
  static const double tag_height_alphabetic = 1.4;

  /// TODO 宽屏只限制可读行宽，仍由当前弹窗提供真实可用宽度。
  static EdgeInsets content_padding(double width) {
    final horizontal = math.max(
      horizontal_padding,
      (width - content_max_width) / 2,
    );
    return EdgeInsets.fromLTRB(
      horizontal,
      top_padding,
      horizontal,
      bottom_padding,
    );
  }

  static Color primary(bool dark) => dark
      ? ColorConstants.whiteColor.withValues(alpha: .92)
      : ColorConstants.lightTextColor;
  static Color body(bool dark) =>
      primary(dark).withValues(alpha: dark ? .8 : .82);
  static Color muted(bool dark) =>
      primary(dark).withValues(alpha: dark ? .56 : .55);
  static Color divider(bool dark) => primary(dark).withValues(alpha: .09);
  static Color tag_background(bool dark) =>
      ColorConstants.themeColor.withValues(alpha: dark ? .1 : .08);
  static Color tag_border(bool dark) =>
      ColorConstants.themeColor.withValues(alpha: dark ? .17 : .2);
  static Color tag_ink(bool dark) => dark
      ? Color.lerp(ColorConstants.themeColor, ColorConstants.whiteColor, .18)!
      : Color.lerp(
          ColorConstants.themeColor,
          ColorConstants.lightTextColor,
          .72,
        )!;

  static TextStyle genres_heading({required bool dark, required bool cjk}) =>
      TextStyle(
        color: muted(dark),
        fontSize: cjk ? genre_heading_size_cjk : genre_heading_size_alphabetic,
        height: cjk
            ? genre_heading_height_cjk
            : genre_heading_height_alphabetic,
        fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
      );
  static TextStyle heading({required bool dark, required bool cjk}) =>
      TextStyle(
        color: primary(dark),
        fontSize: cjk ? heading_size_cjk : heading_size_alphabetic,
        height: cjk ? heading_height_cjk : heading_height_alphabetic,
        fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
      );
  static TextStyle paragraph({
    required bool dark,
    required bool cjk,
    bool empty = false,
  }) => TextStyle(
    color: empty ? muted(dark) : body(dark),
    fontSize: cjk ? body_size_cjk : body_size_alphabetic,
    height: cjk ? body_height_cjk : body_height_alphabetic,
    fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
  );
  static TextStyle tag({required bool dark, required bool cjk}) => TextStyle(
    color: tag_ink(dark),
    fontSize: cjk ? tag_size_cjk : tag_size_alphabetic,
    height: cjk ? tag_height_cjk : tag_height_alphabetic,
    fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
  );
}
