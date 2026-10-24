// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:app/config/layout_config.dart';
import 'package:app/config/color_config.dart';
import 'package:app/components/reader_bottom_action/style.dart';
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';
import 'package:app/pages/comics/style.dart';
import 'package:app/pages/short_story_read/style.dart';

/// TODO 漫画画布、小说风格阅读工具栏与章节收尾区的设计参数统一管理。
/// 控件使用稳定对比度，隐藏后保留完整图片画布，日间与夜间分别配置颜色。
class ComicReaderStyle {
  /// 顶部直接复用短篇 SVG 的尺寸与原始多色，避免同一图形在三类阅读器内粗细不同。
  static const double top_favorite_icon_size = 22;
  static const double top_share_icon_size = 20;

  static Color? top_favorite_icon_color(bool dark, {required bool collected}) =>
      collected
      ? (dark
            ? ColorConstants
                  .components_fixed_bottom_navigation_style_tone_ffd0d4db
                  .withValues(alpha: 0.82)
            : null)
      : (dark
            ? ShortStoryReadStyle.secondary_dark_color
            : ShortStoryReadStyle.title_light_color);

  static Color top_share_icon_color(bool dark) => dark
      ? ColorConstants.components_fixed_bottom_navigation_style_tone_ffd0d4db
            .withValues(alpha: 0.82)
      : ShortStoryReadStyle.title_light_color;

  /// TODO 松开进度滑块后的定位过渡时长。
  static const Duration progress_seek_duration = Duration(milliseconds: 320);
  static const double page_scroll_fraction = 1;

