import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/layout_config.dart';

/// TODO 章节弹窗的 Hero、玻璃分页栏与纸面目录共用样式。
class ReadDirectorySheetStyle {
  static const double sheet_border_radius = LayoutConfig.radius_32;
  static const double sheet_height_ratio = .94;
  static const double hero_max_height_ratio = .38;
  static const double compact_height = 500;
  static const double chrome_height = 40;
  static const double close_target = 40;
  static const double close_icon = 22;
  static const double handle_width = 34;
  static const double handle_height = 4;
  static const double tab_bar_height = 52;
  static const double tab_horizontal_padding = LayoutConfig.space_16;
  static const double tab_font_size_cjk = 15;
  static const double tab_font_size_alphabetic = 12;
  static const double tab_label_padding = 4;
  static const double tab_icon_size = 18;
  static const double tab_gap = LayoutConfig.space_6;
  static const double body_radius = LayoutConfig.radius_24;
  static const double toolbar_height = 54;
  static const double toolbar_font_size_cjk = 14;
  static const double toolbar_font_size_alphabetic = 12;
  static const double toolbar_target = 40;
  static const double catalog_padding = LayoutConfig.space_16;
  static const double chapter_separator_height = LayoutConfig.space_8;
  static const double chapter_item_estimated_height = 68;
  static const double current_chapter_reveal_alignment = .18;
  static const int position_max_refine_attempts = 8;
  static const int scroll_animation_duration_ms = 320;
  static const double position_button_right = LayoutConfig.space_16;
  static const double position_button_bottom_spacing = LayoutConfig.space_16;
  static const EdgeInsets catalog_list_padding = EdgeInsets.fromLTRB(
    catalog_padding,
    LayoutConfig.space_4,
    catalog_padding,
    LayoutConfig.space_20,
  );
  static const double chapter_radius = LayoutConfig.radius_20;
  static const double chapter_padding = LayoutConfig.space_14;
  static const double chapter_shadow_blur_radius = 18;
  static const Offset chapter_shadow_offset = Offset(0, 5);
  static const double chapter_min_height = 58;
  static const double chapter_number_width = 34;
  static const double chapter_number_padding_v = LayoutConfig.space_5;
  static const double chapter_number_radius = LayoutConfig.radius_12;
  static const double chapter_number_size_cjk = 13;
  static const double chapter_number_size_alphabetic = 12;
  static const double chapter_number_title_spacing = LayoutConfig.space_12;
  static const double chapter_title_size_cjk = 15;
  static const double chapter_title_size_alphabetic = 14;
  static const double chapter_label_size_cjk = 12;
  static const double chapter_label_size_alphabetic = 11;
  static const double chapter_title_height = 1.35;
  static const double chapter_label_gap = LayoutConfig.space_4;
  static const double chapter_action_target = 40;
  static const double chapter_action_icon = 22;
  static const double chapter_chevron_gap = LayoutConfig.space_8;
  static const double progress_height = 4;
  static const double progress_gap = LayoutConfig.space_12;
  static const double progress_label_size_cjk = 12;
  static const double progress_label_size_alphabetic = 11;
  static const double footer_padding = LayoutConfig.space_16;
  static const double footer_vertical_padding = LayoutConfig.space_12;
  static const double footer_compact_vertical_padding = LayoutConfig.space_6;
  static const double footer_radius = LayoutConfig.radius_32;
  static const double footer_shadow_blur_radius = 22;
  static const Offset footer_shadow_offset = Offset(0, 8);
  static const double footer_min_height = 56;
  static const double footer_compact_min_height = 44;
  static const EdgeInsets footer_content_padding = EdgeInsets.symmetric(
    horizontal: LayoutConfig.space_16,
    vertical: LayoutConfig.space_8,
  );
  static const double footer_font_size_cjk = 18;
  static const double footer_font_size_alphabetic = 17;
  static const double footer_meta_size_cjk = 12;
  static const double footer_meta_size_alphabetic = 11;
  static const double footer_icon_size = 26;
  static const double footer_gap = LayoutConfig.space_12;
  static const double footer_compact_height = 500;
  static const Duration transition_duration = Duration(milliseconds: 220);

  static Color getSheetColor(bool dark) => dark
      ? ColorConstants.nightBackgroundColor
      : Color.lerp(
          ColorConstants.whiteColor,
          ColorConstants.palette_violet,
          .025,
        )!;
  static Color getPrimaryTextColor(bool dark) =>
      dark ? ColorConstants.whiteColor : ColorConstants.lightTextColor;
  static Color getSubTextColor(bool dark) =>
      getPrimaryTextColor(dark).withValues(alpha: dark ? .65 : .58);
  static Color getCardColor(bool dark) => dark
      ? ColorConstants.components_reader_top_bar_style_tone
      : ColorConstants.whiteColor;
  static Color getChapterNumberColor(bool dark) =>
      getPrimaryTextColor(dark).withValues(alpha: .055);
  static Color getCurrentCardColor(bool dark) => getCardColor(dark);
  static Color getProgressTrackColor(bool dark) =>
      getPrimaryTextColor(dark).withValues(alpha: .10);
  static Color hero_surface(bool dark) =>
      ColorConstants.poster_background_ff181c23;
  static Color tab_surface(bool dark) =>
      ColorConstants.whiteColor.withValues(alpha: .12);
  static Color card_shadow(bool dark) =>
      ColorConstants.palette_violet.withValues(alpha: dark ? .03 : .065);
}
