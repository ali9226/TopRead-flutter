import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';
import 'package:app/pages/bookshelf/style.dart';

/// 书架页逻辑控制器。
///
/// 作用：
/// 1. 统一维护书架页的 Tab 控制器。
/// 2. 提供页面所需的 Tab 数量，避免页面层硬编码。
/// 3. 提供响应式布局计算。
class BookshelfLogic {
  /// 书架页 Tab 总数（历史、收藏、关注）。
  static const int tab_length = 3;

  /// 创建书架页使用的 TabController。
  static TabController create_tab_controller({required TickerProvider vsync}) {
    return TabController(length: tab_length, vsync: vsync);
  }

  /// 根据顶部 Tab 下标返回区分色。
  static Color resolve_tab_accent_color(int index) {
    /// 第一个 Tab（历史）使用清透蓝。
    if (index == 0) {
      return const Color(0xFF8DB7FF);
    }

    /// 第二个 Tab（收藏）使用红色。
    if (index == 1) {
      return ColorConstants.dangerColor;
    }

    /// 第三个 Tab（关注）使用薄荷绿。
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
}

/// 顶部 Tab 枚举。
enum BookshelfTabKind { history, favorite, focus }
