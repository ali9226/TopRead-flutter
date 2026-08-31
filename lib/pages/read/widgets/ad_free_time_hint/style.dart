import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';

/// 免广告提示文字样式常量。
class AdFreeTimeHintStyle {
  AdFreeTimeHintStyle._();

  /// 提示文字与上方内容的间距。
  static const double top_spacing = 12;

  /// 提示文字与下方内容的间距。
  static const double bottom_spacing = 18;

  /// 提示文字水平内边距。
  static const double horizontal_padding = 0;

  /// CJK语系的提示文字字号。
  static const double font_size_cjk = 13;

  /// 拉丁字母语系的提示文字字号，长文案适当缩小。
  static const double font_size_alphabetic = 12;

  /// 提示文字字重。
  static final FontWeight font_weight = FontConfig.adjustedWeight(
    FontWeight.w400,
  );

  /// 日间模式下提示文字颜色（浅灰色）。
  static final Color text_color_light = ColorConstants.hintColor;

  /// 夜间模式下提示文字颜色（夜间提示色）。
  static final Color text_color_dark = ColorConstants.nightTextColor;
}
