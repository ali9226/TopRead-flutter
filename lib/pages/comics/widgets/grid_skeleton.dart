// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:app/pages/comics/style.dart';
import 'package:flutter/material.dart';

/// 漫画瀑布流首屏骨架屏。
///
/// 与 [ComicCard] 结构一一对应（封面比例、标题两行、简介两行、标签胶囊），
/// 数据加载期间以流光动画占位，保证加载完成前后布局零跳动。
/// 流光实现与首页推荐瀑布流骨架保持一致。
class ComicsGridSkeleton extends StatefulWidget {
  /// 当前是否为夜间主题。
  final bool is_dark;

  const ComicsGridSkeleton({super.key, required this.is_dark});

  @override
  State<ComicsGridSkeleton> createState() => _ComicsGridSkeletonState();
}

class _ComicsGridSkeletonState extends State<ComicsGridSkeleton>
    with SingleTickerProviderStateMixin {
  /// 骨架屏流光动画控制器。
  late final AnimationController _shimmer_controller;

  /// 骨架卡片配置池，按列循环填充，模拟真实瀑布流的高度错落。
  static const List<_SkeletonCardData> _card_data_pool =
      <_SkeletonCardData>[
        _SkeletonCardData(has_description: true, tag_count: 2),
        _SkeletonCardData(has_description: true, tag_count: 1),
        _SkeletonCardData(has_description: false, tag_count: 0),
        _SkeletonCardData(has_description: true, tag_count: 2),
        _SkeletonCardData(has_description: false, tag_count: 1),
        _SkeletonCardData(has_description: true, tag_count: 1),
      ];

  @override
  void initState() {
    super.initState();

    /// 以当前时间取模作为初始进度，避免所有骨架屏同相位闪烁。
    final Duration animation_duration =
        ComicCardStyle.skeleton_animation_duration;
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
    /// 骨架条底色与高亮色。
    final Color base_color = widget.is_dark
        ? ComicCardStyle.skeleton_dark_base_color
        : ComicCardStyle.skeleton_light_base_color;
    final Color highlight_color = widget.is_dark
        ? ComicCardStyle.skeleton_dark_highlight_color
        : ComicCardStyle.skeleton_light_highlight_color;

    /// 卡片背景色。
    final Color card_bg = widget.is_dark
        ? ComicCardStyle.card_dark_bg
        : ComicCardStyle.card_light_bg;

    return AnimatedBuilder(
      animation: _shimmer_controller,
      builder: (BuildContext context, Widget? child) {
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            /// 与 [ComicsGrid] 相同的列数推算，保证骨架与真实网格密度一致。
            final int columns =
                (constraints.maxWidth / ComicsStyle.grid_card_width)
                    .floor()
                    .clamp(
                      ComicCardStyle.grid_min_column_count,
                      ComicCardStyle.grid_max_column_count,
                    );

            /// 每列骨架卡片配置，按池循环取值。
            final List<List<_SkeletonCardData>> column_cards = List<
              List<_SkeletonCardData>
            >.generate(columns, (int column_index) {
              return List<_SkeletonCardData>.generate(
                ComicCardStyle.skeleton_row_count,
                (int row_index) =>
                    _card_data_pool[(column_index *
                            ComicCardStyle.skeleton_row_count +
                        row_index) %
                    _card_data_pool.length],
              );
            });

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List<Widget>.generate(columns, (int column_index) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: column_index == 0
                          ? 0
                          : ComicCardStyle.grid_column_spacing / 2,
                      right: column_index == columns - 1
                          ? 0
                          : ComicCardStyle.grid_column_spacing / 2,
                    ),
                    child: Column(
                      children: List<Widget>.generate(
                        column_cards[column_index].length,
                        (int row_index) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom:
                                  row_index <
                                      column_cards[column_index].length - 1
                                  ? ComicCardStyle.grid_item_spacing
                                  : 0,
                            ),
                            child: _build_skeleton_card(
                              data: column_cards[column_index][row_index],
                              card_bg: card_bg,
                              base_color: base_color,
                              highlight_color: highlight_color,
                              delay:
                                  column_index *
                                      ComicCardStyle.skeleton_column_delay +
                                  row_index *
                                      ComicCardStyle.skeleton_row_delay,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        );
      },
    );
  }

  /// 构建单张漫画卡片骨架，结构与 [ComicCard] 对应。
  ///
  /// [data] 该骨架卡片的简介/标签占位配置。
  /// [card_bg] 卡片背景色。
  /// [base_color] 骨架条底色。
  /// [highlight_color] 骨架条高亮色。
  /// [delay] 该卡片的流光相位延迟。
  Widget _build_skeleton_card({
    required _SkeletonCardData data,
    required Color card_bg,
    required Color base_color,
    required Color highlight_color,
    required double delay,
  }) {
    final double animation_value = _shimmer_controller.value;

    /// 标题条高度，与真实标题行高一致。
    final double title_bar_height =
        ComicCardStyle.title_font_size_cjk *
        ComicCardStyle.title_height_cjk;

    /// 简介条高度，与真实简介行高一致。
    final double description_bar_height =
        ComicCardStyle.description_font_size_cjk *
        ComicCardStyle.description_height_cjk;

    return Container(
      decoration: BoxDecoration(
        color: card_bg,
        borderRadius: BorderRadius.circular(ComicCardStyle.card_radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          /// 封面占位：与真实封面同比例，加载完成零跳动。
          AspectRatio(
            aspectRatio: ComicsStyle.cover_ratio,
            child: _build_skeleton_bar(
              width: double.infinity,
              height: double.infinity,
              radius: 0,
              base_color: base_color,
              highlight_color: highlight_color,
              animation_value: animation_value,
              delay: delay,
            ),
          ),

          /// 文字区占位，内边距与 [ComicCard] 一致。
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ComicCardStyle.content_padding_h,
              ComicCardStyle.content_padding_top,
              ComicCardStyle.content_padding_h,
              ComicCardStyle.content_padding_bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                /// 标题第一行。
                _build_skeleton_bar(
                  width: double.infinity,
                  height: title_bar_height,
                  radius: ComicCardStyle.skeleton_title_radius,
                  base_color: base_color,
                  highlight_color: highlight_color,
                  animation_value: animation_value,
                  delay:
                      delay + ComicCardStyle.skeleton_title_first_line_delay,
                ),
                const SizedBox(
                  height: ComicCardStyle.skeleton_title_line_spacing,
                ),

                /// 标题第二行。
                _build_skeleton_bar(
                  width: ComicCardStyle.skeleton_title_second_line_width,
                  height: title_bar_height,
                  radius: ComicCardStyle.skeleton_title_radius,
                  base_color: base_color,
                  highlight_color: highlight_color,
                  animation_value: animation_value,
                  delay:
                      delay + ComicCardStyle.skeleton_title_second_line_delay,
                ),

                /// 简介两行。
                if (data.has_description) ...<Widget>[
                  const SizedBox(
                    height: ComicCardStyle.description_top_spacing_cjk,
                  ),
                  _build_skeleton_bar(
                    width: double.infinity,
                    height: description_bar_height,
                    radius: ComicCardStyle.skeleton_description_radius,
                    base_color: base_color,
                    highlight_color: highlight_color,
                    animation_value: animation_value,
                    delay:
                        delay +
                        ComicCardStyle
                            .skeleton_description_first_line_delay,
                  ),
                  const SizedBox(
                    height: ComicCardStyle.skeleton_description_line_spacing,
                  ),
                  _build_skeleton_bar(
                    width:
                        ComicCardStyle.skeleton_description_second_line_width,
                    height: description_bar_height,
                    radius: ComicCardStyle.skeleton_description_radius,
                    base_color: base_color,
                    highlight_color: highlight_color,
                    animation_value: animation_value,
                    delay:
                        delay +
                        ComicCardStyle
                            .skeleton_description_second_line_delay,
                  ),
                ],

                /// 标签胶囊占位。
                if (data.tag_count > 0) ...<Widget>[
                  const SizedBox(height: ComicCardStyle.tag_top_spacing),
                  Row(
                    children: List<Widget>.generate(data.tag_count, (
                      int index,
                    ) {
                      return Padding(
                        padding: EdgeInsets.only(
                          right: index < data.tag_count - 1
                              ? ComicCardStyle.tag_spacing
                              : 0,
                        ),
                        child: _build_skeleton_bar(
                          width: ComicCardStyle.skeleton_tag_width,
                          height: ComicCardStyle.skeleton_tag_height,
                          radius: ComicCardStyle.tag_radius,
                          base_color: base_color,
                          highlight_color: highlight_color,
                          animation_value: animation_value,
                          delay:
                              delay +
                              ComicCardStyle.skeleton_tag_initial_delay +
                              index *
                                  ComicCardStyle.skeleton_tag_interval_delay,
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

  /// 构建带流光循环动画的骨架条。
  ///
  /// [width] 骨架条宽度。
  /// [height] 骨架条高度。
  /// [radius] 骨架条圆角。
  /// [base_color] 底色。
  /// [highlight_color] 高亮色。
  /// [animation_value] 当前流光进度（0~1）。
  /// [delay] 流光相位延迟，制造波浪效果。
  Widget _build_skeleton_bar({
    required double width,
    required double height,
    required double radius,
    required Color base_color,
    required Color highlight_color,
    required double animation_value,
    required double delay,
  }) {
    /// 相位偏移后的流光进度。
    final double adjusted_value = (animation_value + delay) % 1.0;

    /// 三角波强度：0 → 1 → 0，产生明暗呼吸。
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

/// 单张骨架卡片的占位配置。
class _SkeletonCardData {
  /// 是否展示简介占位。
  final bool has_description;

  /// 标签占位数量。
  final int tag_count;

  const _SkeletonCardData({
    required this.has_description,
    required this.tag_count,
  });
}
