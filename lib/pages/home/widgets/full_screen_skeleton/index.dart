import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:app/components/home_header_bar/index.dart';
import 'package:app/components/recommend_book_card/widgets/recommend_waterfall_skeleton.dart';
import 'package:app/components/top_decoration/index.dart';
import 'package:app/pages/home/widgets/full_screen_skeleton/style.dart';
import 'package:app/pages/home/widgets/tab_contents/recommend_tab/style.dart';
import 'package:app/pages/home/widgets/tab_contents/recommend_tab/widgets/ranking_section/style.dart';
import 'package:app/pages/home/widgets/tab_contents/recommend_tab/widgets/ranking_section/widgets/ranking_section_skeleton.dart';

/// 首页全屏骨架。
///
/// 首页分类数据加载期间保留真实头部，并通过公共骨架子组件模拟推荐页，
/// 确保分类加载完成后切换到推荐 Tab 时内容区域不会改变布局。
class FullScreenSkeleton extends StatefulWidget {
  /// 当前是否为夜间主题。
  final bool is_dark;

  /// 搜索区域点击回调。
  final VoidCallback on_search_tap;

  /// 语种区域点击回调。
  final VoidCallback on_language_tap;

  const FullScreenSkeleton({
    super.key,
    required this.is_dark,
    required this.on_search_tap,
    required this.on_language_tap,
  });

  @override
  State<FullScreenSkeleton> createState() => _FullScreenSkeletonState();
}

class _FullScreenSkeletonState extends State<FullScreenSkeleton>
    with SingleTickerProviderStateMixin {
  /// 首页分类 Tab 骨架动画控制器。
  late final AnimationController _animation_controller;

  @override
  void initState() {
    super.initState();
    _animation_controller = AnimationController(
      vsync: this,
      duration: FullScreenSkeletonStyle.animation_duration,
    )..repeat();
  }

  @override
  void dispose() {
    _animation_controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool is_dark = widget.is_dark;
    final double status_bar_height = MediaQuery.paddingOf(context).top;
    final bool has_status_bar_spacing = !kIsWeb && status_bar_height > 0;
    final Color background_color = is_dark
        ? FullScreenSkeletonStyle.dark_background_color
        : FullScreenSkeletonStyle.light_background_color;
    final Color panel_color = is_dark
        ? FullScreenSkeletonStyle.dark_panel_color
        : FullScreenSkeletonStyle.light_panel_color;

    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        color: background_color,
        child: Stack(
          children: <Widget>[
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: TopDecoration(is_dark: is_dark),
            ),
            Column(
              children: <Widget>[
                if (has_status_bar_spacing) SizedBox(height: status_bar_height),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: HomeHeaderBar(
                    is_dark: is_dark,
                    on_search_tap: widget.on_search_tap,
                    on_language_tap: widget.on_language_tap,
                  ),
                ),
                Transform.translate(
                  offset: const Offset(
                    0,
                    FullScreenSkeletonStyle.tab_bar_top_offset,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: FullScreenSkeletonStyle.tab_bar_height,
                    child: _build_tab_bar_skeleton(is_dark: is_dark),
                  ),
                ),
                Expanded(
                  child: _build_content_skeleton(
                    is_dark: is_dark,
                    panel_color: panel_color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建首页分类 Tab 骨架。
  Widget _build_tab_bar_skeleton({required bool is_dark}) {
    final Color base_color = is_dark
        ? FullScreenSkeletonStyle.dark_base_color
        : FullScreenSkeletonStyle.light_base_color;
    final Color highlight_color = is_dark
        ? FullScreenSkeletonStyle.dark_highlight_color
        : FullScreenSkeletonStyle.light_highlight_color;

    return AnimatedBuilder(
      animation: _animation_controller,
      builder: (BuildContext context, Widget? child) {
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(left: 16),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: FullScreenSkeletonStyle.tab_item_count,
          itemBuilder: (BuildContext context, int index) {
            final double item_width =
                FullScreenSkeletonStyle.tab_item_width_list[index %
                    FullScreenSkeletonStyle.tab_item_width_list.length];
            final double shimmer_offset = _animation_controller.value;
            final double item_delay =
                index * FullScreenSkeletonStyle.tab_item_animation_delay;
            final double adjusted_offset = (shimmer_offset + item_delay) % 1.0;
            final double intensity = adjusted_offset < 0.5
                ? adjusted_offset * 2
                : (1.0 - adjusted_offset) * 2;
            final Color item_color = Color.lerp(
              base_color,
              highlight_color,
              intensity,
            )!;

            return Container(
              margin: const EdgeInsets.only(
                right: FullScreenSkeletonStyle.tab_item_spacing,
              ),
              width: item_width,
              height: FullScreenSkeletonStyle.tab_item_height,
              decoration: BoxDecoration(
                color: item_color,
                borderRadius: BorderRadius.circular(
                  FullScreenSkeletonStyle.tab_item_radius,
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 构建推荐 Tab 的内容骨架。
  ///
  /// 榜单和瀑布流均直接复用推荐页实际加载时使用的公共子组件。
  Widget _build_content_skeleton({
    required bool is_dark,
    required Color panel_color,
  }) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: RecommendTabStyle.ranking_margin,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: double.infinity,
              height: RankingSectionStyle.section_fixed_height,
              decoration: BoxDecoration(
                color: panel_color,
                borderRadius: BorderRadius.circular(
                  RecommendTabStyle.ranking_border_radius,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: RankingSectionSkeleton(is_dark: is_dark),
            ),
            const SizedBox(height: RecommendTabStyle.recommend_top_spacing),
            RecommendWaterfallSkeleton(is_dark: is_dark),
            const SizedBox(height: RecommendTabStyle.recommend_bottom_spacing),
          ],
        ),
      ),
    );
  }
}
