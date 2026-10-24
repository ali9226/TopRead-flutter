// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:app/config/layout_config.dart';
import 'package:app/components/work_section_card/style.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

/// 目录和推荐列表沿用同一白卡层级，以轻投影区分纯白底与卡片。
class CatalogCardStyle {
  const CatalogCardStyle._();
  static const Color sheet_light = ColorConstants.whiteColor;
  static const Color sheet_dark = ColorConstants.nightBackgroundColor;
  static const Color card_light = ColorConstants.whiteColor;
  static const Color card_dark = ColorConstants.night_popup_surface;
  static const double radius = LayoutConfig.card_radius;
  static const double padding_cjk = LayoutConfig.space_14;
  static const double padding_alphabetic = 12;
  static const double gap = LayoutConfig.space_8;
  static const double title_size_cjk = 17;
  static const double title_size_alphabetic = 15;
  static const double title_height_cjk = 1.4;
  static const double title_height_alphabetic = 1.35;
  static const double description_size_cjk = 15;
  static const double description_size_alphabetic = 13.5;
  static const double description_height = 1.5;
  static const double cover_width = 88;
  static const double cover_height = 66;
  static const double cover_radius = LayoutConfig.radius_8;
  static const double border_width = 1.5;
  static const double border_alpha = 0.3;
  static const double sheet_height_ratio = 0.9;
  static const double sheet_radius = LayoutConfig.radius_16;
  static const double list_padding = LayoutConfig.page_horizontal_padding;
  static const double list_gap = LayoutConfig.space_8;

  static Color sheet_background(bool dark) =>
      WorkSectionCardStyle.background(dark);
  static Color card_background(bool dark) =>
      WorkSectionCardStyle.card_background(dark);
}
