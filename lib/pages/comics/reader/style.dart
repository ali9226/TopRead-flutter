// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';

/// 漫画阅读页设计参数：沉浸式画布、渐变遮罩工具条、章节收尾区集中管理。
///
/// 设计语言：全黑画布 + 顶部/底部细渐变遮罩 + 极简悬浮控件，
/// 避免厚重玻璃拟态，让画面本身成为主角。
class ComicReaderStyle {
  /// 阅读画布最大宽度，超宽屏居中留白。
  static const double canvas_max_width = 920;

  /// 画布背景色（近黑，减少 OLED 发光）。
  static const Color canvas_background = Color(0xFF0A0B0E);

  // ==================== 顶部工具条 ====================

  /// 顶部渐变遮罩总高度（含安全区补偿由 UI 层叠加）。
  static const double top_scrim_height = 120;

  /// 顶部渐变遮罩高度（不含安全区）。
  static const double top_bar_height = 52;

  /// 顶部控件水平内边距。
  static const double top_padding_h = 12;

  /// 顶部渐变最大不透明度。
  static const double top_scrim_opacity = 0.72;

  /// 标题字号（CJK）。
  static const double title_font_size_cjk = 15;

  /// 标题字号（拉丁语系）。
  static const double title_font_size_alphabetic = 14;

  /// 标题最大行数。
  static const int title_max_lines = 1;

  /// 顶部图标按钮点击区尺寸。
  static const double top_icon_target = 44;

  /// 顶部图标尺寸。
  static const double top_icon_size = 22;

  /// 顶部按钮间距。
  static const double top_button_gap = 2;

  // ==================== 顶部细进度条 ====================

  /// 顶部细进度条高度。
  static const double progress_track_height = 2.5;

  /// 进度条已读部分颜色。
  static final Color progress_active_color = ColorConstants.themeColor;

  /// 进度条未读部分颜色。
  static const Color progress_inactive_color = Color(0x33FFFFFF);

  // ==================== 底部控制条 ====================

  /// 底部渐变遮罩总高度。
  static const double bottom_scrim_height = 140;

  /// 底部控件区高度。
  static const double bottom_bar_height = 64;

  /// 底部控件水平内边距。
  static const double bottom_padding_h = 20;

  /// 底部渐变最大不透明度。
  static const double bottom_scrim_opacity = 0.82;

  /// 页码胶囊水平内边距。
  static const double page_pill_padding_h = 14;

  /// 页码胶囊垂直内边距。
  static const double page_pill_padding_v = 7;

  /// 页码胶囊圆角。
  static const double page_pill_radius = 999;

  /// 页码字号。
  static const double page_font_size = 13;

  /// 章节切换按钮尺寸。
  static const double nav_button_size = 44;

  /// 章节切换按钮图标尺寸。
  static const double nav_icon_size = 22;

  // ==================== 章节收尾区 ====================

  /// 章节收尾区顶部留白。
  static const double end_section_top_spacing = 72;

  /// 章节收尾区底部留白。
  static const double end_section_bottom_spacing = 120;

  /// 章节收尾区水平内边距。
  static const double end_section_padding_h = 32;

  /// 完成图标圆形容器尺寸。
  static const double end_icon_container = 56;

  /// 完成图标尺寸。
  static const double end_icon_size = 30;

  /// 标题与图标间距。
  static const double end_title_top_spacing = 20;

  /// 完成标题字号（CJK）。
  static const double end_title_font_size_cjk = 21;

  /// 完成标题字号（拉丁语系）。
  static const double end_title_font_size_alphabetic = 19;

  /// 副标题与标题间距。
  static const double end_subtitle_top_spacing = 8;

  /// 副标题字号。
  static const double end_subtitle_font_size = 13;

  /// 装饰分隔线宽高。
  static const double end_divider_width = 36;

  /// 装饰分隔线厚度。
  static const double end_divider_thickness = 2;

  /// 装饰分隔线与上文间距。
  static const double end_divider_top_spacing = 24;

  /// 操作区与分隔线间距。
  static const double end_actions_top_spacing = 28;

  /// 主按钮高度。
  static const double end_button_height = 52;

  /// 主按钮圆角。
  static const double end_button_radius = 999;

  /// 主按钮水平内边距。
  static const double end_button_padding_h = 36;

  /// 主按钮字号（CJK）。
  static const double end_button_font_size_cjk = 15;

  /// 主按钮字号（拉丁语系）。
  static const double end_button_font_size_alphabetic = 14;

  /// 次按钮与主按钮间距。
  static const double end_button_gap = 6;

  /// 次按钮高度。
  static const double end_secondary_height = 44;

  // ==================== 控件显隐动画 ====================

  /// 控件显隐动画时长。
  static const int controls_animation_ms = 240;

  /// 控件显隐动画曲线。
  static const Curve controls_curve = Curves.easeOutCubic;

  /// 隐藏时底部控件位移距离。
  static const double controls_slide_offset = 80;

  // ==================== 色彩 ====================

  /// 底部玻璃胶囊底色。
  static const Color pill_background = Color(0x1FFFFFFF);

  /// 次要文字颜色。
  static const Color muted_text = Color(0xB3FFFFFF);

  /// 禁用图标颜色。
  static const Color disabled_icon = Color(0x47FFFFFF);

  /// 平台适配字重：正文。
  static FontWeight get weight_regular =>
      FontConfig.adjustedWeight(FontWeight.w400);

  /// 平台适配字重：强调。
  static FontWeight get weight_medium =>
      FontConfig.adjustedWeight(FontWeight.w500);

  /// 按当前语种选择字号。

  static double pick_font_size({
    required bool is_cjk,
    required double cjk,
    required double alphabetic,
  }) => is_cjk ? cjk : alphabetic;
}