  /// 与小说阅读器保持同样的方向判定阈值，避免滚动中的轻微抖动切换导航栏。
  static const double navigation_scroll_threshold = 8;
  static const int page_scroll_ms = 280;
  static const double auto_min_speed = 20;
  static const double auto_speed_range = 280;
  static const double auto_delta_limit = 0.1;
  static const double auto_button_inset = LayoutConfig.space_20;
  static double title_size(BuildContext context) => ComicsStyle.is_cjk(context)
      ? title_font_size_cjk
      : title_font_size_alphabetic;
  static double top_bar_height(BuildContext context) =>
      (MediaQuery.textScalerOf(context).scale(title_size(context)) * 1.3 + 12)
          .clamp(control_target, double.infinity);
  static double bottom_bar_height(BuildContext context) =>
      ReaderBottomActionStyle.row_height(context);
  static Color canvas_color(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? canvas_background
      : ColorConstants.whiteColor;

  /// TODO 实色控件底板随主题变化，不能依赖漫画图片自身颜色产生对比。
  static Color panel_background(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? ColorConstants.components_reader_top_bar_style_tone
      : ColorConstants.whiteColor;
  static Color foreground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? ColorConstants.whiteColor
      : ColorConstants.components_reader_top_bar_style_tone_ff1f1a12;
  static Color secondary_foreground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? ColorConstants.components_reader_bottom_action_style_tone_b2ffffff
      : ColorConstants.components_reader_top_bar_style_tone_ff7a6a56;
  static Color border_color(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? ColorConstants.components_reader_top_bar_style_tone_ff21262d
      : ColorConstants.components_reader_top_bar_style_tone_ffeeeeee;
  static Color disabled_color(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? ColorConstants.pages_comics_reader_style_tone
      : ColorConstants.pages_comics_reader_style_tone_ff777e88;
  static const double control_target = 48;
  static Color track_background(BuildContext context) =>
      secondary_foreground(context).withValues(alpha: 0.15);
  static double action_label_size(BuildContext context) =>
      ComicsStyle.is_cjk(context) ? 11 : 10;
  static const double toolbar_padding = LayoutConfig.space_8;
  static const double top_title_padding = LayoutConfig.space_6;
  static const double divider_width = 0.5;
  static const double progress_radius = LayoutConfig.radius_4;
  static const double progress_label_gap = LayoutConfig.space_4;
  static const double action_label_gap = LayoutConfig.space_4;
  static const double progress_horizontal_padding = LayoutConfig.space_6;
  static const double control_radius = LayoutConfig.radius_8;
  static const double control_padding = LayoutConfig.space_4;
  static const double control_vertical_padding = LayoutConfig.space_5;
  static const double control_icon_gap = LayoutConfig.space_6;
  static const double control_font_cjk = 14;
  static const double control_font_alphabetic = 13;
  static const double subtitle_size = 11;

  /// 阅读画布最大宽度，超宽屏居中留白。
  static const double canvas_max_width = 920;

  /// 画布背景色（近黑，减少 OLED 发光）。
  static const Color canvas_background =
      ColorConstants.canvas_background_ff0a0b0e;

  // ==================== 顶部工具条 ====================

  /// 标题字号（CJK）。
  static const double title_font_size_cjk = 14;

  /// 标题字号（拉丁语系）。
  static const double title_font_size_alphabetic = 13;

  // ==================== 页进度 ====================

  /// 页进度轨道高度。
  static const double progress_track_height = 2.5;

  /// 进度条已读部分颜色。
  static final Color progress_active_color = ColorConstants.themeColor;

  /// 进度条未读部分颜色。
  static const Color progress_inactive_color =
      ColorConstants.components_work_hero_stats_style_tone_33ffffff;

  // ==================== 底部控制条 ====================

  /// 页码字号。
  static const double page_font_size = 11;

  /// 章节切换按钮图标尺寸。
  static const double nav_icon_size = LayoutConfig.icon_compact;

  // ==================== 章节收尾区 ====================

  /// 章节收尾区顶部留白。
  static const double end_section_top_spacing = LayoutConfig.space_72;

  /// 章节收尾区底部留白。
  static const double end_section_bottom_spacing = 120;

  /// 章节收尾区水平内边距。
  static const double end_section_padding_h = LayoutConfig.space_32;

  /// 完成图标圆形容器尺寸。
  static const double end_icon_container = 56;

  /// 完成图标尺寸。
  static const double end_icon_size = 30;

  /// 标题与图标间距。
  static const double end_title_top_spacing = LayoutConfig.space_20;

  /// 完成标题字号（CJK）。
  static const double end_title_font_size_cjk = 21;

  /// 完成标题字号（拉丁语系）。
  static const double end_title_font_size_alphabetic = 19;

  /// 副标题与标题间距。
  static const double end_subtitle_top_spacing = LayoutConfig.space_8;

  /// 副标题字号。
  static const double end_subtitle_font_size = 13;

  /// 装饰分隔线宽高。
  static const double end_divider_width = 36;

  /// 装饰分隔线厚度。
  static const double end_divider_thickness = 2;

  /// 装饰分隔线与上文间距。
  static const double end_divider_top_spacing = LayoutConfig.space_24;

  /// 操作区与分隔线间距。
  static const double end_actions_top_spacing = LayoutConfig.space_28;

  /// 主按钮高度。
  static const double end_button_height = 52;

  /// 主按钮圆角。
  static const double end_button_radius = LayoutConfig.radius_pill;

  /// 主按钮水平内边距。
  static const double end_button_padding_h = LayoutConfig.space_36;

  /// 主按钮字号（CJK）。
  static const double end_button_font_size_cjk = 15;

  /// 主按钮字号（拉丁语系）。
  static const double end_button_font_size_alphabetic = 14;

  /// 次按钮与主按钮间距。
  static const double end_button_gap = LayoutConfig.space_6;

  /// 次按钮高度。
  static const double end_secondary_height = 48;

  // ==================== 控件显隐动画 ====================

  /// 控件显隐动画时长。
  static const int controls_animation_ms = 240;

  /// TODO 系统减少动画时操作条立即显隐，保留手势与无障碍语义。
  static Duration controls_duration(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ||
          MediaQuery.accessibleNavigationOf(context)
      ? Duration.zero
      : const Duration(milliseconds: controls_animation_ms);

  /// 控件显隐动画曲线。
  static const Curve controls_curve = Curves.easeOutCubic;

  // ==================== 色彩 ====================

  /// 次要文字颜色。
  static const Color muted_text =
      ColorConstants.components_reader_top_bar_style_tone_b3ffffff;

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
