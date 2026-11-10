import 'package:app/config/color_config.dart';
import 'package:app/components/work_introduction_hero/style.dart';
import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';

/// TODO 目录封面 Hero 的尺寸、字号与遮罩，短视口仅保留核心作品信息。
class BookDetailHeaderStyle {
  const BookDetailHeaderStyle._();

  static const double compact_viewport_height = 500;
  static const double horizontal_padding = LayoutConfig.space_20;
  static const double compact_horizontal_padding = LayoutConfig.space_16;
  static const double top_padding = LayoutConfig.space_8;
  static const double bottom_padding = LayoutConfig.space_20;
  static const double compact_bottom_padding = LayoutConfig.space_12;
  static const double cover_width = 84;
  static const double cover_height = 116;
  static const double compact_cover_width = 48;
  static const double compact_cover_height = 66;
  static const double cover_radius = LayoutConfig.radius_10;
  static const double cover_border_width = 1;
  static const double cover_gap = LayoutConfig.space_16;
  static const double compact_cover_gap = LayoutConfig.space_12;
  static const double title_size_cjk = 22;
  static const double title_size_alphabetic = 22;
  static const double compact_title_size_cjk = 17;
  static const double compact_title_size_alphabetic = 17;
  static const double title_height_cjk = 1.22;
  static const double title_height_alphabetic = 1.16;
  static const int title_lines = 2;
  static const int compact_title_lines = 1;
  static const double subtitle_size_cjk = 13;
  static const double subtitle_size_alphabetic = 12.5;
  static const double subtitle_height_cjk = 1.35;
  static const double subtitle_height_alphabetic = 1.35;
  static const double subtitle_gap = LayoutConfig.space_4;
  static const double author_gap = LayoutConfig.space_6;
  static const double author_icon_size = 13;
  static const double author_min_width = 44;
  static const double follow_font_size_cjk = 11;
  static const double follow_font_size_alphabetic = 10.5;
  static const double follow_padding_h = LayoutConfig.space_8;
  static const double follow_padding_v = LayoutConfig.space_4;
  static const double follow_target_height = 28;
  static const double follow_border_width = .6;
  static const double metadata_gap = LayoutConfig.space_8;
  static const double compact_metadata_gap = LayoutConfig.space_4;
  static const double token_spacing = LayoutConfig.space_10;
  static const double token_run_spacing = LayoutConfig.space_6;
  static const double token_icon_size = 13;
  static const double token_icon_gap = LayoutConfig.space_4;
  static const double metadata_size_cjk = 11;
  static const double metadata_size_alphabetic = 10.5;
  static const double metadata_line_height = 1.25;
  static const double status_padding_h = LayoutConfig.space_7;
  static const double status_padding_v = LayoutConfig.space_3;
  static const double status_radius = LayoutConfig.radius_pill;
  static const double statistics_gap = LayoutConfig.space_14;
  static const double compact_statistics_gap = LayoutConfig.space_6;
  static const double statistics_padding_h = LayoutConfig.space_4;
  static const double statistics_padding_v = LayoutConfig.space_10;
  static const double compact_statistics_padding_v = LayoutConfig.space_5;
  static const double statistic_value_size_cjk = 19;
  static const double statistic_value_size_alphabetic = 19;
  static const double compact_statistic_value_size_cjk = 13;
  static const double compact_statistic_value_size_alphabetic = 13;
  static const double statistic_label_size_cjk = 10.5;
  static const double statistic_label_size_alphabetic = 10;
  static const double statistic_line_height = 1.2;
  static const double statistic_label_height = 1.3;
  static const double statistic_icon_size = 18;
  static const double compact_statistic_icon_size = 13;
  static const double statistic_icon_gap = LayoutConfig.space_4;
  static const double statistic_label_gap = LayoutConfig.space_3;
  static const double statistic_min_width = 65;
  static const double compact_statistic_min_width = 45;
  static const double statistic_item_padding = LayoutConfig.space_6;
  static const double statistic_row_gap = LayoutConfig.space_8;
  static const double statistic_divider_width = .5;
  static const double layout_tolerance = .1;
  static const Color ink = ColorConstants.whiteColor;
  static const Color accent = ColorConstants.themeColor;
  static const Color status_ink = ColorConstants.lightTextColor;
  static const Color background = WorkIntroductionHeroStyle.poster_background;
  static const double cover_border_opacity = .65;
  static const double follow_surface_opacity = .06;
  static const double follow_border_opacity = .18;
  static const double statistic_divider_opacity = .2;
  static const Color muted_ink =
      ColorConstants.components_load_more_footer_index_tone_bfffffff;
  static const List<BoxShadow> cover_shadows = [
    BoxShadow(
      color: ColorConstants.shadow_medium_33,
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];
  static const List<Shadow> title_shadows =
      WorkIntroductionHeroStyle.title_shadows;
}
