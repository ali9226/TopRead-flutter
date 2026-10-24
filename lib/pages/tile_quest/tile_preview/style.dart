// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'package:app/config/layout_config.dart';
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

/// 方块材质预览页的视觉常量；深蓝夜空底突出奶油方块。
class TilePreviewStyle {
  const TilePreviewStyle._();

  /// 页面左右留白。
  static const double page_padding = LayoutConfig.space_20;

  /// 区块之间的垂直间距。
  static const double section_gap = LayoutConfig.space_36;

  /// 区块标题与内容的间距。
  static const double header_gap = LayoutConfig.space_16;

  /// 尺寸标签字号。
  static const double label_size = 11;

  /// 区块标题字号。
  static const double title_size = 13;

  /// 页面主标题字号。
  static const double heading_size = 22;

  /// 尺寸展示的固定边长序列。
  static const List<double> sample_sizes = [40, 48, 56, 64, 80, 96];

  /// 堆叠演示里每个方块的边长。
  static const double stack_tile = 72;

  /// 堆叠演示中同层相邻方块的间距。
  static const double stack_gap = LayoutConfig.space_4;

  /// 堆叠演示层与层之间的水平错位。
  static const double stack_layer_dx = 28;

  /// 堆叠演示层与层之间的垂直错位。
  static const double stack_layer_dy = 22;

  /// 夜空渐变：上深下浅，模拟游戏场景天光。
  static const List<Color> sky = [
    ColorConstants.pages_tile_quest_style_tone_ff0b1430,
    ColorConstants.pages_tile_quest_tile_preview_style_tone_ff15284c,
    ColorConstants.pages_tile_quest_tile_preview_style_tone_ff1c3d62,
  ];

  /// 标题色。
  static const Color heading = ColorConstants.game_cream;

  /// 次级文字色。
  static const Color caption = ColorConstants.caption_ffb8cce8;

  /// 区块标题色。
  static const Color section_title = ColorConstants.section_title_ff9fc2e8;

  /// 区块标题样式。
  static TextStyle section() => TextStyle(
    color: section_title,
    fontSize: title_size,
    letterSpacing: 2.4,
    fontWeight: FontConfig.adjustedWeight(FontWeight.w600),
  );

  /// 尺寸标签样式。
  static TextStyle label() => TextStyle(
    color: caption,
    fontSize: label_size,
    letterSpacing: 0.6,
    fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
  );

  /// 主标题样式。
  static TextStyle heading_style() => TextStyle(
    color: heading,
    fontSize: heading_size,
    letterSpacing: -0.4,
    fontWeight: FontConfig.adjustedWeight(FontWeight.w700),
  );
}
