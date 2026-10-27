// ignore_for_file: non_constant_identifier_names

import 'package:app/components/work_detail_skeleton/pulse.dart';
import 'package:app/pages/comics/style.dart';
import 'package:flutter/material.dart';

import 'skeleton_style.dart';
import 'style.dart';

/// 用真实卡片列数、封面比例和单行字阶计算占位，避免加载完成时网格跳动。
SliverGridDelegateWithFixedCrossAxisCount _skeleton_delegate(
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

/// 首页有限书目的盒子占位。已有外部共享时钟时设 [with_pulse] 为 false。
class ComicDiscoverySkeleton extends StatelessWidget {
  const ComicDiscoverySkeleton({
    super.key,
    this.item_count = ComicDiscoverySkeletonStyle.section_count,
    this.section = true,
    this.is_dark,
    this.with_pulse = true,
  }) : assert(item_count >= 0);

  final int item_count;
  final bool section;
  final bool? is_dark;
  final bool with_pulse;

  @override
  Widget build(BuildContext context) {
    final grid = LayoutBuilder(
      builder: (context, constraints) => GridView.builder(
        primary: false,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: _skeleton_delegate(
          context,
          constraints.maxWidth,
          section,
        ),
        itemCount: item_count,
        itemBuilder: (context, index) => _SkeletonCard(
          key: ValueKey('comic_discovery_skeleton_card_$index'),
        ),
      ),
    );
    return with_pulse
        ? SkeletonPulse(
            is_dark: is_dark ?? ComicsStyle.is_dark(context),
            child: grid,
          )
        : grid;
  }
}

/// 分类页初始加载和追加分页都使用惰性 sliver，占位共享一个轻量绘制时钟。
class ComicDiscoverySliverSkeleton extends StatelessWidget {
  const ComicDiscoverySliverSkeleton({
    super.key,
    this.item_count = ComicDiscoverySkeletonStyle.catalog_count,
    this.section = false,
    this.is_dark,
  }) : assert(item_count >= 0);

  final int item_count;
  final bool section;
  final bool? is_dark;

  @override
  Widget build(BuildContext context) => SkeletonPulse(
    is_dark: is_dark ?? ComicsStyle.is_dark(context),
    child: SliverLayoutBuilder(
      builder: (context, constraints) => SliverGrid(
        gridDelegate: _skeleton_delegate(
          context,
          constraints.crossAxisExtent,
          section,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _SkeletonCard(
            key: ValueKey('comic_discovery_skeleton_card_$index'),
          ),
          childCount: item_count,
        ),
      ),
    ),
  );
}

/// 数据已返回而封面尚在下载时继续展示光扫，图片到达便销毁临时时钟。
class ComicDiscoveryCoverSkeleton extends StatelessWidget {
  const ComicDiscoveryCoverSkeleton({super.key, this.is_dark});

  final bool? is_dark;

  @override
  Widget build(BuildContext context) => SkeletonPulse(
    is_dark: is_dark ?? ComicsStyle.is_dark(context),
    child: LayoutBuilder(
      builder: (context, constraints) => SkeletonBlock(
        height: constraints.hasBoundedHeight ? constraints.maxHeight : 0,
        radius: ComicDiscoveryGridStyle.cover_radius,
      ),
    ),
  );
}

/// 一张真实书卡对应一张占位，文本条保持缩短墨迹并保留完整行高。
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final cjk = ComicsStyle.is_cjk(context);
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SkeletonBlock(
            key: const ValueKey('comic_discovery_skeleton_cover'),
            height: constraints.maxWidth / ComicDiscoveryGridStyle.cover_ratio,
            radius: ComicDiscoveryGridStyle.cover_radius,
          ),
          const SizedBox(height: ComicDiscoveryGridStyle.title_gap),
          SizedBox(
            height: ComicDiscoveryGridStyle.title_extent(scaler, cjk),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FractionallySizedBox(
                widthFactor: ComicDiscoverySkeletonStyle.title_width_ratio,
                child: SkeletonBlock(
                  height: scaler.scale(
                    cjk
                        ? ComicDiscoverySkeletonStyle.title_bar_height_cjk
                        : ComicDiscoverySkeletonStyle
                              .title_bar_height_alphabetic,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: ComicDiscoveryGridStyle.category_gap),
          SizedBox(
            height: ComicDiscoveryGridStyle.category_extent(scaler, cjk),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FractionallySizedBox(
                widthFactor: ComicDiscoverySkeletonStyle.category_width_ratio,
                child: SkeletonBlock(
                  height: scaler.scale(
                    cjk
                        ? ComicDiscoverySkeletonStyle.category_bar_height_cjk
                        : ComicDiscoverySkeletonStyle
                              .category_bar_height_alphabetic,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
