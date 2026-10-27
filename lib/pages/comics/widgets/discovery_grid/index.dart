// ignore_for_file: non_constant_identifier_names

import 'package:app/models/comics.dart';
import 'package:app/pages/comics/style.dart';
import 'package:flutter/material.dart';

import 'comic_card.dart';
import 'style.dart';

export 'comic_card.dart';
export 'style.dart';

SliverGridDelegateWithFixedCrossAxisCount _delegate(
  BuildContext context,
  double width,
  bool section,
) {
  final columns = ComicDiscoveryGridStyle.columns(width, section: section);
  final card_width =
      (width - (columns - 1) * ComicDiscoveryGridStyle.column_gap) / columns;
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: columns,
    crossAxisSpacing: ComicDiscoveryGridStyle.column_gap,
    mainAxisSpacing: ComicDiscoveryGridStyle.row_gap,
    mainAxisExtent: ComicDiscoveryGridStyle.item_height(
      card_width,
      MediaQuery.textScalerOf(context),
      ComicsStyle.is_cjk(context),
    ),
  );
}

/// 首页单组最多六本，交由外层分组 SliverList 按屏幕懒加载。
class ComicDiscoveryGrid extends StatelessWidget {
  const ComicDiscoveryGrid({
    super.key,
    required this.items,
    this.section = true,
    this.on_open,
  });

  final List<ComicItem> items;
  final bool section;
  final ValueChanged<ComicItem>? on_open;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => GridView.builder(
      primary: false,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: _delegate(context, constraints.maxWidth, section),
      itemCount: items.length,
      itemBuilder: (context, index) => ComicDiscoveryCard(
        key: ValueKey('comic_discovery_card_${items[index].id}'),
        comic: items[index],
        on_open: on_open,
      ),
    ),
  );
}

/// 分类页使用真正的 SliverGrid，翻页后仍只解码可见封面。
class ComicDiscoverySliverGrid extends StatelessWidget {
  const ComicDiscoverySliverGrid({
    super.key,
    required this.items,
    this.on_open,
  });

  final List<ComicItem> items;
  final ValueChanged<ComicItem>? on_open;

  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
    builder: (context, constraints) => SliverGrid(
      gridDelegate: _delegate(context, constraints.crossAxisExtent, false),
      delegate: SliverChildBuilderDelegate(
        (context, index) => ComicDiscoveryCard(
          key: ValueKey('comic_discovery_card_${items[index].id}'),
          comic: items[index],
          on_open: on_open,
        ),
        childCount: items.length,
      ),
    ),
  );
}
