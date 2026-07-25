import 'package:flutter/material.dart';

import 'package:app/components/recommend_book_card/style.dart';

/// 推荐瀑布流首屏骨架。
///
/// 首页全屏加载态与推荐瀑布流真实加载态共同复用本组件，
/// 保证两个加载阶段的卡片结构、尺寸、间距和动画完全一致。
class RecommendWaterfallSkeleton extends StatefulWidget {
  /// 当前是否为夜间主题。
  final bool is_dark;

  const RecommendWaterfallSkeleton({super.key, required this.is_dark});

  @override
  State<RecommendWaterfallSkeleton> createState() =>
      _RecommendWaterfallSkeletonState();
}

class _RecommendWaterfallSkeletonState extends State<RecommendWaterfallSkeleton>
    with SingleTickerProviderStateMixin {
  /// 骨架屏流光动画控制器。
  late final AnimationController _shimmer_controller;

  /// 左列骨架卡片配置。
  static const List<_SkeletonCardData> _left_cards = <_SkeletonCardData>[
    _SkeletonCardData(
      cover_height: RecommendBookCardStyle.skeleton_cover_standard_height,
      has_description: true,
      tag_count: 2,
    ),
    _SkeletonCardData(
      cover_height: RecommendBookCardStyle.skeleton_cover_short_height,
      has_description: true,
      tag_count: 1,
    ),
    _SkeletonCardData(
      cover_height: RecommendBookCardStyle.skeleton_cover_tall_height,
      has_description: false,
      tag_count: 0,
    ),
  ];

  /// 右列骨架卡片配置。
  static const List<_SkeletonCardData> _right_cards = <_SkeletonCardData>[
    _SkeletonCardData(
      cover_height: RecommendBookCardStyle.skeleton_cover_short_height,
      has_description: true,
      tag_count: 1,
    ),
    _SkeletonCardData(
      cover_height: RecommendBookCardStyle.skeleton_cover_tall_height,
      has_description: true,
      tag_count: 2,
    ),
    _SkeletonCardData(
      cover_height: RecommendBookCardStyle.skeleton_cover_standard_height,
      has_description: false,
      tag_count: 1,
    ),
  ];

  @override
  void initState() {
    super.initState();
    final Duration animation_duration =
        RecommendBookCardStyle.skeleton_animation_duration;
    final double initial_progress =
        (DateTime.now().millisecondsSinceEpoch %
            animation_duration.inMilliseconds) /
        animation_duration.inMilliseconds;
    _shimmer_controller = AnimationController(
      vsync: this,
      duration: animation_duration,
      value: initial_progress,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer_controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color base_color = widget.is_dark
        ? RecommendBookCardStyle.skeleton_dark_base_color
        : RecommendBookCardStyle.skeleton_light_base_color;
    final Color highlight_color = widget.is_dark
        ? RecommendBookCardStyle.skeleton_dark_highlight_color
        : RecommendBookCardStyle.skeleton_light_highlight_color;

    return AnimatedBuilder(
      animation: _shimmer_controller,
      builder: (BuildContext context, Widget? child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(
            RecommendBookCardStyle.skeleton_row_count,
            (int row_index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom:
                      row_index < RecommendBookCardStyle.skeleton_row_count - 1
                      ? RecommendBookCardStyle.item_spacing
                      : 0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: RecommendBookCardStyle.column_spacing / 2,
                        ),
                        child: _build_skeleton_card(
                          data: _left_cards[row_index],
                          base_color: base_color,
                          highlight_color: highlight_color,
                          delay:
                              row_index *
                              RecommendBookCardStyle.skeleton_row_delay,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: RecommendBookCardStyle.column_spacing / 2,
                        ),
                        child: _build_skeleton_card(
                          data: _right_cards[row_index],
                          base_color: base_color,
                          highlight_color: highlight_color,
                          delay:
                              RecommendBookCardStyle
                                  .skeleton_right_column_delay +
                              row_index *
                                  RecommendBookCardStyle.skeleton_row_delay,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// 构建单张推荐卡片骨架。
  Widget _build_skeleton_card({
    required _SkeletonCardData data,
    required Color base_color,
    required Color highlight_color,
    required double delay,
  }) {
    final double animation_value = _shimmer_controller.value;

    return Container(
      decoration: BoxDecoration(
        color: widget.is_dark
            ? RecommendBookCardStyle.card_dark_bg
            : RecommendBookCardStyle.card_light_bg,
        borderRadius: BorderRadius.circular(RecommendBookCardStyle.card_radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _build_skeleton_bar(
            width: double.infinity,
            height: data.cover_height,
            radius: 0,
            base_color: base_color,
            highlight_color: highlight_color,
            animation_value: animation_value,
            delay: delay,
          ),
          Padding(
            padding: RecommendBookCardStyle.content_padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _build_skeleton_bar(
                  width: double.infinity,
                  height:
                      RecommendBookCardStyle.title_font_size *
                      RecommendBookCardStyle.title_height,
                  radius: RecommendBookCardStyle.skeleton_title_radius,
                  base_color: base_color,
                  highlight_color: highlight_color,
                  animation_value: animation_value,
                  delay:
                      delay +
                      RecommendBookCardStyle.skeleton_title_first_line_delay,
                ),
                const SizedBox(
                  height: RecommendBookCardStyle.skeleton_title_line_spacing,
                ),
                _build_skeleton_bar(
                  width:
                      RecommendBookCardStyle.skeleton_title_second_line_width,
                  height:
                      RecommendBookCardStyle.title_font_size *
                      RecommendBookCardStyle.title_height,
                  radius: RecommendBookCardStyle.skeleton_title_radius,
                  base_color: base_color,
                  highlight_color: highlight_color,
                  animation_value: animation_value,
                  delay:
                      delay +
                      RecommendBookCardStyle.skeleton_title_second_line_delay,
                ),
                if (data.has_description) ...<Widget>[
                  const SizedBox(
                    height: RecommendBookCardStyle.description_top_spacing,
                  ),
                  _build_skeleton_bar(
                    width: double.infinity,
                    height:
                        RecommendBookCardStyle.description_font_size *
                        RecommendBookCardStyle.description_height,
                    radius: RecommendBookCardStyle.skeleton_description_radius,
                    base_color: base_color,
                    highlight_color: highlight_color,
                    animation_value: animation_value,
                    delay:
                        delay +
                        RecommendBookCardStyle
                            .skeleton_description_first_line_delay,
                  ),
                  const SizedBox(
                    height: RecommendBookCardStyle
                        .skeleton_description_line_spacing,
                  ),
                  _build_skeleton_bar(
                    width: RecommendBookCardStyle
                        .skeleton_description_second_line_width,
                    height:
                        RecommendBookCardStyle.description_font_size *
                        RecommendBookCardStyle.description_height,
                    radius: RecommendBookCardStyle.skeleton_description_radius,
                    base_color: base_color,
                    highlight_color: highlight_color,
                    animation_value: animation_value,
                    delay:
                        delay +
                        RecommendBookCardStyle
                            .skeleton_description_second_line_delay,
                  ),
                ],
                if (data.tag_count > 0) ...<Widget>[
                  const SizedBox(
                    height: RecommendBookCardStyle.tag_top_spacing,
                  ),
                  Row(
                    children: List<Widget>.generate(data.tag_count, (
                      int index,
                    ) {
                      return Padding(
                        padding: EdgeInsets.only(
                          right: index < data.tag_count - 1
                              ? RecommendBookCardStyle.tag_spacing
                              : 0,
                        ),
                        child: _build_skeleton_bar(
                          width: RecommendBookCardStyle.skeleton_tag_width,
                          height:
                              RecommendBookCardStyle.tag_font_size * 2 +
                              RecommendBookCardStyle
                                  .skeleton_tag_vertical_padding,
                          radius: RecommendBookCardStyle.tag_radius,
                          base_color: base_color,
                          highlight_color: highlight_color,
                          animation_value: animation_value,
                          delay:
                              delay +
                              RecommendBookCardStyle
                                  .skeleton_tag_initial_delay +
                              index *
                                  RecommendBookCardStyle
                                      .skeleton_tag_interval_delay,
                        ),
                      );
                    }),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建带有明暗循环动画的骨架条。
  Widget _build_skeleton_bar({
    required double width,
    required double height,
    required double radius,
    required Color base_color,
    required Color highlight_color,
    required double animation_value,
    required double delay,
  }) {
    final double adjusted_value = (animation_value + delay) % 1.0;
    final double intensity = adjusted_value < 0.5
        ? adjusted_value * 2
        : (1.0 - adjusted_value) * 2;
    final Color current_color = Color.lerp(
      base_color,
      highlight_color,
      intensity,
    )!;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: current_color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// 单张推荐卡片骨架的数据配置。
class _SkeletonCardData {
  /// 封面骨架高度。
  final double cover_height;

  /// 是否展示简介骨架。
  final bool has_description;

  /// 标签骨架数量。
  final int tag_count;

  const _SkeletonCardData({
    required this.cover_height,
    required this.has_description,
    required this.tag_count,
  });
}
