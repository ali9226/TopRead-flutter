// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:math' as math;

import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/config/layout_config.dart';
import 'package:app/pages/home/widgets/home_tab_bar/style.dart';
import 'package:app/util/language_util/index.dart';
import 'package:flutter/material.dart';

/// 分类页沿用首页横滑标题的字阶、选中缩放和主题色标记。
class NovelBrowseStyle {
  static const double horizontal_padding = LayoutConfig.page_horizontal_padding;
  static const double content_top_gap = LayoutConfig.space_12;
  static const double content_bottom_gap = LayoutConfig.space_24;
  static const double tab_vertical_padding = LayoutConfig.space_10;
  static const double tab_inner_padding = LayoutConfig.space_4;

  /// 与首页一致，指示线抬离栏底，滚动时仍保留稳定的标题留白。
  static const double tab_indicator_bottom_offset = LayoutConfig.space_4;

  /// 独立于列表首项的间隔，列表滚动至顶部时也不会紧贴指示线。
  static const double tab_bottom_gap = LayoutConfig.space_8;
  static const double indicator_width = 3;
  static const double loading_extent = 160;
  static const double pagination_threshold = 480;
  static const double footer_gap = LayoutConfig.space_16;
  static const double compact_icon_size = 20;
  static const double title_size_cjk = 19;
  static const double title_size_alphabetic = 18;
  static const double status_size_cjk = 13;
  static const double status_size_alphabetic = 12.5;
  static const double tab_line_height = 1.3;
  static const Duration tab_duration = Duration(milliseconds: 260);

  static bool is_cjk(BuildContext context) => LanguageUtil.is_cjk_language(
    Localizations.localeOf(context).languageCode,
  );
  static bool reduce_motion(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ||
      MediaQuery.accessibleNavigationOf(context);
  static Color background(bool dark) =>
      dark ? ColorConstants.nightBackgroundColor : ColorConstants.whiteColor;
  static Color foreground(bool dark) =>
      dark ? ColorConstants.whiteColor : ColorConstants.lightTextColor;
  static Color muted(bool dark) => dark
      ? HomeTabBarStyle.unselected_dark_color
      : HomeTabBarStyle.unselected_light_color;
  static double tab_font_size(BuildContext context) => is_cjk(context)
      ? HomeTabBarStyle.tab_title_font_size_cjk
      : HomeTabBarStyle.tab_title_font_size_alphabetic;
  static double selected_scale(BuildContext context) => is_cjk(context)
      ? HomeTabBarStyle.tab_selected_scale_cjk
      : HomeTabBarStyle.tab_selected_scale_alphabetic;
  static double tab_height(BuildContext context) => math.max(
    LayoutConfig.touch_target_size,
    MediaQuery.textScalerOf(context).scale(tab_font_size(context)) *
            tab_line_height *
            selected_scale(context) +
        tab_vertical_padding * 2,
  );
  static TextStyle title(BuildContext context, bool dark) => TextStyle(
    fontSize: is_cjk(context) ? title_size_cjk : title_size_alphabetic,
    fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
    color: foreground(dark),
  );
}
