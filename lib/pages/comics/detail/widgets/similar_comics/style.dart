// ignore_for_file: constant_identifier_names

import 'package:app/config/layout_config.dart';
import 'package:flutter/widgets.dart';

/// 同一行的推荐统一预留两行标题和一行作者，高度随系统字号变化。
class ComicSimilarComicsStyle {
  const ComicSimilarComicsStyle._();

  static const double font_size_cjk = 14;
  static const double font_size_alphabetic = 14;
  static const double line_height_cjk = 1.45;
  static const double line_height_alphabetic = 1.3;
  static const double card_width = 152;
  static const double cover_height = 152;
  static const int title_lines = 2;
  static const double card_padding = LayoutConfig.space_10;
  static const double card_gap = LayoutConfig.space_12;
  static const double horizontal_padding = LayoutConfig.page_horizontal_padding;
  static const double shadow_padding = LayoutConfig.space_12;
  static const double author_gap = LayoutConfig.space_6;
  static const double author_size_cjk = 11;
  static const double author_size_alphabetic = 11;
  static const double section_heading_gap = LayoutConfig.space_4;
  static const double font_metric_allowance = 2;
  static const int author_lines = 1;

  static double title_height(TextScaler scaler, bool cjk) =>
      scaler.scale(cjk ? font_size_cjk : font_size_alphabetic) *
          (cjk ? line_height_cjk : line_height_alphabetic) *
          title_lines +
      font_metric_allowance;

  static double author_height(TextScaler scaler, bool cjk) =>
      scaler.scale(cjk ? author_size_cjk : author_size_alphabetic) *
          (cjk ? line_height_cjk : line_height_alphabetic) +
      font_metric_allowance;

  static double card_height(TextScaler scaler, bool cjk) =>
      cover_height +
      card_padding * 2 +
      title_height(scaler, cjk) +
      author_gap +
      author_height(scaler, cjk);
}
