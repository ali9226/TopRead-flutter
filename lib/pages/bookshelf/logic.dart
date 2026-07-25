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

/// 书架书籍项模型（用于历史和收藏的网格展示）。
class BookshelfBookItem {
  /// 数据唯一标识。
  final String id;

  /// 小说ID。
  final String novel_id;

  /// 标题文案。
  final String title;

  /// 发布状态：1=连载中, 2=已完结, 3=下架, 4=短篇。
  final int publish_status;

  /// 小说简介（用于封面兜底展示）。
  final String introduction;

  /// 进度文案国际化 key。
  final String progress_key;

  /// 进度文案参数。
  final Map<String, String> progress_args;

  /// 右上角标签国际化 key。
  final String? tag_key;

  /// 远程封面图地址。
  final String? cover_image_url;

  /// 封面渐变起始色。
  final Color cover_start_color;

  /// 封面渐变结束色。
  final Color cover_end_color;

  BookshelfBookItem({
    required this.id,
    required this.novel_id,
    required this.title,
    this.publish_status = 1,
    this.introduction = '',
    required this.progress_key,
    required this.progress_args,
    this.tag_key,
    this.cover_image_url,
    required this.cover_start_color,
    required this.cover_end_color,
  });
}

/// 预定义的封面渐变色列表，用于没有封面图时的兜底展示。
const List<List<Color>> cover_gradient_colors = <List<Color>>[
  [Color(0xFFF7C9C0), Color(0xFFF2E0A6)],
  [Color(0xFFBBDCF7), Color(0xFFE4EFFA)],
  [Color(0xFFD7C7F6), Color(0xFFF0EAFE)],
  [Color(0xFFF7D1D7), Color(0xFFFCEBEC)],
  [Color(0xFFE7D4BA), Color(0xFFF8EEE0)],
  [Color(0xFFC6E6D7), Color(0xFFE8F6F0)],
  [Color(0xFFD0DCF7), Color(0xFFE8EEFF)],
  [Color(0xFFCFE8EC), Color(0xFFE9F5F7)],
  [Color(0xFFF3D2C7), Color(0xFFFDEEEA)],
  [Color(0xFFE2D7F4), Color(0xFFF3EEFB)],
];
