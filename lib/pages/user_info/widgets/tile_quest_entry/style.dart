// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';

/// 个人中心游戏入口的尺寸与日夜配色。
class TileQuestEntryStyle {
  static const margin = EdgeInsets.fromLTRB(16, 12, 16, 16);
  static const padding = EdgeInsets.all(16);
  static const double radius = 24;
  static const double icon_size = 64;
  static const double icon_radius = 18;
  static const double content_gap = 14;
  static const double title_size_cjk = 20;
  static const double title_size_alphabetic = 19;
  static const double subtitle_size_cjk = 13;
  static const double subtitle_size_alphabetic = 12;
  static const double line_height_cjk = 1.4;
  static const double line_height_alphabetic = 1.5;
  static const double action_size = 36;
  static const light_colors = [Color(0xffeef1ff), Color(0xffe9f7ff)];
  static const dark_colors = [Color(0xff252d53), Color(0xff182c45)];
  static const light_ink = Color(0xff28345b);
  static const dark_ink = Color(0xffeef2ff);
  static const accent = Color(0xff637fe6);
  static final title_weight = FontConfig.adjustedWeight(FontWeight.w700);
  static final subtitle_weight = FontConfig.adjustedWeight(FontWeight.w400);
}
