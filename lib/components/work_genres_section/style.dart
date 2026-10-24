import 'package:app/config/layout_config.dart';
import 'package:app/components/content_category_tag/style.dart';
import 'package:app/components/work_about_section/style.dart';
import 'package:flutter/material.dart';

/// 独立分类和嵌入简介的分类共用同一胶囊尺寸与昼夜着色规则。
class WorkGenresSectionStyle {
  const WorkGenresSectionStyle._();

  static const double tag_min_height = WorkAboutSectionStyle.tag_min_height;
  static const double tag_padding_horizontal =
      WorkAboutSectionStyle.tag_padding_horizontal;
  static const double tag_padding_vertical =
      WorkAboutSectionStyle.tag_padding_vertical;
  static const double tag_radius = WorkAboutSectionStyle.tag_radius;
  static const double tag_font_size_cjk =
      WorkAboutSectionStyle.tag_font_size_cjk;
  static const double tag_font_size_alphabetic =
      WorkAboutSectionStyle.tag_font_size_alphabetic;
  static const double tag_height_cjk = WorkAboutSectionStyle.tag_height_cjk;
  static const double tag_height_alphabetic =
      WorkAboutSectionStyle.tag_height_alphabetic;
  static const double tag_spacing = WorkAboutSectionStyle.tag_spacing;
  static const double tag_run_spacing = WorkAboutSectionStyle.tag_run_spacing;

  /// 海报区内分类胶囊：更紧凑的尺寸，不与统计争夺视觉重量。
  static const double hero_tag_min_height = 22;
  static const double hero_tag_padding_h = LayoutConfig.space_8;
  static const double hero_tag_padding_v = LayoutConfig.space_2;
  static const double hero_tag_font_cjk = 11;
  static const double hero_tag_font_alphabetic = 10.5;
  static const double hero_tag_spacing = LayoutConfig.space_6;
  static const double hero_tag_run_spacing = LayoutConfig.space_5;

  /// 与既有分类标签使用相同透明度，夜间保留彩色底的层次而不换掉原色。
  static Color tag_background(Color color, bool dark) => color.withValues(
    alpha: dark
        ? ContentCategoryTagStyle.background_alpha_dark
        : ContentCategoryTagStyle.background_alpha_light,
  );

  static Color tag_foreground(Color color) =>
      color.withValues(alpha: ContentCategoryTagStyle.text_alpha);
}
