// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:app/components/fixed_bottom_navigation/style.dart'
    as fixed_nav_style;
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';

/// 推荐组不加外部卡片；封面网格、标题与浅色操作条组成清晰的阅读节奏。
class NovelsTabStyle {
  static const int section_item_count = 6;
  static final double list_bottom_base =
      fixed_nav_style.Style.bar_height + LayoutConfig.space_40;
  static const double horizontal_padding = LayoutConfig.page_horizontal_padding;
  static const double first_section_top = LayoutConfig.space_16;
  static const double section_gap = LayoutConfig.space_28;
  static const double heading_gap = LayoutConfig.space_14;
  static const double heading_size_cjk = 18;
  static const double heading_size_alphabetic = 17;
  static const double heading_height_cjk = 1.35;
  static const double heading_height_alphabetic = 1.4;
  static const double actions_top_gap = LayoutConfig.space_16;
  static const double actions_radius = LayoutConfig.radius_18;
  static const double action_min_height = LayoutConfig.touch_target_size;
  static const double action_padding_h = LayoutConfig.space_12;
  static const double action_padding_v = LayoutConfig.space_10;
  static const double action_icon_size = 15;
  static const double action_icon_gap = LayoutConfig.space_6;
  static const double action_label_size_cjk = 12;
  static const double action_label_size_alphabetic = 12;
  static const double action_label_height = 1.35;
  static const double action_divider_width = 0.5;
  static const double action_divider_height = LayoutConfig.space_16;
  static const double loading_stroke_width = 1.5;
  static const double error_gap = LayoutConfig.space_8;
  static const double error_size_cjk = 12;
  static const double error_size_alphabetic = 11.5;
  static const int skeleton_section_count = 2;
  static const double skeleton_heading_width_cjk = 120;
  static const double skeleton_heading_width_alphabetic = 152;
  static const double skeleton_heading_height = 12;
  static const Duration batch_duration = Duration(milliseconds: 240);
  static const Duration scroll_to_top_duration = Duration(milliseconds: 300);
  static const ScrollPhysics list_scroll_physics =
      AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());
  static final FontWeight heading_weight = FontConfig.adjustedWeight(
    FontWeight.w500,
  );
  static final FontWeight action_weight = FontConfig.adjustedWeight(
    FontWeight.w400,
  );

  static Color actions_background(bool dark) =>
      (dark ? ColorConstants.whiteColor : ColorConstants.lightTextColor)
          .withValues(alpha: dark ? 0.065 : 0.035);
  static Color actions_foreground(bool dark) =>
      (dark ? ColorConstants.whiteColor : ColorConstants.lightTextColor)
          .withValues(alpha: dark ? 0.75 : 0.65);
  static Color actions_divider(bool dark) =>
      (dark ? ColorConstants.whiteColor : ColorConstants.lightTextColor)
          .withValues(alpha: dark ? 0.10 : 0.07);
}
