// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';

/// 两种阅读页共享同一套段评布局及原短篇日夜配色。
class ParagraphCommentSheetStyle {
  const ParagraphCommentSheetStyle._();

  static const double height_ratio = .75;
  static const double sheet_radius = 14;
  static const double horizontal_padding = 16;
  static const double vertical_padding = 12;
  static const double item_spacing = 16;
  static const double small_spacing = 8;
  static const double tight_spacing = 4;
  static const double avatar_radius = 16;
  static const double avatar_gap = 10;
  static const double reply_padding = 12;
  static const double reply_radius = 12;
  static const double action_icon_size = 16;
  static const double icon_size = 22;
  static const double send_button_size = 40;
  static const double input_radius = 24;
  static const double input_vertical_padding = 10;
  static const double title_font_size_cjk = 17;
  static const double title_font_size_alphabetic = 15;
  static const double content_font_size_cjk = 15;
  static const double content_font_size_alphabetic = 14;
  static const double secondary_font_size_cjk = 13;
  static const double secondary_font_size_alphabetic = 12;
  static const double content_height_cjk = 1.5;
  static const double content_height_alphabetic = 1.4;
  static const double button_min_width_cjk = 64;
  static const double button_min_width_alphabetic = 80;
  static const double image_size = 88;
  static const double image_radius = 8;
  static const double image_spacing = 8;
  static const double quote_border_width = 3;
  static const double divider_height = 1;
  static const double progress_size = 18;
  static const int preview_max_lines = 3;
  static const int input_max_lines = 3;

  static Color surface(bool is_dark) =>
      is_dark ? const Color(0xFF0D1117) : Colors.white;
  static Color title(bool is_dark) =>
      is_dark ? const Color(0xFFE8E8EA) : const Color(0xFF1A1A1A);
  static Color body(bool is_dark) =>
      is_dark ? const Color(0xFFCCCCDD) : const Color(0xFF333333);
  static Color secondary(bool is_dark) =>
      is_dark ? const Color(0xFF8B8B9E) : const Color(0xFF666666);
  static Color divider(bool is_dark) =>
      is_dark ? const Color(0xFF21262D) : const Color(0xFFEEEEEE);
  static Color inset(bool is_dark) =>
      is_dark ? const Color(0xFF21262D) : const Color(0xFFF5F5F5);
  static Color get accent => ColorConstants.themeColor;
  static Color get danger => ColorConstants.dangerColor;

  /// 列表、菜单、确认框和图片预览的操作文字共用语系尺寸与平台字重。
  static ButtonStyle button({
    required bool is_dark,
    required bool is_cjk,
    bool destructive = false,
  }) => TextButton.styleFrom(
    foregroundColor: destructive ? danger : body(is_dark),
    minimumSize: Size(
      is_cjk ? button_min_width_cjk : button_min_width_alphabetic,
      kMinInteractiveDimension,
    ),
    textStyle: text(is_dark: is_dark, is_cjk: is_cjk),
  );

  static TextStyle text({
    required bool is_dark,
    required bool is_cjk,
    bool secondary = false,
    bool emphasis = false,
    bool heading = false,
  }) => TextStyle(
    color: secondary
        ? ParagraphCommentSheetStyle.secondary(is_dark)
        : heading ? title(is_dark) : body(is_dark),
    fontSize: heading
        ? (is_cjk ? title_font_size_cjk : title_font_size_alphabetic)
        : secondary
        ? (is_cjk ? secondary_font_size_cjk : secondary_font_size_alphabetic)
        : (is_cjk ? content_font_size_cjk : content_font_size_alphabetic),
    height: is_cjk ? content_height_cjk : content_height_alphabetic,
    fontWeight: FontConfig.adjustedWeight(
      emphasis || heading ? FontWeight.w500 : FontWeight.w400,
    ),
  );
}
