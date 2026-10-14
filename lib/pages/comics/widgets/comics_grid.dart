// ignore_for_file: non_constant_identifier_names

import 'package:app/models/comics.dart';
import 'package:app/pages/comics/style.dart';
import 'package:app/pages/comics/widgets/comic_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

/// 漫画瀑布流网格：自适应列数，卡片高度随内容自然伸展。
class ComicsGrid extends StatelessWidget {
  /// 当前页的漫画列表。
  final List<ComicItem> items;

  const ComicsGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
    builder: (context, constraints) {
      final columns =
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
        itemBuilder: (context, index) => ComicCard(comic: items[index]),
      );
    },
  );
}
