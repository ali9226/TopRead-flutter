// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:app/config/layout_config.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';

/// 两种阅读页共享同一套段评布局及原短篇日夜配色。
class ParagraphCommentSheetStyle {
  const ParagraphCommentSheetStyle._();

  static const double height_ratio = .75;
  static const double sheet_radius = LayoutConfig.radius_14;
  static const double horizontal_padding = LayoutConfig.space_16;
  static const double vertical_padding = LayoutConfig.space_12;
  static const double item_spacing = LayoutConfig.space_16;
  static const double small_spacing = LayoutConfig.space_8;
  static const double tight_spacing = LayoutConfig.space_4;
  static const double avatar_radius = LayoutConfig.radius_16;
  static const double avatar_gap = LayoutConfig.space_10;
  static const double reply_padding = LayoutConfig.space_12;
  static const double reply_radius = LayoutConfig.radius_12;
  static const double action_icon_size = LayoutConfig.icon_small;
  static const double icon_size = LayoutConfig.icon_compact;
  static const double send_button_size = 40;
  static const double input_radius = LayoutConfig.radius_24;
  static const double input_vertical_padding = LayoutConfig.space_10;
  static const double title_font_size_cjk = 17;
  static const double title_font_size_alphabetic = 15;
  static const double content_font_size_cjk = 15;
  static const double content_font_size_alphabetic = 14;
  static const double secondary_font_size_cjk = 13;
  static const double secondary_font_size_alphabetic = 12;
  static const double content_height_cjk = 1.5;
  static const double content_height_alphabetic = 1.4;
  static const double button_min_width_cjk = 64;
  static const double button_min_width_alphabetic = 80;
  static const double image_size = 88;
  static const double image_radius = LayoutConfig.radius_8;
  static const double image_spacing = LayoutConfig.space_8;
  static const double quote_border_width = 3;
  static const double divider_height = 1;
  static const double progress_size = 18;
  static const int preview_max_lines = 3;
  static const int input_max_lines = 3;

  static Color surface(bool is_dark) => ColorConstants.sheetBackground(is_dark);
  static Color title(bool is_dark) =>
      is_dark ? ColorConstants.components_category_filter_filter_popup_tone : ColorConstants.components_cute_mascot_index_tone_ff1a1a1a;
  static Color body(bool is_dark) =>
      is_dark ? ColorConstants.components_paragraph_comment_sheet_style_tone : ColorConstants.components_paragraph_comment_sheet_style_tone_ff333333;
  static Color secondary(bool is_dark) =>
      is_dark ? ColorConstants.components_no_internet_cute_no_internet_cloud_tone_ff8b8b9e : ColorConstants.customer_service_sheet_style_time_color_dark;
  static Color divider(bool is_dark) =>
      is_dark ? ColorConstants.components_reader_top_bar_style_tone_ff21262d : ColorConstants.components_reader_top_bar_style_tone_ffeeeeee;
  static Color inset(bool is_dark) =>
      is_dark ? ColorConstants.components_reader_top_bar_style_tone_ff21262d : ColorConstants.config_color_config_tone_fff5f5f5;
  static Color get accent => ColorConstants.themeColor;
  static Color get danger => ColorConstants.dangerColor;

  /// 列表、菜单、确认框和图片预览的操作文字共用语系尺寸与平台字重。
  static ButtonStyle button({
    required bool is_dark,
    required bool is_cjk,
    bool destructive = false,
  }) => TextButton.styleFrom(
    foregroundColor: destructive ? danger : body(is_dark),
    minimumSize: Size(
      is_cjk ? button_min_width_cjk : button_min_width_alphabetic,
      kMinInteractiveDimension,
    ),
    textStyle: text(is_dark: is_dark, is_cjk: is_cjk),
  );

  static TextStyle text({
    required bool is_dark,
    required bool is_cjk,
    bool secondary = false,
    bool emphasis = false,
    bool heading = false,
  }) => TextStyle(
    color: secondary
        ? ParagraphCommentSheetStyle.secondary(is_dark)
        : heading
        ? title(is_dark)
        : body(is_dark),
    fontSize: heading
        ? (is_cjk ? title_font_size_cjk : title_font_size_alphabetic)
        : secondary
        ? (is_cjk ? secondary_font_size_cjk : secondary_font_size_alphabetic)
        : (is_cjk ? content_font_size_cjk : content_font_size_alphabetic),
    height: is_cjk ? content_height_cjk : content_height_alphabetic,
    fontWeight: FontConfig.adjustedWeight(
      emphasis || heading ? FontConfig.adjustedWeight(FontWeight.w500) : FontConfig.adjustedWeight(FontWeight.w400),
    ),
  );
}
