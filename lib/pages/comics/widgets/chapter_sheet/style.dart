// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:app/components/catalog_card/index.dart';
import 'package:flutter/material.dart';

/// TODO 章节目录的卡片、分段控件和缩放布局参数。
class ComicChapterCatalogStyle {
  const ComicChapterCatalogStyle._();

  static const double horizontal_padding = 12;
  static const double toolbar_height = 54;
  static const double toolbar_gap = 8;
  static const double card_gap = 8;
  static const double card_radius = CatalogCardStyle.radius;
  static const double card_padding = 14;
  static const double card_min_height = 54;
  static const double number_width = 36;
  static const double divider_height = 28;
  static const double content_gap = 12;
  static const double title_size_cjk = CatalogCardStyle.title_size_cjk;
  static const double title_size_alphabetic =
      CatalogCardStyle.title_size_alphabetic;
  static const double metadata_size_cjk = 13;
  static const double metadata_size_alphabetic = 12.5;
  static const double title_height = 1.4;
  static const double metadata_height = 1.3;
  static const double metadata_gap = 3;

  /// TODO 为跨平台字形的上下留白取整保留空间，避免大字模式行高出现亚像素溢出。
  static const double font_metric_allowance = 2;
  static const double number_size = 14;
  static const double sort_size_cjk = 11;
  static const double sort_size_alphabetic = 10;
  static const double sort_padding = 10;
  static const double sort_radius = 24;
  static const double sort_height = 30;
  static const double count_size_cjk = 13;
  static const double count_size_alphabetic = 12;
  static const double arrow_size = 20;
  static const double continue_radius = 22;
  static const double continue_padding = 12;
  static const double continue_height = 30;
  static const double continue_icon = 15;
  static const double selected_accent_width = 3;
  static const double selected_accent_height = 28;
  static const double selected_accent_inset = 9;
  static const double compact_width = 360;
  static const double compact_scale = 1.3;
  static const Duration sort_duration = Duration(milliseconds: 180);
  static const Duration jump_duration = Duration(milliseconds: 300);

  static Color card_color(BuildContext context, {required bool selected}) =>
      CatalogCardStyle.card_background(
        Theme.of(context).brightness == Brightness.dark,
      );

  static const List<Color> continue_colors = [
    Color(0xFFFFEC75),
    Color(0xFFFFCC25),
  ];
}

/// TODO 目录弹窗沿用小说阅读目录的 88% 高度、圆角和作品信息区比例。
class ComicChapterSheetStyle {
  const ComicChapterSheetStyle._();
  static const double height_ratio = CatalogCardStyle.sheet_height_ratio;
  static const double radius = CatalogCardStyle.sheet_radius;
  static const double max_width = 600;
  static const double header_padding = 20;
  static const double header_gap = 16;
  static const double cover_width = 58;
  static const double cover_height = 78;
  static const double cover_radius = 8;
  static const double title_size_cjk = 20;
  static const double title_size_alphabetic = 18;
  static const double author_size_cjk = 13;
  static const double author_size_alphabetic = 12;
  static const double title_gap = 8;
}
