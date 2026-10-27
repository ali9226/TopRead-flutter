// ignore_for_file: non_constant_identifier_names

import 'package:app/models/novel_discovery.dart';
import 'package:app/pages/novel_discovery/style.dart';
import 'package:flutter/material.dart';

import 'novel_card.dart';
import 'style.dart';

export 'novel_card.dart';
export 'style.dart';

SliverGridDelegateWithFixedCrossAxisCount _delegate(
  BuildContext context,
  double width,
  bool section,
) {
  final columns = NovelDiscoveryGridStyle.columns(width, section: section);
  final card_width =
      (width - (columns - 1) * NovelDiscoveryGridStyle.column_gap) / columns;
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: columns,
    crossAxisSpacing: NovelDiscoveryGridStyle.column_gap,
    mainAxisSpacing: NovelDiscoveryGridStyle.row_gap,
    mainAxisExtent: NovelDiscoveryGridStyle.item_height(
      card_width,
      MediaQuery.textScalerOf(context),
      NovelDiscoveryStyle.is_cjk(context),
    ),
  );
}

/// 首页单组最多六本，交由外层分组 SliverList 按屏幕懒加载。
class NovelDiscoveryGrid extends StatelessWidget {
  const NovelDiscoveryGrid({
    super.key,
    required this.items,
    this.section = true,
    this.on_open,
  });

  final List<NovelDiscoveryItem> items;
  final bool section;
  final ValueChanged<NovelDiscoveryItem>? on_open;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => GridView.builder(
      primary: false,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: _delegate(context, constraints.maxWidth, section),
      itemCount: items.length,
      itemBuilder: (context, index) => NovelDiscoveryCard(
        key: ValueKey('novel_discovery_card_${items[index].id}'),
        novel: items[index],
        on_open: on_open,
      ),
    ),
  );
}

/// 分类页使用真正的 SliverGrid，翻页后仍只解码可见封面。
class NovelDiscoverySliverGrid extends StatelessWidget {
  const NovelDiscoverySliverGrid({
    super.key,
    required this.items,
    this.on_open,
  });

  final List<NovelDiscoveryItem> items;
  final ValueChanged<NovelDiscoveryItem>? on_open;

  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
    builder: (context, constraints) => SliverGrid(
      gridDelegate: _delegate(context, constraints.crossAxisExtent, false),
      delegate: SliverChildBuilderDelegate(
        (context, index) => NovelDiscoveryCard(
          key: ValueKey('novel_discovery_card_${items[index].id}'),
          novel: items[index],
          on_open: on_open,
        ),
        childCount: items.length,
      ),
    ),
  );
}
