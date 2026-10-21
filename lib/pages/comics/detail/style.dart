// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';

/// 漫画详情页设计令牌 — 按 UI 设计图 1:1 还原。
///
/// 视觉结构：全幅封面海报 Hero（封面卡 + 标题 + 标签 + 统计 + CTA）
/// → 白色圆角内容卡（Tab 切换 Overview / Chapters / Comments）。
class ComicDetailStyle {
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
  static const double hero_bottom_inset = 12;
  static const double tab_font_size_cjk = 15;
  static const double tab_font_size_alphabetic = 13;
  // ==================== Hero 海报 ====================

  /// 海报区域高度（含状态栏）。
  static const double hero_height = 380;

  /// 海报底部圆角，与内容卡衔接。
  static const double hero_bottom_radius = 24;

  /// 海报背景渐变遮罩（顶部透明 → 底部深色），保证白色文字可读。
  static const List<Color> hero_scrim_colors = <Color>[
    Color(0x1A000000),
    Color(0x00000000),
    Color(0x00000000),
    Color(0xB3242428),
    Color(0xFF29292C),
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
  static const double cover_card_radius = 12;

  /// 封面卡片阴影。
  static const List<BoxShadow> cover_card_shadows = <BoxShadow>[
    BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  /// 「Completed」角标。
  static const double badge_padding_h = 8;
  static const double badge_padding_v = 4;
  static const double badge_radius = 6;
  static const double badge_font_size = 11;
  static const double badge_margin = 6;

  /// 浮动导航按钮（返回 / 分享 / 更多）。
  static const double nav_button_size = 44;
  static const double nav_button_visual = 34;
  static const double nav_button_radius = 999;
  static const double nav_button_icon_size = 23;
  static const EdgeInsets nav_button_margin = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 4,
  );
  static Color nav_button_background(bool is_dark) => is_dark
      ? Colors.black.withValues(alpha: 0.58)
      : Colors.black.withValues(alpha: 0.32);

  // ==================== 标题 / 标签 / 统计 ====================

  /// 标题字号（CJK / 拉丁）。
  static const double title_font_size_cjk = 20;
  static const double title_font_size_alphabetic = 22;
  static const double title_height_cjk = 1.35;
  static const double title_height_alphabetic = 1.30;

  /// 分类标签胶囊。
  static const double tag_padding_h = 8;
  static const double tag_padding_v = 3;
  static const double tag_radius = 6;
  static const double tag_font_size = 10;
  static const double tag_spacing = 8;

  /// 统计行（评分 / 浏览 / 收藏）。
  static const double stats_spacing = 12;
  static const double stats_icon_size = 16;
  static const double stats_value_font_size = 14;
  static const double stats_label_font_size = 10;
  static const double stats_divider_width = 1;
  static const double stats_divider_height = 28;

  // ==================== CTA 按钮 ====================

  /// 「Start reading」主 CTA。
  static const double cta_height = 44;
  static const double cta_radius = 26;
  static const double cta_icon_size = 18;
  static const double cta_arrow_size = 32;
  static const double cta_font_size = 12;
  static const EdgeInsets cta_padding = EdgeInsets.symmetric(horizontal: 10);

  /// 「Save」次级 CTA。
  static const double save_width = 44;
  static const double save_icon_size = 20;

  // ==================== 内容卡 / Tab ====================

  /// 内容卡顶部圆角。
  static const double content_card_radius = 18;
  static const double content_padding_h = 20;
  static const double content_padding_top = 16;
  static const double content_padding_bottom = 32;

  /// Tab 栏。
  static const double tab_height = 48;
  static const double tab_font_size = 15;
  static const double tab_indicator_height = 3;
  static const double tab_indicator_radius = 2;
  static const double tab_badge_padding_h = 6;
  static const double tab_badge_padding_v = 2;
  static const double tab_badge_radius = 8;
  static const double tab_badge_font_size = 11;
  static const double tab_spacing = 8;

  // ==================== 区块 ====================

  /// 区块间距与标题。
  static const double section_spacing = 14;
  static const double section_title_gap = 7;
  static const double section_title_font_size = 15;
  static const double section_accent_width = 4;
  static const double section_accent_height = 16;
  static const double section_accent_radius = 2;
  static const double section_accent_gap = 8;

  /// 简介文本。
  static const double description_font_size = 12.5;
  static const double description_height = 1.3;
  static const int description_collapsed_lines = 4;
  static const double description_fade_height = 36;
  static const double description_toggle_size = 22;

  /// Genres 胶囊。
  static const double genre_chip_padding_h = 12;
  static const double genre_chip_padding_v = 6;
  static const double genre_chip_radius = 20;
  static const double genre_chip_icon_size = 14;
  static const double genre_chip_font_size = 10.5;
  static const double genre_chip_spacing = 6;

  /// Details 网格。
  static const double details_grid_spacing = 0;
  static const double details_cell_padding_v = 10;
  static const double details_icon_size = 22;
  static const double details_icon_radius = 10;
  static const double details_label_font_size = 10;
  static const double details_value_font_size = 13;
  static const double details_cell_gap = 2;

  /// Author 卡片。
  static const double author_avatar_size = 36;
  static const double author_card_radius = 14;
  static const double author_card_padding = 8;
  static const double author_name_font_size = 15;
  static const double author_chevron_size = 20;

  /// Similar comics 横向列表。
  static const double similar_card_width = 76;
  static const double similar_cover_height = 76;
  static const double similar_cover_radius = 10;
  static const double similar_title_font_size = 12;
  static const double similar_title_gap = 6;
  static const double similar_spacing = 8;
  static const double similar_see_all_font_size = 13;

  // ==================== 颜色助手 ====================

  /// 正文表面色：日间纯白、夜间深蓝黑。
  static Color card_background(bool is_dark) =>
      is_dark ? const Color(0xFF1A1E2E) : Colors.white;

  /// 页面底色。
  static Color page_background(bool is_dark) =>
      is_dark ? ColorConstants.nightBackgroundColor : const Color(0xFFF8F7F5);

  static bool is_dark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color ink(BuildContext context) =>
      is_dark(context) ? Colors.white : const Color(0xFF1A1A2E);

  static Color muted(BuildContext context) => is_dark(context)
      ? Colors.white.withValues(alpha: 0.60)
      : const Color(0xFF777985);

  static Color outline(BuildContext context) =>
      ink(context).withValues(alpha: 0.08);

  /// 主题金。
  static Color accent(BuildContext context) => const Color(0xFFFFCF18);

  /// 海报上的文字始终白色。
  static const Color hero_ink = Colors.white;
  static Color get hero_muted => Colors.white.withValues(alpha: 0.78);

  /// 标签配色（分类胶囊 / Genres 胶囊）。
  static const List<Color> tag_palette = <Color>[
    Color(0xFF00B980), // 绿
    Color(0xFF176FFF), // 蓝
    Color(0xFFEC407A), // 粉
    Color(0xFFFFA726), // 橙
    Color(0xFF7E57C2), // 紫
    Color(0xFF26C6DA), // 青
    Color(0xFFEF5350), // 红
    Color(0xFF66BB6A), // 浅绿
  ];

  static const List<Color> genre_palette = [
    Color(0xFF00B980),
    Color(0xFF176FFF),
    Color(0xFFFFA100),
    Color(0xFF824BFF),
    Color(0xFFFF4088),
  ];

  /// Details 网格单元格配色（图标底色）。
  static const List<Color> detail_icon_palette = <Color>[
    Color(0xFF66BB6A), // Status 绿
    Color(0xFF42A5F5), // Chapters 蓝
    Color(0xFF7E57C2), // Language 紫
    Color(0xFFFFA726), // Date 橙
    Color(0xFF26C6DA), // Type 青
    Color(0xFFEC407A), // Age 粉
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
