// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:app/config/layout_config.dart';
import 'package:app/pages/comics/widgets/comic_surface_style.dart';
import 'package:flutter/material.dart';

/// 横向章节的尺寸与文字高度统一管理，按可用窗口宽度和系统字号自然扩展。
class ComicChapterPreviewStyle {
  const ComicChapterPreviewStyle._();

  static const double card_width_ratio = 0.38;
  static const double card_min_width = 124;
  static const double card_max_width = 184;

  /// 竖向空间优先展示首图，原第二行标题的高度交还给4:3预览。
  static const double image_ratio = 4 / 3;
  static const double radius = ComicSurfaceStyle.card_radius;
  static const double gap = LayoutConfig.space_12;
  static const double title_padding_h = LayoutConfig.space_10;
  static const double title_padding_v = LayoutConfig.space_10;
  static const double list_padding_top = LayoutConfig.space_4;
  static const double list_padding_bottom = LayoutConfig.space_10;
  static const double font_metric_allowance = 2;
  static const double header_gap = LayoutConfig.space_8;
  static const double heading_size_cjk = 16;
  static const double heading_size_alphabetic = 15;
  static const double title_size_cjk = 13;
  static const double title_size_alphabetic = 12;
  static const double count_size_cjk = 12;
  static const double count_size_alphabetic = 11;
  static const double line_height_cjk = 1.45;
  static const double line_height_alphabetic = 1.5;
  static const int title_lines = 1;
  static const double arrow_size = 18;
  static const double status_dot_size = 6;
  static const double selection_width = 1.5;
  static const double minimum_action_height =
      LayoutConfig.compact_control_height;
  static const double visibility_tolerance = 0.5;
  static const Duration position_duration = Duration(milliseconds: 320);
  static const Curve position_curve = Curves.easeInOutCubic;
  static const EdgeInsets action_padding = EdgeInsets.symmetric(
    horizontal: LayoutConfig.space_4,
    vertical: LayoutConfig.space_8,
  );
}
