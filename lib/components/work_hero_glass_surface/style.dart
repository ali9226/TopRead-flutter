import 'package:app/config/color_config.dart';
import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';

/// 作品封面区的通透磨砂外壳，供统计与短篇简介共用。
class WorkHeroGlassSurfaceStyle {
  const WorkHeroGlassSurfaceStyle._();

  static const double radius = LayoutConfig.radius_14;
  static const double blur_sigma = 11;
  static const double border_width = 0.6;
  static const double highlight_height = 1;
  static const List<BoxShadow> shadows = [
    BoxShadow(
      color: ColorConstants.shadow_soft_10,
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  /// 保留底图的色彩轮廓，玻璃自身不使用不透明填充。
  static List<Color> colors({required bool on_hero, required bool is_dark}) =>
      on_hero || is_dark
      ? const [
          ColorConstants.icon_color_24e8effa,
          ColorConstants.icon_color_24232c40,
          ColorConstants.icon_color_36121e32,
        ]
      : const [
          ColorConstants.components_back_to_top_button_style_tone_24ffffff,
          ColorConstants.icon_color_1fe7edf6,
          ColorConstants.icon_color_2be4ebf4,
        ];

  static Color border({required bool on_hero, required bool is_dark}) =>
      on_hero || is_dark
      ? ColorConstants.components_work_hero_stats_style_tone
      : ColorConstants.components_work_hero_stats_style_tone_3352617a;

  static List<Color> highlight({
    required bool on_hero,
    required bool is_dark,
  }) => on_hero || is_dark
      ? const [
          ColorConstants.transparent_white,
          ColorConstants.icon_color_52ffffff,
          ColorConstants.transparent_white,
        ]
      : const [
          ColorConstants.transparent_white,
          ColorConstants.util_dialog_show_upgrade_dialog_tone_80ffffff,
          ColorConstants.transparent_white,
        ];
}
