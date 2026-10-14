// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';

/// 漫画详情页设计参数：沉浸式海报头、内容卡片、章节目录集中在这里管理。
class ComicDetailStyle {
  /// 沉浸式海报高度（占屏幕宽度的比例），兼顾竖版封面的可读面积。
  static const double hero_height_factor = 1.05;

  /// 海报最小高度。
  static const double hero_min_height = 320;

  /// 海报最大高度。
  static const double hero_max_height = 520;

  /// 海报底部渐变起始位置（0~1，越小渐变覆盖越高）。
  static const double hero_gradient_start = 0.35;

  /// 海报底部渐变结束颜色不透明度。
  static const double hero_gradient_end_opacity = 0.96;

  /// 海报模糊遮罩不透明度，让标题在复杂封面上仍可读。
  static const double hero_scrim_opacity = 0.28;

  /// 内容卡片圆角，与封面卡片共用设计语言。
  static const double content_card_radius = 24;

  /// 内容卡片上移量，叠在海报渐变之上形成层次。
  static const double content_card_overlap = 28;

  /// 内容卡片水平内边距。
  static const double content_padding_h = 20;

  /// 内容卡片顶部内边距。
  static const double content_padding_top = 22;

  /// 内容卡片底部内边距。
  static const double content_padding_bottom = 32;

  /// 标题字号（CJK）。
  static const double title_font_size_cjk = 24;

  /// 标题字号（拉丁语系）。
  static const double title_font_size_alphabetic = 22;

  /// 标题行高（CJK）。
  static const double title_height_cjk = 1.35;

  /// 标题行高（拉丁语系）。
  static const double title_height_alphabetic = 1.4;

  /// 标题最大行数。
  static const int title_max_lines = 3;

  /// 原标题（与显示标题不同）字号。
  static const double original_title_font_size = 12;

  /// 作者行与标题的间距。
  static const double author_top_spacing = 12;

  /// 作者名字号。
  static const double author_font_size = 14;

  /// 作者头像直径。
  static const double author_avatar_size = 22;

  /// 作者头像与名字的间距。
  static const double author_avatar_gap = 8;

  /// 数据胶囊行与作者行的间距。
  static const double stats_top_spacing = 16;

  /// 数据胶囊水平间距。
  static const double stats_spacing = 8;

