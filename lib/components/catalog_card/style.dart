// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';

/// TODO 目录卡片沿用短篇小说既有层级；日间底色来自 e0a41d9 之前的目录样式。
class CatalogCardStyle {
  const CatalogCardStyle._();
  static const Color sheet_light = Color(0xFFF6F7FB);
  static const Color sheet_dark = Color(0xFF12121C);
  static const Color card_light = Colors.white;
  static const Color card_dark = Color(0xFF1E2130);
  static const double radius = LayoutConfig.card_radius;
  static const double padding_cjk = 14;
  static const double padding_alphabetic = 12;
  static const double gap = 8;
  static const double title_size_cjk = 17;
  static const double title_size_alphabetic = 15;
  static const double title_height_cjk = 1.4;
  static const double title_height_alphabetic = 1.35;
  static const double description_size_cjk = 15;
  static const double description_size_alphabetic = 13.5;
  static const double description_height = 1.5;
  static const double cover_width = 88;
  static const double cover_height = 66;
  static const double cover_radius = 8;
  static const double border_width = 1.5;
  static const double border_alpha = 0.3;
  static const double sheet_height_ratio = 0.9;
  static const double sheet_radius = 16;
  static const double list_padding = LayoutConfig.page_horizontal_padding;
  static const double list_gap = 8;

  static Color sheet_background(bool dark) => dark ? sheet_dark : sheet_light;
  static Color card_background(bool dark) => dark ? card_dark : card_light;
}
