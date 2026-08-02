import 'package:flutter/material.dart';
import 'package:app/config/font_config.dart';

/// 关于TopRead页面样式常量。
class Style {
  const Style._();

  /// Logo尺寸。
  static const double logo_size = 90;

  /// Logo顶部间距。
  static const double logo_top_spacing = 10;

  /// Logo与口号间距。
  static const double logo_to_slogan_spacing = 5;

  /// 口号与版本号间距。
  static const double slogan_to_version_spacing = 6;

  /// 版本号与列表间距。
  static const double version_to_list_spacing = 60;

  /// 列表项高度。
  static const double list_item_height = 56;

  /// 列表项左右内边距。
  static const double list_horizontal_padding = 16;

  /// 版本号字号。
  static const double version_font_size = 14;

  /// 列表项标题字号。
  static final double list_title_font_size = 15;

  /// 列表项标题字重。
  static final FontWeight list_title_weight = FontConfig.adjustedWeight(FontWeight.w400);

  /// 版本号字重。
  static final FontWeight version_weight = FontConfig.adjustedWeight(FontWeight.w400);
}
