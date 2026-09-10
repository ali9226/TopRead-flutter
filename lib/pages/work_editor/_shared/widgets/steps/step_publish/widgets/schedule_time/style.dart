// ignore_for_file: constant_identifier_names

import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';

/// 发布时间卡片与选择面板共用的尺寸、字体及动画参数。
class ScheduleTimeStyle {
  const ScheduleTimeStyle._();

  static const double sheet_max_width = 560;
  static const double sheet_height_factor = .92;
  static const double sheet_radius = 28;
  static const double card_radius = 18;
  static const double sheet_padding = 22;
  static const double card_padding = 16;
  static const double section_gap = 20;
  static const double small_gap = 8;
  static const double icon_size = 22;
  static const double badge_size = 52;
  static const double button_height = 50;
  static const double wheel_height = 200;
  static const double wheel_row_height = 38;
  static const int horizon_days = 365;

  static const double title_size_cjk = 22;
  static const double title_size_alphabetic = 20;
  static const double label_size_cjk = 14;
  static const double label_size_alphabetic = 13;
  static const double hint_size_cjk = 12;
  static const double hint_size_alphabetic = 12;
  static const double wheel_size_cjk = 19;
  static const double wheel_size_alphabetic = 17;
  static const double time_size_cjk = 30;
  static const double time_size_alphabetic = 28;
  static const double picker_max_text_scale = 1.2;

  static final FontWeight title_weight = FontConfig.adjustedWeight(FontWeight.w500);
  static final FontWeight body_weight = FontConfig.adjustedWeight(FontWeight.w400);
}
