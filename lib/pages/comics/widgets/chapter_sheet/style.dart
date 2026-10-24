// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:app/components/catalog_card/index.dart';
import 'package:app/config/layout_config.dart';
import 'package:app/pages/comics/widgets/comic_surface_style.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

/// TODO 章节目录的卡片、分段控件和缩放布局参数。
class ComicChapterCatalogStyle {
  const ComicChapterCatalogStyle._();

  static const double horizontal_padding = LayoutConfig.page_horizontal_padding;
  static const double toolbar_height = 54;
  static const double toolbar_gap = LayoutConfig.space_8;
  static const double card_gap = LayoutConfig.space_16;
  static const double location_inset = LayoutConfig.space_16;
  static const double card_radius = ComicSurfaceStyle.card_radius;
  static const double card_padding = LayoutConfig.space_14;
  static const double card_min_height = preview_height + card_padding * 2;
  static const double divider_height = 28;
  static const double content_gap = LayoutConfig.space_12;

  /// 横幅只裁切章节首图；窄屏和大字号时缩小预览，为标题保留更多空间。
  static const double preview_width = 92;
  static const double preview_height = 68;
  static const double preview_compact_width = 68;
  static const double preview_compact_height = 56;
  static const double preview_compact_content_width = 300;
  static const double preview_radius = LayoutConfig.radius_8;
  static const double preview_badge_inset = LayoutConfig.space_4;
  static const double preview_badge_padding = LayoutConfig.space_3;
  static const double preview_badge_opacity = 0.94;
  static const double title_size_cjk = CatalogCardStyle.title_size_cjk;
  static const double title_size_alphabetic =
      CatalogCardStyle.title_size_alphabetic;
  static const double metadata_size_cjk = 13;
  static const double metadata_size_alphabetic = 12.5;
  static const double title_height = 1.4;
  static const double metadata_height = 1.3;
  static const double metadata_gap = LayoutConfig.space_3;

  /// TODO 为跨平台字形的上下留白取整保留空间，避免大字模式行高出现亚像素溢出。
  static const double font_metric_allowance = 2;
  static const double sort_size_cjk = 11;
  static const double sort_size_alphabetic = 10;
  static const double sort_padding = LayoutConfig.space_10;
  static const double sort_radius = LayoutConfig.radius_24;
  static const double sort_height = 30;
  static const double count_size_cjk = 13;
  static const double count_size_alphabetic = 12;
  static const double arrow_size = 20;
  static const double continue_radius = LayoutConfig.radius_22;
  static const double continue_padding = LayoutConfig.space_12;
  static const double continue_height = 30;
  static const double continue_icon = 15;
  static const double selected_accent_width = 3;
  static const double selected_accent_height = 28;
  static const double selected_accent_inset = LayoutConfig.space_9;
  static const double compact_width = 360;
  static const double compact_scale = 1.3;
  static const Duration sort_duration = Duration(milliseconds: 180);
  static const Duration jump_duration = Duration(milliseconds: 300);

  static Color card_color(BuildContext context, {required bool selected}) =>
      CatalogCardStyle.card_background(
        Theme.of(context).brightness == Brightness.dark,
      );

  static const List<Color> continue_colors = [
    ColorConstants.pages_comics_widgets_chapter_sheet_style_tone_ffffec75,
    ColorConstants.pages_comics_widgets_chapter_sheet_style_tone_ffffcc25,
  ];
}

/// TODO 目录弹窗沿用小说阅读目录的 88% 高度、圆角和作品信息区比例。
class ComicChapterSheetStyle {
  const ComicChapterSheetStyle._();
  static const double height_ratio = 0.88;
  static const double radius = CatalogCardStyle.sheet_radius;
  static const double max_width = 600;
  static const double header_padding = LayoutConfig.page_horizontal_padding;
  static Color background(bool dark) => ComicSurfaceStyle.background(dark);
  static const double header_gap = LayoutConfig.space_16;
  static const double cover_width = 58;
  static const double cover_height = 78;
  static const double cover_radius = LayoutConfig.radius_8;
  static const double title_size_cjk = 20;
  static const double title_size_alphabetic = 18;
  static const double author_size_cjk = 13;
  static const double author_size_alphabetic = 12;
  static const double title_gap = LayoutConfig.space_8;
}
