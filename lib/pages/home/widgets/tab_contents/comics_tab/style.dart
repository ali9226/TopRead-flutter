// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:app/components/fixed_bottom_navigation/style.dart'
    as fixed_nav_style;
import 'package:flutter/material.dart';

/// 首页漫画 Tab 布局参数。
///
/// 卡片与网格的设计参数统一由漫画模块的 [ComicsStyle]/[ComicCardStyle] 管理，
/// 这里只保留 Tab 容器相对固定底部导航栏的留白和滚动触发阈值。
class ComicsTabStyle {
  /// 列表底部基础留白，叠加安全区后保证最后一行不被固定底部导航栏遮挡。
  static final double list_bottom_base =
      fixed_nav_style.Style.bar_height + 40;

  /// 滚动距离底部多少像素时自动触发加载更多。
  static const double load_more_trigger_distance = 600;

  /// 列表滚动物理：始终可滚动以保证下拉刷新，同时启用橡皮筋回弹，
  /// 与首页瀑布流手感保持一致（含 Android）。
  static const ScrollPhysics list_scroll_physics =
      AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());
}
