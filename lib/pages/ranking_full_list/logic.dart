import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';
import 'package:app/pages/ranking_full_list/style.dart';

/// 完整榜单页逻辑控制器。
///
/// 作用：
/// 1. 维护页面的 Tab 控制器。
/// 2. 提供页面所需的 Tab 数量。
/// 3. 提供筛选项和响应式布局计算。
class RankingFullListLogic {
  /// Tab 总数（从外部传入的 tab 标题列表长度决定）。
  static int tab_length = 3;

  /// 创建完整榜单页使用的 TabController。
  static TabController create_tab_controller({
    required TickerProvider vsync,
    int length = 3,
  }) {
    tab_length = length;
    return TabController(length: length, vsync: vsync);
  }

  /// 根据顶部 Tab 下标返回区分色。
  static Color resolve_tab_accent_color(int index) {
    if (index == 0) {
      return const Color(0xFF8DB7FF);
    }

    if (index == 1) {
      return ColorConstants.dangerColor;
    }

    if (index == 2) {
      return const Color(0xFF7ED9B1);
    }

    return ColorConstants.resolveMessageTypeAccentColor(index);
  }

  /// 根据当前内容宽度计算网格列数。
  static int resolve_grid_count(double width) {
    if (width >= Style.ultra_wide_grid_breakpoint) {
      return 6;
    }

    if (width >= Style.extra_wide_grid_breakpoint) {
      return 5;
    }

    if (width >= Style.wide_grid_breakpoint) {
      return 4;
    }

    return Style.compact_grid_count;
  }

  /// 根据榜单 Tab id 获取对应的 API 路径。
  ///
  /// - id=148 → `novel/recommend_ranking`
  /// - id=149 → `novel/completed_ranking`
  /// - id=150 → `novel/peak_ranking`
  /// - id=151 → `novel/new_book_ranking`
  /// - id=157 → `novel/short_story`
  static String resolve_api_path(int ranking_tab_id) {
    switch (ranking_tab_id) {
      case 148:
        return 'novel/recommend_ranking';
      case 149:
        return 'novel/completed_ranking';
      case 150:
        return 'novel/peak_ranking';
      case 151:
        return 'novel/new_book_ranking';
      case 157:
        return 'novel/short_story';
      default:
        return 'novel/recommend_ranking';
    }
  }
}
