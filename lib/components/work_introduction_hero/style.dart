import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

/// 三类作品详情的自然流式封面、信息及安全区尺寸。
class WorkIntroductionHeroStyle {
  const WorkIntroductionHeroStyle._();
  static const double max_content_width = 720;
  static const double horizontal_padding = LayoutConfig.page_horizontal_padding;
  static const double cover_width_ratio = 0.32;
  static const double cover_max_width = 132;
  static const double cover_width_to_height = 2 / 3;
  static const double cover_radius = LayoutConfig.radius_10;
  static const Color cover_border =
      ColorConstants.components_load_more_footer_index_tone;
  static const List<BoxShadow> cover_shadows = [
    BoxShadow(
      color: ColorConstants.shadow_medium_33,
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];
  static const double status_margin = LayoutConfig.space_6;
  static const double status_padding_h = LayoutConfig.space_5;
  static const double status_padding_v = LayoutConfig.space_2;
  static const double status_radius = LayoutConfig.radius_6;
  static const double status_size_cjk = 10;
  static const double status_size_alphabetic = 10;
  static const double status_line_height = 1.2;
  static const Color status_ink = ColorConstants.whiteColor;
  static const double content_gap = LayoutConfig.space_16;
  static const double content_bottom = 24;
  static const double title_gap = LayoutConfig.space_12;
  static const double metadata_actions_gap = LayoutConfig.space_20;
  static const double panel_radius = LayoutConfig.radius_20;
  static const double default_overlap = 20;
  static const double surface_paint_overlap = 1;
  static const double title_size_cjk = 22;
  static const double title_size_alphabetic = 25;
  static const double reduced_title_size_cjk = 20;
  static const double reduced_title_size_alphabetic = 22;
  static const int regular_title_lines = 2;
  static const int reduced_title_lines = 4;
  static const double inline_actions_gap = LayoutConfig.space_12;
  static const double inline_actions_max_width = 320;
  static const double title_height_cjk = 1.3;
  static const double title_height_alphabetic = 1.16;
  static const double overflow_gap = LayoutConfig.space_16;
  static const double genres_gap = LayoutConfig.space_6;
  static const double nav_size = LayoutConfig.compact_control_height;
  static const double nav_icon_size = LayoutConfig.icon_compact;
  static const double nav_top = 8;
  static const double nav_content_gap = LayoutConfig.space_24;
  static const List<Shadow> title_shadows = [
    Shadow(
      color: ColorConstants
          .components_comment_list_widgets_comment_report_sheet_tone_99222222,
      blurRadius: 14,
      offset: Offset(0, 2),
    ),
    Shadow(
      color: ColorConstants.pages_short_story_read_widgets_collapse_button_tone,
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];
  static const Color nav_background =
      ColorConstants.pages_bookshelf_widgets_bookshelf_book_card_tone_73222222;
  static const Color poster_background =
      ColorConstants.poster_background_ff181c23;

  /// 底部黑色到透明渐变覆盖封面，中部保留底图纹理；顶部轻遮保证导航可读。
  static const List<Color> scrim_colors = [
    ColorConstants.pages_short_story_read_widgets_collapse_button_tone_1a222222,
    ColorConstants.transparent,
    ColorConstants.transparent,
    ColorConstants.backdrop_scrim_night,
    ColorConstants.backdrop_placeholder_dark,
  ];
  static const List<double> scrim_stops = [0, 0.12, 0.38, 0.64, 1];
}
