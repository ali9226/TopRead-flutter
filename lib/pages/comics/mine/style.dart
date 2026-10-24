// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:app/config/layout_config.dart';
import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/pages/comics/style.dart';
import 'package:flutter/material.dart';

/// 「我的漫画」列表页设计参数：状态角标、卡片操作层与空状态集中在这里管理。
class ComicsMineStyle {
  /// 页面标题字号（CJK）。
  static const double title_font_size_cjk = 22;

  /// 页面标题字号（拉丁语系，单词更宽需略缩）。
  static const double title_font_size_alphabetic = 20;

  /// 页面副标题字号（CJK）。
  static const double subtitle_font_size_cjk = 13;

  /// 页面副标题字号（拉丁语系）。
  static const double subtitle_font_size_alphabetic = 12;

  /// 标题与副标题的间距。
  static const double subtitle_top_spacing = LayoutConfig.space_4;

  /// 头部与网格的间距。
  static const double header_bottom_spacing = LayoutConfig.space_16;

  /// 状态角标字号。
  static const double status_font_size = 11;

  /// 状态角标水平内边距（CJK）。
  static const double status_padding_h_cjk = LayoutConfig.space_8;

  /// 状态角标水平内边距（拉丁语系，单词更宽需更大留白）。
  static const double status_padding_h_alphabetic = 10;

  /// 状态角标垂直内边距。
  static const double status_padding_v = LayoutConfig.space_4;

  /// 状态角标圆角。
  static const double status_radius = LayoutConfig.radius_pill;

  /// 状态角标与卡片边缘的间距。
  static const EdgeInsets status_margin = EdgeInsets.fromLTRB(
    LayoutConfig.space_8,
    LayoutConfig.space_8,
    LayoutConfig.space_8,
    0,
  );

  /// 卡片点击去编辑的遮罩不透明度。
  static const double edit_overlay_opacity = 0.28;

  /// 悬浮按钮水平内边距。
  static const double fab_padding_h = LayoutConfig.space_18;

  /// 悬浮按钮垂直内边距。
  static const double fab_padding_v = LayoutConfig.space_14;

  /// 悬浮按钮圆角。
  static const double fab_radius = LayoutConfig.radius_pill;

  /// 悬浮按钮图标与文字间距。
  static const double fab_icon_spacing = LayoutConfig.space_8;

  /// 悬浮按钮图标尺寸。
  static const double fab_icon_size = LayoutConfig.icon_compact;

  /// 悬浮按钮投影模糊半径。
  static const double fab_shadow_blur = 18;

  /// 悬浮按钮投影偏移。
  static const Offset fab_shadow_offset = Offset(0, 8);

  /// 悬浮按钮投影不透明度。
  static const double fab_shadow_opacity = 0.28;

  /// 加载更多区与网格的间距。
  static const double load_more_top_spacing = LayoutConfig.space_8;

  /// 空状态操作按钮与文案的间距。
  static const double empty_action_top_spacing = LayoutConfig.space_20;

  /// 草稿横幅内边距。
  static const EdgeInsets banner_padding = EdgeInsets.symmetric(
    horizontal: LayoutConfig.space_14,
    vertical: LayoutConfig.space_12,
  );

  /// 草稿横幅圆角。
  static const double banner_radius = LayoutConfig.radius_14;

  /// 草稿横幅与内容的间距。
  static const double banner_bottom_spacing = LayoutConfig.space_12;

  /// 状态角标背景不透明度。
  static const double status_background_opacity = 0.90;

  /// 状态角标文字不透明度。
  static const double status_text_opacity = 1.0;

  /// 主按钮背景：主题金。
  static Color primary_background(BuildContext context) =>
      ColorConstants.themeColor;

  /// 主按钮文字：深色，保证金底可读。
  static Color primary_foreground(BuildContext context) =>
      ColorConstants.lightTextColor;

  /// 主按钮文字样式。
  static TextStyle primary_text(BuildContext context) => TextStyle(
    fontSize: ComicsStyle.is_cjk(context)
        ? ComicsStyle.body_font_size_cjk
        : ComicsStyle.body_font_size_alphabetic,
    fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
    color: primary_foreground(context),
  );
}

/// 「我的漫画」状态角标配色：按发布状态区分语义色，日夜主题均保持可读。
class ComicsMineStatusStyle {
  /// 角标圆角，与卡片标签共用胶囊形。
  static const double badge_radius = LayoutConfig.radius_pill;

  /// 角标字号。
  static const double badge_font_size = 11;

  /// 角标水平内边距（CJK）。
  static const double badge_padding_h_cjk = LayoutConfig.space_8;

  /// 角标水平内边距（拉丁语系）。
  static const double badge_padding_h_alphabetic = 10;

  /// 角标垂直内边距。
  static const double badge_padding_v = LayoutConfig.space_4;

  /// 草稿：中性灰蓝。
  static Color draft(BuildContext context) => ColorConstants.components_recommend_book_card_index_tone_ff8b93a2;

  /// 审核中：琥珀黄，与主题金同系但更沉稳。
  static Color pending(BuildContext context) => ColorConstants.pages_comics_mine_style_tone;

  /// 已发布：成功绿。
  static Color published(BuildContext context) => ColorConstants.successColor;

  /// 已驳回：危险红。
  static Color rejected(BuildContext context) => ColorConstants.dangerColor;

  /// 已隐藏：弱化墨色。
  static Color hidden(BuildContext context) =>
      ComicsStyle.muted(context).withValues(alpha: 0.85);

  /// 按状态字符串取色，未知状态回退到草稿中性色。
  static Color of(BuildContext context, String status) {
    switch (status) {
      case 'pending':
        return pending(context);
      case 'published':
        return published(context);
      case 'rejected':
        return rejected(context);
      case 'hidden':
        return hidden(context);
      default:
        return draft(context);
    }
  }
}
