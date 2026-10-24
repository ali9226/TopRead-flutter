// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:app/components/comment_list/style.dart';
import 'package:app/components/work_section_card/index.dart';
import 'package:app/config/layout_config.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/util/language_util/index.dart';
import 'package:flutter/material.dart';

/// TODO 漫画面板只维护容器层级，正文、回复、输入继续使用小说公共样式。
class ComicCommentSheetStyle {
  static const double max_width = 680;
  static const double radius = LayoutConfig.radius_24;
  static const double horizontal_padding = LayoutConfig.page_horizontal_padding;
  static const double header_bottom_padding = LayoutConfig.space_10;
  static const double header_gap = LayoutConfig.space_10;
  static const double header_title_cjk = 18;
  static const double header_title_alphabetic = 17;
  static const double count_size_cjk = 12;
  static const double count_size_alphabetic = 11;
  static const double count_padding_h = LayoutConfig.space_9;
  static const double count_padding_v = LayoutConfig.space_3;
  static const double close_target = 48;
  static const double close_surface = 32;
  static const double close_icon = 13;
  static const double border_width = 0.5;
  static const double list_top_padding = LayoutConfig.space_4;
  static const double feedback_top = 56;
  static const double feedback_bottom = 40;
  static const double feedback_max_width = 280;
  static const double feedback_icon_surface = 76;
  static const double feedback_icon = 30;
  static const double feedback_gap = LayoutConfig.space_20;
  static const double feedback_font_cjk = 14;
  static const double feedback_font_alphabetic = 13;
  static const double feedback_line_height = 1.6;

  static double localized_size(
    BuildContext context,
    double cjk,
    double alphabetic,
  ) =>
      LanguageUtil.is_cjk_language(Localizations.localeOf(context).languageCode)
      ? cjk
      : alphabetic;
  static Color background(bool dark) => WorkSectionCardStyle.background(dark);
  static List<BoxShadow> shadows(bool dark) =>
      WorkSectionCardStyle.shadows(dark);
  static Color foreground(bool dark) => dark
      ? CommentListStyle.title_dark_color
      : CommentListStyle.title_light_color;
  static Color secondary(bool dark) => dark
      ? CommentListStyle.secondary_dark_color
      : CommentListStyle.secondary_light_color;
  static Color line(bool dark) => dark
      ? CommentListStyle.divider_dark_color
      : CommentListStyle.divider_light_color;
  static Color soft_surface(bool dark) =>
      foreground(dark).withValues(alpha: dark ? 0.07 : 0.045);
  static Color icon_tint(bool dark) =>
      ColorConstants.themeColor.withValues(alpha: dark ? 0.13 : 0.1);
  static FontWeight get medium => FontConfig.adjustedWeight(FontWeight.w500);
  static FontWeight get regular => FontConfig.adjustedWeight(FontWeight.w400);
}
