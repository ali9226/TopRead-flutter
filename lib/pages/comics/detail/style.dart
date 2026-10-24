// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/config/layout_config.dart';

/// 漫画详情页设计令牌 — 按 UI 设计图 1:1 还原。
///
/// 视觉结构：全幅封面海报 Hero（封面卡 + 标题 + 标签 + 统计 + CTA）
/// → 白色圆角内容卡（Tab 切换 Overview / Chapters / Comments）。
class ComicDetailStyle {
  /// 已加载内容与首屏骨架使用同一最大宽度，窗口伸展时保持几何一致。
  static const double page_max_width = 600;
  static const String public_url = String.fromEnvironment(
    'APP_PUBLIC_URL',
    defaultValue: 'https://app.read.top',
  );
  static const Duration transition_duration = Duration(milliseconds: 240);
  static const double chapter_hero_height_ratio = 0.60;
  static const double chapter_cover_width_ratio = 0.282;
  static const double chapter_cover_aspect_ratio = 1.2;
  static const double cover_max_width = 160;
  static const double hero_max_height = 420;
  static const double chapter_hero_max_height = 340;
  static const double hero_viewport_ratio = 0.68;
  static const double design_width = 430;
  static const double hero_height_ratio = 0.823;
  static const double cover_width_ratio = 0.313;
  static const double cover_aspect_ratio = 1.49;
  static const double hero_inset_ratio = 0.049;
  static const double hero_bottom_inset = LayoutConfig.space_12;
  static const double tab_font_size_cjk = 15;
  static const double tab_font_size_alphabetic = 13;
  // ==================== Hero 海报 ====================

  /// 海报区域高度（含状态栏）。
  static const double hero_height = 380;

  /// 海报底部圆角，与内容卡衔接。
  static const double hero_bottom_radius = LayoutConfig.radius_24;

  /// 海报背景渐变遮罩（顶部透明 → 底部深色），保证白色文字可读。
  static const List<Color> hero_scrim_colors = <Color>[
    ColorConstants.pages_short_story_read_widgets_collapse_button_tone_1a222222,
    ColorConstants.transparent,
    ColorConstants.transparent,
    ColorConstants.backdrop_scrim_night,
    ColorConstants.backdrop_placeholder_dark,
  ];
  static const List<double> hero_scrim_stops = <double>[
    0.0,
    0.12,
    0.38,
    0.64,
    1.0,
  ];

  /// 封面卡片尺寸。
  static const double cover_card_width = 100;
  static const double cover_card_height = 134;
  static const double cover_card_radius = LayoutConfig.radius_12;

