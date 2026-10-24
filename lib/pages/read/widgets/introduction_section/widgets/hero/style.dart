import 'package:app/config/layout_config.dart';
import 'package:app/components/work_reading_actions/style.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

/// 长篇操作使用与短篇、漫画一致的设计参数。
typedef ReadIntroductionHeroStyle = WorkReadingActionsStyle;

/// 作者下方的连载状态为辅助信息，不与数字统计混排。
class ReadIntroductionMetadataStyle {
  const ReadIntroductionMetadataStyle._();
  static const double status_gap = LayoutConfig.space_8;
  static const double status_size_cjk = 12;
  static const double status_size_alphabetic = 11.5;
  static const double status_height_cjk = 1.4;
  static const double status_height_alphabetic = 1.5;
  static const Color status_hero = ColorConstants.pages_bookshelf_widgets_bookshelf_book_card_tone_b8ffffff;
  static const Color status_dark = ColorConstants.pages_change_password_style_tone_a6ffffff;
  static const Color status_light = ColorConstants.status_light_ff72737e;
}
