// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:app/config/layout_config.dart';
import 'package:app/config/color_config.dart';
import 'package:flutter/material.dart';

/// TODO 首页、小说和漫画共用的展示标签样式；筛选器仍保留自身选中态样式。
class ContentCategoryTagStyle {
  const ContentCategoryTagStyle._();

  static const double font_size_cjk = 11;
  static const double font_size_alphabetic = 11;
  static const double padding_h_cjk = LayoutConfig.space_8;
  static const double padding_h_alphabetic = 8;
  static const double padding_v = LayoutConfig.space_4;
  static const double radius = LayoutConfig.radius_pill;
  static const double line_height_cjk = 1.25;
  static const double line_height_alphabetic = 1.25;
  static const double background_alpha_light = 0.16;
  static const double background_alpha_dark = 0.18;
  static const double text_alpha = 0.96;
  static const double spacing = LayoutConfig.space_6;
  static const int content_color_factor = 7;
  static const int position_color_factor = 3;

  /// TODO 与首页/漫画列表保持稳定取色，作品刷新和详情切换不会随机换色。
  static Color color_for({required int content_id, required int index}) =>
      ColorConstants.resolveTagColor(
        content_id * content_color_factor + index * position_color_factor,
      );
}