  /// 封面卡片阴影。
  static const List<BoxShadow> cover_card_shadows = <BoxShadow>[
    BoxShadow(
      color: ColorConstants.shadow_medium_33,
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  /// 「Completed」角标。
  static const double badge_padding_h = LayoutConfig.space_8;
  static const double badge_padding_v = LayoutConfig.space_4;
  static const double badge_radius = LayoutConfig.radius_6;
  static const double badge_font_size = 10;
  static const double badge_margin = LayoutConfig.space_6;

  /// 浮动导航按钮（返回 / 分享 / 更多）。
  static const double nav_button_size = LayoutConfig.compact_control_height;
  static const double nav_button_visual = 34;
  static const double nav_button_radius = LayoutConfig.radius_pill;
  static const double nav_button_icon_size = 23;
  static const EdgeInsets nav_button_margin = EdgeInsets.symmetric(
    horizontal: LayoutConfig.space_16,
    vertical: LayoutConfig.space_4,
  );
  static Color nav_button_background(bool is_dark) => is_dark
      ? ColorConstants.pages_comics_detail_style_tone
      : ColorConstants.pages_comics_detail_style_tone_52222222;

  // ==================== 标题 / 标签 / 统计 ====================

  /// 标题字号（CJK / 拉丁）。
  static const double title_font_size_cjk = 20;
  static const double title_font_size_alphabetic = 22;
  static const double title_height_cjk = 1.35;
  static const double title_height_alphabetic = 1.30;

  /// 分类标签胶囊。
  static const double tag_padding_h = LayoutConfig.space_8;
  static const double tag_padding_v = LayoutConfig.space_3;
  static const double tag_radius = LayoutConfig.radius_6;
  static const double tag_font_size = 10;
  static const double tag_spacing = LayoutConfig.space_8;

  /// 统计行（评分 / 浏览 / 收藏）。
  static const double stats_spacing = LayoutConfig.space_12;
  static const double stats_icon_size = LayoutConfig.icon_small;
  static const double stats_value_font_size = 14;
  static const double stats_label_font_size = 10;
  static const double stats_divider_width = 1;
  static const double stats_divider_height = 28;

  // ==================== CTA 按钮 ====================

  /// 「Start reading」主 CTA。
  static const double cta_height = LayoutConfig.compact_control_height;
  static const double cta_radius = LayoutConfig.radius_26;
  static const double cta_icon_size = 18;
  static const double cta_arrow_size = 32;
  static const double cta_font_size = 12;
  static const double quick_action_padding = LayoutConfig.space_16;
  static const double quick_action_inner_padding = LayoutConfig.space_12;
  static const double quick_action_gap = LayoutConfig.space_8;
  static const double quick_action_height =
      LayoutConfig.prominent_button_height;
  static const double quick_action_icon_size = LayoutConfig.icon_medium;
  static const double quick_action_arrow_size = 18;
  static const double quick_action_font_cjk = 14;
  static const double quick_action_font_alphabetic = 12;
  static const double quick_action_count_cjk = 12;
  static const double quick_action_count_alphabetic = 11;
  static const double quick_action_count_gap = LayoutConfig.space_3;
  static const double quick_action_line_height = 1.35;
  static const double cta_font_size_cjk = 13;
  static const double cta_font_size_alphabetic = 12;
  static const double hero_author_size_cjk = 14;
  static const double hero_author_size_alphabetic = 13;
  static const double hero_metadata_line_height = 1.35;
  static const double hero_metadata_gap = LayoutConfig.space_9;
  static const double hero_action_gap = LayoutConfig.space_8;
  static const double hero_stats_label_cjk = 11;
  static const double hero_stats_label_alphabetic = 10;
  static const double hero_stat_divider_alpha = 0.18;
  static const double hero_action_alpha = 0.2;
  static const double surface_action_alpha = 0.06;
  static const EdgeInsets cta_padding = EdgeInsets.symmetric(
    horizontal: LayoutConfig.space_10,
    vertical: LayoutConfig.space_10,
  );

  /// 「Save」次级 CTA。
  static const double save_width = 44;
  static const double save_icon_size = LayoutConfig.icon_medium;

  // ==================== 内容卡 / Tab ====================

  /// 内容卡顶部圆角。
  static const double content_card_radius = LayoutConfig.radius_18;
  static const double content_padding_h = LayoutConfig.page_horizontal_padding;
  static const double content_padding_top = LayoutConfig.space_16;

  /// 纸面向上覆盖一像素，遮住独立海报圆角绘制在亚像素边界的接缝。
  static const double content_seam_overlap = 1;
  static const double content_padding_bottom = LayoutConfig.space_32;

  /// Tab 栏。
  static const double tab_height = 48;
  static const double tab_font_size = 15;
  static const double tab_indicator_height = 3;
  static const double tab_indicator_radius = LayoutConfig.radius_2;
  static const double tab_badge_padding_h = LayoutConfig.space_6;
  static const double tab_badge_padding_v = LayoutConfig.space_2;
  static const double tab_badge_radius = LayoutConfig.radius_8;
  static const double tab_badge_font_size = 11;
  static const double tab_spacing = LayoutConfig.space_8;

  // ==================== 区块 ====================

  /// 区块间距与标题。
  static const double section_spacing = LayoutConfig.space_14;
  static const double section_title_gap = LayoutConfig.space_7;
  static const double section_title_font_size = 15;
  static const double section_accent_width = 4;
  static const double section_accent_height = 16;
  static const double section_accent_radius = LayoutConfig.radius_2;
  static const double section_accent_gap = LayoutConfig.space_8;

  /// 简介文本。
  static const double description_font_size = 12.5;
  static const double description_height = 1.3;
  static const int description_collapsed_lines = 4;
  static const double description_fade_height = 36;
  static const double description_toggle_size = 22;

  /// Genres 胶囊。
  static const double genre_chip_padding_h = LayoutConfig.space_12;
  static const double genre_chip_padding_v = LayoutConfig.space_6;
  static const double genre_chip_radius = LayoutConfig.radius_20;
  static const double genre_chip_icon_size = 14;
  static const double genre_chip_font_size = 10.5;
  static const double genre_chip_spacing = LayoutConfig.space_6;

  /// Details 网格。
  static const double details_grid_spacing = 0;
  static const double details_cell_padding_v = LayoutConfig.space_10;
  static const double details_icon_size = LayoutConfig.icon_compact;
  static const double details_icon_radius = LayoutConfig.radius_10;
  static const double details_label_font_size = 10;
  static const double details_value_font_size = 13;
  static const double details_cell_gap = LayoutConfig.space_2;

  /// Author 卡片。
  static const double author_avatar_size = 36;
  static const double author_card_radius = LayoutConfig.radius_14;
  static const double author_card_padding = LayoutConfig.space_8;
  static const double author_name_font_size = 15;
  static const double author_chevron_size = 20;

  /// Similar comics 横向列表。
  static const double similar_card_width = 76;
  static const double similar_cover_height = 76;
  static const double similar_cover_radius = LayoutConfig.radius_10;
  static const double similar_title_font_size = 12;
  static const double similar_title_gap = LayoutConfig.space_6;
  static const double similar_spacing = LayoutConfig.space_8;
  static const double similar_see_all_font_size = 13;

  // ==================== 颜色助手 ====================

  /// 正文表面色：日间纯白、夜间深蓝黑。
  static Color card_background(bool is_dark) => is_dark
      ? ColorConstants.pages_comics_detail_style_tone_ff1a1e2e
      : ColorConstants.whiteColor;

  /// 页面底色。
  static Color page_background(bool is_dark) =>
      is_dark ? ColorConstants.nightBackgroundColor : ColorConstants.whiteColor;

  static bool is_dark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color ink(BuildContext context) => is_dark(context)
      ? ColorConstants.whiteColor
      : ColorConstants.pages_comics_detail_style_tone_ff1a1a2e;

  static Color muted(BuildContext context) => is_dark(context)
      ? ColorConstants.components_load_more_footer_index_tone
      : ColorConstants.pages_comics_detail_style_tone_ff777985;

  static Color outline(BuildContext context) =>
      ink(context).withValues(alpha: 0.08);

  /// 主题金。
  static Color accent(BuildContext context) =>
      ColorConstants.pages_comics_detail_style_tone_ffffcf18;

  /// 海报上的文字始终白色。
  static const Color hero_ink = ColorConstants.whiteColor;
  static Color get hero_muted =>
      ColorConstants.components_home_top_search_entry_index_tone_c7ffffff;

  /// 标签配色（分类胶囊 / Genres 胶囊）。
  static const List<Color> tag_palette = <Color>[
    ColorConstants.palette_mint, // 绿
    ColorConstants.palette_blue, // 蓝
    ColorConstants.palette_pink, // 粉
    ColorConstants.palette_tangerine, // 橙
    ColorConstants.palette_purple, // 紫
    ColorConstants.palette_cyan, // 青
    ColorConstants.hero_ink_ffef5350, // 红
    ColorConstants.palette_green, // 浅绿
  ];

  static const List<Color> genre_palette = [
    ColorConstants.palette_mint,
    ColorConstants.palette_blue,
    ColorConstants.hero_ink_ffffa100,
    ColorConstants.hero_ink_ff824bff,
    ColorConstants.hero_ink_ffff4088,
  ];

  /// Details 网格单元格配色（图标底色）。
  static const List<Color> detail_icon_palette = <Color>[
    ColorConstants.palette_green, // Status 绿
    ColorConstants.hero_ink_ff42a5f5, // Chapters 蓝
    ColorConstants.palette_purple, // Language 紫
    ColorConstants.palette_tangerine, // Date 橙
    ColorConstants.palette_cyan, // Type 青
    ColorConstants.palette_pink, // Age 粉
  ];

  /// 统计数字格式化：>999 显示 K，>999999 显示 M。
  static String format_count(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return '$count';
  }

  /// 字重助手。
  static FontWeight get weight_regular =>
      FontConfig.adjustedWeight(FontWeight.w400);
  static FontWeight get weight_medium =>
      FontConfig.adjustedWeight(FontWeight.w500);
  static FontWeight get weight_semi_bold =>
      FontConfig.adjustedWeight(FontWeight.w600);

  /// 按语种选择字号。
  static double pick_font_size({
    required bool is_cjk,
    required double cjk,
    required double alphabetic,
  }) => is_cjk ? cjk : alphabetic;
}
