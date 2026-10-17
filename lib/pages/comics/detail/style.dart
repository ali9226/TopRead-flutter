// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/config/layout_config.dart';
import 'package:app/pages/comics/style.dart';
import 'package:app/pages/read/widgets/introduction_section/style.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/author_section/style.dart';
import 'package:app/pages/read/widgets/read_directory_sheet/style.dart';

/// TODO 漫画详情沿用小说介绍和目录的令牌；仅保留漫画语种、页数及续读所需参数。
class ComicDetailStyle {
  /// 封面全屏宽度，高度固定，顶部贯穿状态栏。
  static const double cover_height = 400;

  /// 封面底部圆角，与内容卡片衔接。
  static const double cover_radius = 20;

  /// 封面与内容卡片的重叠量。
  static const double cover_overlap = 24;
  static const double content_padding_h = LayoutConfig.page_horizontal_padding;
  static const double content_padding_top = IntroductionStyle.title_top_spacing;
  static const double content_padding_bottom = 32;
  static const double title_font_size_cjk = IntroductionStyle.title_font_size;
  static const double title_font_size_alphabetic =
      IntroductionStyle.title_font_size;
  static const double title_height_cjk = 1.35;
  static const double title_height_alphabetic = 1.4;
  static const double original_title_spacing = 6;
  static const double author_top_spacing = IntroductionStyle.author_top_spacing;
  static const double author_avatar_size = AuthorStyle.author_avatar_size;
  static const int author_avatar_variants = 10;
  static const double author_avatar_gap = AuthorStyle.author_name_left_spacing;
  static const double stats_top_spacing =
      IntroductionStyle.stat_panel_top_spacing;
  static const double stats_spacing = 12;
  static const double tags_top_spacing =
      IntroductionStyle.tag_section_top_spacing;
  static const double section_top_spacing = 24;
  static const double section_title_gap = 8;
  static const double section_title_font_size_cjk = 16;
  static const double section_title_font_size_alphabetic = 15;

  /// TODO 着色区自然包住文本，48高的透明点击区不参与视觉标签的上下内边距。
  static const double language_spacing = 8;
  static const double language_run_spacing = 0;
  static const double language_visual_height = 32;
  static const double language_radius = LayoutConfig.section_radius;
  static const double language_line_height = 1.4;
  static const double language_selected_alpha = 0.18;
  static const EdgeInsets language_padding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 6,
  );
  static const double label_size_cjk = 13;
  static const double label_size_alphabetic = 12;
  static const double label_height_cjk = 1.5;
  static const double label_height_alphabetic = 1.6;

  static const double description_font_size_cjk = 14;
  static const double description_font_size_alphabetic = 13;
  static const double description_height_cjk = 1.7;
  static const double description_height_alphabetic = 1.75;
  static const int description_collapsed_lines = 4;
  static const double description_fade_height = 36;
  static const double description_toggle_icon_size = 20;
  static const int description_toggle_animation_ms = 240;
  static const double description_toggle_spacing = 4;

  /// TODO 目录用小说相同的透明行、细分隔线及当前章标记，不再为每章创建独立卡片。
  static const double chapter_padding_v =
      ReadDirectorySheetStyle.chapter_item_vertical_padding;
  static const double chapter_separator_height =
      ReadDirectorySheetStyle.chapter_separator_height;
  static const double chapter_number_width =
      ReadDirectorySheetStyle.chapter_number_width;
  static const double chapter_title_gap =
      ReadDirectorySheetStyle.chapter_number_title_spacing;
  static const double chapter_title_font_size =
      ReadDirectorySheetStyle.chapter_title_font_size_cjk;
  static const int chapter_title_max_lines = 2;
  static const double chapter_marker_width =
      ReadDirectorySheetStyle.current_chapter_bar_width;
  static const double chapter_marker_height = 24;
  static const double chapter_marker_radius =
      ReadDirectorySheetStyle.current_chapter_bar_radius;
  static const double chapter_marker_gap = 8;

  static const double action_bar_padding_h =
      LayoutConfig.page_horizontal_padding;
  static const double action_bar_padding_v = 10;
  static const double action_bar_spacing = 12;
  static const double action_bar_button_height = 48;
  static const double collect_icon_size = 22;
  static const double action_bar_button_radius = LayoutConfig.section_radius;
  static const double action_bar_primary_font_size = 15;
  static const double action_bar_secondary_font_size = 14;
  static const double action_text_line_height_cjk = 1.4;
  static const double action_text_line_height_alphabetic = 1.5;
  static const EdgeInsets collect_padding = EdgeInsets.symmetric(
    horizontal: 4,
    vertical: 10,
  );
  static const EdgeInsets read_padding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 10,
  );

  /// TODO 导航遵照用户指定的透明黑/白对照，视觉圆形36，完整命中区48，无描边和阴影。
  static const double touch_target = 48;
  static const double floating_visual_size = 36;
  static const double back_icon_size = 18;
  static const EdgeInsets floating_action_margin = EdgeInsets.symmetric(
    horizontal: LayoutConfig.page_horizontal_padding,
    vertical: 4,
  );
  static Color floating_background(bool is_dark) => is_dark
      ? Colors.white.withValues(alpha: 0.78)
      : Colors.black.withValues(alpha: 0.56);
  static Color floating_foreground(bool is_dark) =>
      is_dark ? Colors.black : Colors.white;
  static Color card_background(bool is_dark) =>
      is_dark ? ColorConstants.nightBackgroundColor : Colors.white;
  static Color get surface_dark => ColorConstants.sheetInputBackground(true);
  static Color get surface_light => ColorConstants.sheetInputBackground(false);
  static bool is_dark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
  static Color ink(BuildContext context) =>
      is_dark(context) ? Colors.white : ColorConstants.lightTextColor;
  static Color muted(BuildContext context) => is_dark(context)
      ? Colors.white.withValues(alpha: 0.68)
      : const Color(0xFF7A6A56);
  static Color outline(BuildContext context) =>
      ink(context).withValues(alpha: 0.08);

  static Duration animation_duration(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ||
          MediaQuery.accessibleNavigationOf(context)
      ? Duration.zero
      : const Duration(milliseconds: description_toggle_animation_ms);
  static TextStyle label_style(
    BuildContext context,
    bool is_cjk, {
    Color? color,
    bool strong = false,
  }) => (Theme.of(context).textTheme.bodyMedium ?? const TextStyle()).copyWith(
    fontSize: is_cjk ? label_size_cjk : label_size_alphabetic,
    height: is_cjk ? label_height_cjk : label_height_alphabetic,
    color: color ?? ink(context),
    fontWeight: strong ? weight_medium : weight_regular,
  );
  static TextStyle text(
    BuildContext context, {
    double? size,
    bool strong = false,
    Color? color,
  }) => ComicsStyle.text(
    context,
    size: size,
    strong: strong,
    color: color ?? ink(context),
  );
  static ButtonStyle text_button(BuildContext context) =>
      ComicsStyle.text_button(
        context,
      ).copyWith(foregroundColor: WidgetStatePropertyAll(ink(context)));
  static FontWeight get weight_regular =>
      FontConfig.adjustedWeight(FontWeight.w400);
  static FontWeight get weight_medium =>
      FontConfig.adjustedWeight(FontWeight.w500);
  static double pick_font_size({
    required bool is_cjk,
    required double cjk,
    required double alphabetic,
  }) => is_cjk ? cjk : alphabetic;
}
