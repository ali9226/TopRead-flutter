import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';
import 'package:app/components/expandable_synopsis/style.dart';
import 'package:app/config/color_config.dart';

/// 简介区块样式常量
class IntroSummaryStyle {
  /// 区块标题字号
  static const double section_title_font_size = 16;

  /// 简介内容顶部间距
  static const double intro_top_spacing = LayoutConfig.space_12;

  /// 简介字号
  static const double intro_font_size = ExpandableSynopsisStyle.font_size_cjk;

  /// 简介文案行高倍数
  static const double intro_line_height = 1.5;

  /// 简介文案右侧预留间距
  static const double intro_right_padding = LayoutConfig.space_20;

  /// 更多文字字号
  static const double more_font_size = 12;

  /// 夜间模式下的正文颜色
  static const Color intro_text_color_dark = ColorConstants.pages_message_widgets_message_item_card_tone; // white64

  /// 日间模式下的正文颜色
  static const Color intro_text_color_light = ColorConstants.components_reader_top_bar_style_tone_ff7a6a56;

  /// 夜间模式下的标题颜色
  static const Color intro_title_color_dark = ColorConstants.whiteColor;

  /// 日间模式下的标题颜色
  static const Color intro_title_color_light = ColorConstants.components_reader_top_bar_style_tone_ff1f1a12;

  /// 更多按钮颜色
  static const Color more_button_color = ColorConstants.pages_read_widgets_read_directory_sheet_widgets_book_detail_header_tone;
}
