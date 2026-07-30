import 'package:flutter/material.dart';

import 'package:app/config/layout_config.dart';
import 'package:app/pages/home/widgets/tab_contents/recommend_tab/widgets/ranking_section/style.dart';

/// 完整榜单区域骨架。
///
/// 首页全屏加载态与推荐 Tab 榜单加载态共同复用本组件，
/// 保证分类数据返回前后的榜单骨架结构和尺寸完全一致。
class RankingSectionSkeleton extends StatelessWidget {
  /// 当前是否为夜间主题。
  final bool is_dark;

  /// 已加载完成的真实榜单 Tab。
  ///
  /// 首次加载时为空并展示 Tab 骨架；切换榜单时传入真实 Tab，
  /// 只对榜单内容和“查看更多”区域展示骨架。
  final Widget? tab_bar;

  const RankingSectionSkeleton({
    super.key,
    required this.is_dark,
    this.tab_bar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
          child: tab_bar ?? _build_tab_bar_skeleton(),
        ),
        _build_content_skeleton(context),
        _build_view_more_skeleton(),
        const SizedBox(height: RankingSectionStyle.ranking_bottom_spacing),
      ],
    );
  }

  /// 构建榜单分类 Tab 骨架。
  Widget _build_tab_bar_skeleton() {
    final Color skeleton_color = _get_skeleton_color();

    return SizedBox(
      height: RankingSectionStyle.tab_bar_height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          RankingSectionStyle.tab_left_padding,
          0,
          RankingSectionStyle.tab_right_padding,
          0,
        ),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: RankingSectionStyle.skeleton_tab_item_count,
        separatorBuilder: (BuildContext context, int index) {
          return const SizedBox(
            width: RankingSectionStyle.tab_separator_width_cjk,
          );
        },
        itemBuilder: (BuildContext context, int index) {
          final double item_width =
              RankingSectionStyle.skeleton_tab_item_base_width +
              (index % RankingSectionStyle.skeleton_tab_item_width_variants) *
                  RankingSectionStyle.skeleton_tab_item_width_step;

          return Center(
            child: Container(
              width: item_width,
              height: RankingSectionStyle.skeleton_tab_item_height,
              decoration: BoxDecoration(
                color: skeleton_color,
                borderRadius: BorderRadius.circular(LayoutConfig.tag_radius),
              ),
              child: _SkeletonShimmer(is_dark: is_dark),
            ),
          );
        },
      ),
    );
  }

  /// 构建双列四行榜单内容骨架。
  Widget _build_content_skeleton(BuildContext context) {
    final Color skeleton_color = _get_skeleton_color();
    final TextScaler text_scaler = MediaQuery.textScalerOf(context);
    final double item_content_height =
        RankingSectionStyle.resolve_item_content_height(text_scaler);
    final double item_height = RankingSectionStyle.resolve_item_height(
      text_scaler,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: RankingSectionStyle.content_padding_horizontal,
      ),
      child: Column(
        children: List<Widget>.generate(RankingSectionStyle.rows_per_column, (
          int row_index,
        ) {
          return Padding(
            padding: EdgeInsets.only(bottom: item_height - item_content_height),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _build_single_skeleton_item(
                    skeleton_color: skeleton_color,
                    index: row_index * 2,
                    item_content_height: item_content_height,
                  ),
                ),
                const SizedBox(width: RankingSectionStyle.column_gap),
                Expanded(
                  child: _build_single_skeleton_item(
                    skeleton_color: skeleton_color,
                    index: row_index * 2 + 1,
                    item_content_height: item_content_height,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// 构建与“查看更多”位置一致的居中骨架。
  Widget _build_view_more_skeleton() {
    final Color skeleton_color = _get_skeleton_color();

    return Padding(
      padding: const EdgeInsets.only(
        top: RankingSectionStyle.view_more_top_spacing,
        bottom: RankingSectionStyle.view_more_bottom_spacing,
      ),
      child: SizedBox(
        height: RankingSectionStyle.view_more_content_height,
        child: Center(
          child: Container(
            width: RankingSectionStyle.view_more_skeleton_width,
            height: RankingSectionStyle.view_more_skeleton_height,
            decoration: BoxDecoration(
              color: skeleton_color,
              borderRadius: BorderRadius.circular(LayoutConfig.tag_radius),
            ),
            child: _SkeletonShimmer(is_dark: is_dark),
          ),
        ),
      ),
    );
  }

  /// 构建单个榜单条目骨架。
  Widget _build_single_skeleton_item({
    required Color skeleton_color,
    required int index,
    required double item_content_height,
  }) {
    final double title_width =
        RankingSectionStyle.skeleton_title_base_width +
        (index % RankingSectionStyle.skeleton_title_width_variants) *
            RankingSectionStyle.skeleton_title_width_step;
    final double metadata_width =
        RankingSectionStyle.skeleton_metadata_base_width +
        (index % RankingSectionStyle.skeleton_metadata_width_variants) *
            RankingSectionStyle.skeleton_metadata_width_step;

    return SizedBox(
      height: item_content_height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: RankingSectionStyle.cover_width,
            height: RankingSectionStyle.cover_height,
            decoration: BoxDecoration(
              color: skeleton_color,
              borderRadius: BorderRadius.circular(
                RankingSectionStyle.cover_border_radius,
              ),
            ),
          ),
          const SizedBox(width: RankingSectionStyle.cover_to_rank_gap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: title_width,
                  height: RankingSectionStyle.skeleton_title_height,
                  decoration: BoxDecoration(
                    color: skeleton_color,
                    borderRadius: BorderRadius.circular(
                      LayoutConfig.tag_radius,
                    ),
                  ),
                ),
                const SizedBox(
                  height: RankingSectionStyle.skeleton_text_line_spacing,
                ),
                Container(
                  width: metadata_width,
                  height: RankingSectionStyle.skeleton_metadata_height,
                  decoration: BoxDecoration(
                    color: skeleton_color,
                    borderRadius: BorderRadius.circular(
                      LayoutConfig.tag_radius,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 获取当前主题下的骨架底色。
  Color _get_skeleton_color() {
    return is_dark
        ? RankingSectionStyle.skeleton_dark_color
        : RankingSectionStyle.skeleton_light_color;
  }
}

/// 榜单骨架流光动画。
class _SkeletonShimmer extends StatefulWidget {
  /// 当前是否为夜间主题。
  final bool is_dark;

  const _SkeletonShimmer({required this.is_dark});

  @override
  State<_SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<_SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  /// 流光动画控制器。
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final Duration animation_duration =
        RankingSectionStyle.skeleton_animation_duration;
    final double initial_progress =
        (DateTime.now().millisecondsSinceEpoch %
            animation_duration.inMilliseconds) /
        animation_duration.inMilliseconds;
    _controller = AnimationController(
      vsync: this,
      duration: animation_duration,
      value: initial_progress,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final Color base_color = widget.is_dark
            ? RankingSectionStyle.skeleton_dark_shimmer_base_color
            : RankingSectionStyle.skeleton_light_shimmer_base_color;
        final Color highlight_color = widget.is_dark
            ? RankingSectionStyle.skeleton_dark_shimmer_highlight_color
            : RankingSectionStyle.skeleton_light_shimmer_highlight_color;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[base_color, highlight_color, base_color],
              stops: <double>[
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value,
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
            borderRadius: BorderRadius.circular(LayoutConfig.tag_radius),
          ),
        );
      },
    );
  }
}
