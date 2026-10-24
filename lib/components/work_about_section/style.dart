import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

/// 作品详情正文的统一留白、标题和中性分类胶囊。
class WorkAboutSectionStyle {
  const WorkAboutSectionStyle._();

  static const double horizontal_padding = LayoutConfig.page_horizontal_padding;
  static const double module_gap = LayoutConfig.space_24;
  static const double heading_gap = LayoutConfig.space_12;
  static const double heading_size_cjk = 17;
  static const double heading_size_alphabetic = 17;
  static const double heading_height = 1.3;
  static const double divider_width = 0.5;
  static const double divider_gap = LayoutConfig.space_12;
  static const double tag_spacing = LayoutConfig.space_8;
  static const double tag_run_spacing = LayoutConfig.space_8;
  static const double tag_min_height = 32;
  static const double tag_padding_horizontal = LayoutConfig.space_12;
  static const double tag_padding_vertical = LayoutConfig.space_6;
  static const double tag_radius = LayoutConfig.radius_pill;
  static const double tag_font_size_cjk = 12.5;
  static const double tag_font_size_alphabetic = 12;
  static const double tag_height_cjk = 1.4;
  static const double tag_height_alphabetic = 1.45;

  static Color foreground(bool dark) =>
      dark ? ColorConstants.components_work_about_section_style_tone : ColorConstants.components_work_about_section_style_tone_ff25262c;
  static Color secondary(bool dark) =>
      dark ? ColorConstants.components_work_about_section_style_tone_ffb7bac4 : ColorConstants.components_work_about_section_style_tone_ff626570;
  static Color tag_background(bool dark) =>
      dark ? ColorConstants.components_work_about_section_style_tone_ff26272e : ColorConstants.components_work_about_section_style_tone_fff1f2f4;
  static Color divider(bool dark) =>
      dark ? ColorConstants.components_work_about_section_style_tone_ff30313a : ColorConstants.components_work_about_section_style_tone_ffe9eaed;
}
