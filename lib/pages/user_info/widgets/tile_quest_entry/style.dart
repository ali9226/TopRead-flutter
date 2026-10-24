// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';
import 'package:app/config/color_config.dart';

/// 个人中心游戏入口的尺寸与日夜配色。
class TileQuestEntryStyle {
  static const margin = EdgeInsets.fromLTRB(
    LayoutConfig.space_16,
    LayoutConfig.space_12,
    LayoutConfig.space_16,
    LayoutConfig.space_16,
  );
  static const padding = EdgeInsets.all(LayoutConfig.space_16);
  static const double radius = LayoutConfig.radius_24;
  static const double icon_size = 64;
  static const double icon_radius = LayoutConfig.radius_18;
  static const double content_gap = LayoutConfig.space_14;
  static const double title_size_cjk = 20;
  static const double title_size_alphabetic = 19;
  static const double subtitle_size_cjk = 13;
  static const double subtitle_size_alphabetic = 12;
  static const double line_height_cjk = 1.4;
  static const double line_height_alphabetic = 1.5;
  static const double action_size = 36;
  static const light_colors = [ColorConstants.pages_user_info_widgets_tile_quest_entry_style_tone_ffeef1ff, ColorConstants.pages_user_info_widgets_tile_quest_entry_style_tone_ffe9f7ff];
  static const dark_colors = [ColorConstants.pages_user_info_widgets_tile_quest_entry_style_tone_ff252d53, ColorConstants.pages_user_info_widgets_tile_quest_entry_style_tone_ff182c45];
  static const light_ink = ColorConstants.pages_user_info_widgets_tile_quest_entry_style_tone_ff28345b;
  static const dark_ink = ColorConstants.pages_user_info_widgets_tile_quest_entry_style_tone_ffeef2ff;
  static const accent = ColorConstants.pages_user_info_widgets_tile_quest_entry_style_tone_ff637fe6;
  static final title_weight = FontConfig.adjustedWeight(FontWeight.w700);
  static final subtitle_weight = FontConfig.adjustedWeight(FontWeight.w400);
}
