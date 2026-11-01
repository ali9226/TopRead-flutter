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

  /*
   TODO 卡片在宽屏下的最大宽度，超出后居中放置。

   卡片内容是「图标 + 两行短标题 + 播放按钮」，
   被 iPad / 横屏的 900pt 内容列拉满时，标题与播放钮之间会留下大片空白，
   比例明显失衡。限制到该宽度后：
   - 手机（内容列 408pt）小于此值，宽度与原本完全一致，不受影响；
   - iPad / 横屏自动收到此值并居中，视觉回到紧凑的推广卡片比例。
   */
  static const double max_width = 560;
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
  static const light_colors = [
    ColorConstants.pages_user_info_widgets_tile_quest_entry_style_tone_ffeef1ff,
    ColorConstants.pages_user_info_widgets_tile_quest_entry_style_tone_ffe9f7ff,
  ];
  static const dark_colors = [
    ColorConstants.pages_user_info_widgets_tile_quest_entry_style_tone_ff252d53,
    ColorConstants.pages_user_info_widgets_tile_quest_entry_style_tone_ff182c45,
  ];
  static const light_ink = ColorConstants
      .pages_user_info_widgets_tile_quest_entry_style_tone_ff28345b;
  static const dark_ink = ColorConstants
      .pages_user_info_widgets_tile_quest_entry_style_tone_ffeef2ff;
  static const accent = ColorConstants
      .pages_user_info_widgets_tile_quest_entry_style_tone_ff637fe6;
  static final title_weight = FontConfig.adjustedWeight(FontWeight.w700);
  static final subtitle_weight = FontConfig.adjustedWeight(FontWeight.w400);
}
