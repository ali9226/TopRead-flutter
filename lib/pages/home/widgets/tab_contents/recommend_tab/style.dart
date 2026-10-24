import 'package:flutter/material.dart';
import 'package:app/config/layout_config.dart';

/// 推荐 Tab 内容样式常量。
class RecommendTabStyle {
  /// 卡片圆角。
  static const double card_radius = LayoutConfig.card_radius;

  /// 卡片内边距。
  static const EdgeInsets card_padding = EdgeInsets.all(LayoutConfig.space_16);

  /// 卡片间距。
  static const double card_spacing = LayoutConfig.space_12;

  /// 标题字号。
  static const double title_font_size = 16.0;

  /// 副标题字号。
  static const double subtitle_font_size = 13.0;

  /// 标题与副标题间距。
  static const double title_subtitle_gap = LayoutConfig.space_4;

  /// 列表内边距。
  static const EdgeInsets list_padding = EdgeInsets.symmetric(
    horizontal: LayoutConfig.space_16,
    vertical: LayoutConfig.space_12,
  );

  /// 榜单区域外边距。
  static const EdgeInsets ranking_margin = EdgeInsets.fromLTRB(
    LayoutConfig.space_12,
    0,
    LayoutConfig.space_12,
    0,
  );

  /// 榜单区域圆角。
  static const double ranking_border_radius = LayoutConfig.card_radius;

  /// 榜单区域底部间距。
  static const double ranking_bottom_spacing = LayoutConfig.space_12;

  /// 今日推荐区域顶部间距。
  static const double recommend_top_spacing = LayoutConfig.space_10;

  /// 今日推荐区域底部间距。
  static const double recommend_bottom_spacing = LayoutConfig.space_20;

  /// 返回顶部按钮显示的滚动阈值。
  static const double back_to_top_visible_offset = 320;
}