  /// 数据胶囊内边距。
  static const EdgeInsets stats_padding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 7,
  );

  /// 数据胶囊圆角。
  static const double stats_radius = 999;

  /// 数据胶囊字号。
  static const double stats_font_size = 12;

  /// 分类标签区与数据胶囊的间距。
  static const double tags_top_spacing = 16;

  /// 分类标签水平间距。
  static const double tag_spacing = 8;

  /// 分类标签换行间距。
  static const double tag_run_spacing = 8;

  /// 分类标签内边距。
  static const EdgeInsets tag_padding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 6,
  );

  /// 分类标签圆角。
  static const double tag_radius = 999;

  /// 分类标签字号（CJK）。
  static const double tag_font_size_cjk = 12;

  /// 分类标签字号（拉丁语系）。
  static const double tag_font_size_alphabetic = 11;

  /// 区块标题与上一元素的间距。
  static const double section_top_spacing = 28;

  /// 区块标题与内容的间距。
  static const double section_title_gap = 12;

  /// 区块标题字号（CJK）。
  static const double section_title_font_size_cjk = 17;

  /// 区块标题字号（拉丁语系）。
  static const double section_title_font_size_alphabetic = 16;

  /// 语种标签水平间距。
  static const double language_spacing = 8;

  /// 语种标签换行间距。
  static const double language_run_spacing = 8;

  /// 语种标签内边距。
  static const EdgeInsets language_padding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 8,
  );

  /// 语种标签圆角。
  static const double language_radius = 999;

  /// 语种标签字号。
  static const double language_font_size = 13;

  /// 简介字号（CJK）。
  static const double description_font_size_cjk = 14;

  /// 简介字号（拉丁语系）。
  static const double description_font_size_alphabetic = 13;

  /// 简介行高（CJK）。
  static const double description_height_cjk = 1.7;

  /// 简介行高（拉丁语系）。
  static const double description_height_alphabetic = 1.75;

  /// 简介收起时最大行数。
  static const int description_collapsed_lines = 4;

  /// 简介底部渐变遮罩高度，箭头居中浮于其上。
  static const double description_fade_height = 36;

  /// 简介展开/收起箭头图标尺寸。
  static const double description_toggle_icon_size = 26;

  /// 简介箭头旋转动画时长。
  static const int description_toggle_animation_ms = 240;

  /// 章节条目垂直内边距。
  static const double chapter_padding_v = 14;

  /// 章节条目水平内边距。
  static const double chapter_padding_h = 16;

  /// 章节条目间距。
  static const double chapter_spacing = 8;

  /// 章节条目圆角。
  static const double chapter_radius = 14;

  /// 章节序号宽度。
  static const double chapter_number_width = 36;

  /// 章节序号字号。
  static const double chapter_number_font_size = 15;

  /// 章节标题字号。
  static const double chapter_title_font_size = 15;

  /// 章节标题最大行数。
  static const int chapter_title_max_lines = 2;

  /// 章节元信息字号。
  static const double chapter_meta_font_size = 12;

  /// 章节元信息与标题的间距。
  static const double chapter_meta_top_spacing = 4;

  /// 底部操作栏水平内边距。
  static const double action_bar_padding_h = 20;

  /// 底部操作栏垂直内边距。
  static const double action_bar_padding_v = 12;

  /// 底部操作栏按钮间距。
  static const double action_bar_spacing = 12;

  /// 底部操作栏按钮高度。
  static const double action_bar_button_height = 52;

  /// 底部操作栏按钮圆角。
  static const double action_bar_button_radius = 16;

  /// 底部操作栏主按钮字号。
  static const double action_bar_primary_font_size = 16;

  /// 底部操作栏次按钮字号。
  static const double action_bar_secondary_font_size = 14;

  /// 底部操作栏次按钮最小宽度。
  static const double action_bar_secondary_min_width = 108;

  /// 底部操作栏次按钮最大宽度。
  static const double action_bar_secondary_max_width = 150;

  /// 返回按钮尺寸。
  static const double back_button_size = 48;

  /// 返回按钮圆角。
  static const double back_button_radius = 12;

  /// 返回按钮图标尺寸。
  static const double back_icon_size = 22;

  /// 顶部悬浮操作区外边距。
  static const EdgeInsets floating_action_margin = EdgeInsets.all(16);

  /// 海报上返回按钮与评论按钮的间距。
  static const double floating_action_spacing = 10;

  /// 深色模式内容卡片背景。
  static const Color content_card_dark = Color(0xFF12151C);

  /// 浅色模式内容卡片背景。
  static const Color content_card_light = Colors.white;

  /// 深色模式次级表面（章节条目、胶囊）。
  static const Color surface_dark = Color(0xFF1C2130);

  /// 浅色模式次级表面。
  static const Color surface_light = Color(0xFFF4F6FA);

  /// 数据胶囊深色模式背景不透明度。
  static const double stats_bg_dark_opacity = 0.16;

  /// 数据胶囊浅色模式背景不透明度。
  static const double stats_bg_light_opacity = 0.08;

  /// 海报悬浮按钮背景不透明度。
  static const double floating_button_bg_opacity = 0.42;

  /// 海报悬浮按钮模糊半径。
  static const double floating_button_blur = 16;

  /// 标题阴影不透明度。
  static const double title_shadow_opacity = 0.45;

  /// 标题阴影模糊半径。
  static const double title_shadow_blur = 18;

  /// 平台适配字重：正文。
  static FontWeight get weight_regular =>
      FontConfig.adjustedWeight(FontWeight.w400);

  /// 平台适配字重：强调。
  static FontWeight get weight_medium =>
      FontConfig.adjustedWeight(FontWeight.w500);

  /// 按当前语种选择字号：CJK 与拉丁语系字宽不同。
  static double pick_font_size({
    required bool is_cjk,
    required double cjk,
    required double alphabetic,
  }) => is_cjk ? cjk : alphabetic;

  /// 点击波纹颜色。
  static Color ripple_color(BuildContext context, bool is_dark) =>
      ColorConstants.themeColor.withValues(alpha: 0.12);
}
