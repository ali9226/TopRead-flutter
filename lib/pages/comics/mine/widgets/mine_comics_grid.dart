// ignore_for_file: non_constant_identifier_names

import 'package:app/models/comics.dart';
import 'package:app/pages/comics/mine/widgets/mine_comic_card.dart';
import 'package:app/pages/comics/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

/// 「我的漫画」瀑布流网格：自适应列数，点击卡片进入编辑器。
class MineComicsGrid extends StatelessWidget {
  /// 当前页作品列表。
  final List<ComicItem> items;

  /// 点击卡片回调，参数为漫画 id。
  final void Function(int comic_id) on_item_tap;

  const MineComicsGrid({
    super.key,
    required this.items,
    required this.on_item_tap,
  });

  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
    builder: (context, constraints) {
      /// 按内容宽度推算列数，与公共 [ComicsGrid] 保持一致的密度。
      final int columns =
          (constraints.crossAxisExtent / ComicsStyle.grid_card_width)
              .floor()
              .clamp(
                ComicCardStyle.grid_min_column_count,
                ComicCardStyle.grid_max_column_count,
              );
      return SliverMasonryGrid.count(
        crossAxisCount: columns,
        mainAxisSpacing: ComicCardStyle.grid_item_spacing,
        crossAxisSpacing: ComicCardStyle.grid_column_spacing,
        childCount: items.length,
        itemBuilder: (context, index) {
          final ComicItem comic = items[index];
          return MineComicCard(
            comic: comic,
            on_tap: () => on_item_tap(comic.id),
          );
        },
      );
    },
  );
}
