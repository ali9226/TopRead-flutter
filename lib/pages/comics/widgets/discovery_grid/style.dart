// ignore_for_file: non_constant_identifier_names

import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';

/// 首页六本分组与分类分页共用一套封面比例、单行字阶与网格节奏。
class ComicDiscoveryGridStyle {
  const ComicDiscoveryGridStyle._();

  static const double cover_ratio = 2 / 3;
  static const double cover_radius = LayoutConfig.radius_10;
  static const double column_gap = LayoutConfig.space_12;
  static const double row_gap = LayoutConfig.space_20;
  static const double title_gap = LayoutConfig.space_8;
  static const double category_gap = LayoutConfig.space_2;
  static const double title_size_cjk = 14;
  static const double title_size_alphabetic = 13;
  static const double title_height_cjk = 1.4;
  static const double title_height_alphabetic = 1.4;
  static const double category_size_cjk = 11;
  static const double category_size_alphabetic = 10.5;
  static const double category_height_cjk = 1.4;
  static const double category_height_alphabetic = 1.4;
  static const double metric_allowance = 2;
  static const double section_wide_width = 680;
  static const double catalog_min_card_width = 112;
  static const int phone_columns = 3;
  static const int wide_columns = 6;

  static int columns(double width, {required bool section}) => section
      ? (width >= section_wide_width ? wide_columns : phone_columns)
      : (width / catalog_min_card_width).floor().clamp(
          phone_columns,
          wide_columns,
        );

  static double title_extent(TextScaler scaler, bool cjk) =>
      scaler.scale(cjk ? title_size_cjk : title_size_alphabetic) *
          (cjk ? title_height_cjk : title_height_alphabetic) +
      metric_allowance;

  static double category_extent(TextScaler scaler, bool cjk) =>
      scaler.scale(cjk ? category_size_cjk : category_size_alphabetic) *
          (cjk ? category_height_cjk : category_height_alphabetic) +
      metric_allowance;

  static double item_height(double width, TextScaler scaler, bool cjk) =>
      width / cover_ratio +
      title_gap +
      title_extent(scaler, cjk) +
      category_gap +
      category_extent(scaler, cjk);
}
