import 'package:app/config/layout_config.dart';
import 'package:flutter/material.dart';

import 'package:app/components/comment_list/style.dart';

/// 段评输入弹窗的尺寸、排版和主题参数。
class ParagraphCommentComposerStyle {
  static const double max_width = 640;
  static const double radius = LayoutConfig.radius_20;
  static const double horizontal_padding = LayoutConfig.space_18;
  static const double vertical_padding = LayoutConfig.space_14;
  static const double section_spacing = LayoutConfig.space_12;
  static const double quote_padding = LayoutConfig.space_10;
  static const double quote_border_width = 3;
  static const double quote_radius = LayoutConfig.radius_6;
  static const int quote_max_lines = 3;
  static const double quote_font_size_cjk = 13;
  static const double quote_font_size_alphabetic = 12;
  static const double line_height_cjk = 1.5;
  static const double line_height_alphabetic = 1.4;
  static const double input_font_size_cjk = 16;
  static const double input_font_size_alphabetic = 15;
  static const double input_radius = LayoutConfig.radius_6;
  static const double input_padding = LayoutConfig.space_10;
  static const int input_min_lines = 3;
  static const int input_max_lines = 5;
  static const int max_content_length = 2000;
  static const double action_size = LayoutConfig.compact_control_height;
  static const double action_icon_size = 25;
  static const double send_min_width_cjk = 64;
  static const double send_min_width_alphabetic = 76;
  static const double send_font_size_cjk = 14;
  static const double send_font_size_alphabetic = 13;
  static const double send_radius = LayoutConfig.radius_18;
  static const double image_size = 64;
  static const double image_spacing = LayoutConfig.space_8;
  static const double image_radius = LayoutConfig.radius_8;
  static const double remove_size = 24;
  static const double remove_icon_size = LayoutConfig.icon_small;
  static const double progress_size = 18;
  static const double progress_stroke = 2;
  static const double error_font_size = 12;
  static const double emoji_max_height = 248;
  // 未打开过软键盘时，表情占位最多使用可用窗口的一半。
  static const double panel_height_ratio = 0.5;
  // 输入法高度改变后，等待连续指标停止再解除切换高度锁。
  static const Duration keyboard_settle_delay = Duration(milliseconds: 160);
  // 外接键盘没有软键盘高度变化，避免永久保留表情面板占位。
  static const Duration keyboard_restore_timeout = Duration(milliseconds: 600);
  static const int max_images = 9;
  static const double image_max_dimension = 1600;
  static const int image_quality = 85;

  static Color surface(bool is_dark) => is_dark
      ? CommentListStyle.sheet_dark_bg
      : CommentListStyle.sheet_light_bg;

  static Color text(bool is_dark) => is_dark
      ? CommentListStyle.title_dark_color
      : CommentListStyle.title_light_color;

  static Color secondary_text(bool is_dark) => is_dark
      ? CommentListStyle.secondary_dark_color
      : CommentListStyle.secondary_light_color;

  static Color quote_background(bool is_dark) => is_dark
      ? CommentListStyle.input_dark_bg
      : CommentListStyle.input_light_bg;

  static Color input_background(bool is_dark) => quote_background(is_dark);
}
