// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:app/components/work_section_card/style.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/config/layout_config.dart';
import 'package:app/util/language_util/index.dart';
import 'package:flutter/material.dart';

/// 热评卡片复用详情纸面和公共评论项，额外尺寸只定义标题、反馈和发表入口。
class ComicHotCommentsStyle {
  const ComicHotCommentsStyle._();

  static const int preview_count = 3;
  static const int skeleton_count = 2;
  static const double horizontal_padding = WorkSectionCardStyle.padding;
  static const double header_top = LayoutConfig.space_12;
  static const double header_gap = LayoutConfig.space_8;
  static const double title_count_gap = LayoutConfig.space_4;
  static const double count_size_cjk = 12;
  static const double count_size_alphabetic = 11;
  static const double action_size_cjk = 13;
  static const double action_size_alphabetic = 12;
  static const double action_max_fraction = 0.45;
  static const double action_icon = 16;
  static const double action_icon_gap = LayoutConfig.space_4;
  static const double control_min_height = LayoutConfig.compact_control_height;
  static const double footer_gap = LayoutConfig.space_12;
  static const double feedback_padding = LayoutConfig.space_24;
  static const double feedback_size_cjk = 13;
  static const double feedback_size_alphabetic = 12;
  static const double text_height_cjk = 1.5;
  static const double text_height_alphabetic = 1.45;
  static const double control_radius = LayoutConfig.radius_10;
  static const double control_tint = 0.045;
  static const double border_alpha = 0.08;

  static final FontWeight regular = FontConfig.adjustedWeight(FontWeight.w400);
  static final FontWeight medium = FontConfig.adjustedWeight(FontWeight.w500);

  static bool is_cjk(BuildContext context) => LanguageUtil.is_cjk_language(
    Localizations.localeOf(context).languageCode,
  );

  static double localized_size(
    BuildContext context,
    double cjk,
    double alphabetic,
  ) => is_cjk(context) ? cjk : alphabetic;

  static double line_height(BuildContext context) =>
      is_cjk(context) ? text_height_cjk : text_height_alphabetic;

  static Color foreground(bool dark) => WorkSectionCardStyle.foreground(dark);

  static Color secondary(bool dark) => dark
      ? ColorConstants.components_load_more_footer_index_tone
      : ColorConstants.pages_comics_detail_style_tone_ff777985;
}
