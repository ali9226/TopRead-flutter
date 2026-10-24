import 'package:app/config/layout_config.dart';
import 'package:app/components/work_hero_glass_surface/style.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';

/// 作品统计共用的暗蓝磨砂面板：清晰的整块表面与克制的数字层级。
class WorkHeroStatsStyle {
  const WorkHeroStatsStyle._();

  static const double radius = WorkHeroGlassSurfaceStyle.radius;
  static const double blur_sigma = WorkHeroGlassSurfaceStyle.blur_sigma;
  static const double surface_padding_h = LayoutConfig.space_6;
  static const double surface_padding_v = LayoutConfig.space_8;
  static const double surface_border_width =
      WorkHeroGlassSurfaceStyle.border_width;
  static const double highlight_height =
      WorkHeroGlassSurfaceStyle.highlight_height;
  static const double value_size_cjk = 16;
  static const double value_size_alphabetic = 16;
  static const double value_height_cjk = 1.25;
  static const double value_height_alphabetic = 1.25;
  static const double label_size_cjk = 11;
  static const double label_size_alphabetic = 10.5;
  static const double label_height_cjk = 1.3;
  static const double label_height_alphabetic = 1.35;
  static const double icon_label_gap = LayoutConfig.space_4;
  static const double icon_size = LayoutConfig.icon_small;
  static const double item_padding_h = LayoutConfig.space_4;
  static const double item_min_width = 60;
  static const double item_min_height = 40;
  static const double row_gap = LayoutConfig.space_8;
  static const double divider_width = 0.5;
  static const double layout_tolerance = 0.5;

  static final FontWeight value_weight = FontConfig.adjustedWeight(
    FontWeight.w500,
  );
  static final FontWeight label_weight = FontConfig.adjustedWeight(
    FontWeight.w400,
  );
  static final Color icon_color = ColorConstants.themeColor;

  static const List<BoxShadow> surface_shadows =
      WorkHeroGlassSurfaceStyle.shadows;

  static List<Color> surface_colors({
    required bool on_hero,
    required bool is_dark,
  }) => WorkHeroGlassSurfaceStyle.colors(on_hero: on_hero, is_dark: is_dark);

  static Color surface_border({required bool on_hero, required bool is_dark}) =>
      WorkHeroGlassSurfaceStyle.border(on_hero: on_hero, is_dark: is_dark);

  static List<Color> highlight_colors({
    required bool on_hero,
    required bool is_dark,
  }) => WorkHeroGlassSurfaceStyle.highlight(on_hero: on_hero, is_dark: is_dark);

  static Color value_color({required bool on_hero, required bool is_dark}) =>
      on_hero || is_dark
      ? ColorConstants.components_work_hero_stats_style_tone_fff6f6f8
      : ColorConstants.components_work_hero_stats_style_tone_ff202735;

  static Color label_color({required bool on_hero, required bool is_dark}) =>
      on_hero || is_dark
      ? ColorConstants.components_load_more_footer_index_tone_bfffffff
      : ColorConstants.components_work_hero_stats_style_tone_ff626d80;

  static Color divider_color({required bool on_hero, required bool is_dark}) =>
      on_hero || is_dark
      ? ColorConstants.components_work_hero_stats_style_tone_33ffffff
      : ColorConstants.components_work_hero_stats_style_tone_1f52617a;
}
