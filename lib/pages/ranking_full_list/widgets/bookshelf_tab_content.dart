import 'package:flutter/material.dart';
import 'package:app/pages/ranking_full_list/widgets/bookshelf_grid_content.dart';

/// 榜单主 Tab 内容。
class BookshelfTabContent extends StatelessWidget {
  /// 榜单 Tab id，决定请求哪个接口。
  final int ranking_tab_id;

  /// 当前 Tab 的强调色。
  final Color accent_color;

  /// 当前是否为夜间模式。
  final bool is_dark;

  /// 初始选中的分类 id（可选，用于从外部传入默认选中项）。
  final int? initial_category_id;

  const BookshelfTabContent({
    super.key,
    required this.ranking_tab_id,
    required this.accent_color,
    required this.is_dark,
    this.initial_category_id,
  });

  @override
  Widget build(BuildContext context) {
    return BookshelfGridContent(
      ranking_tab_id: ranking_tab_id,
      accent_color: accent_color,
      is_dark: is_dark,
      initial_category_id: initial_category_id,
    );
  }
}
