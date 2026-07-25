import 'package:flutter/material.dart';

import 'package:app/components/home/style.dart';

/// 首页榜单区域整体骨架屏。
///
/// 这个组件用于榜单真实接口还在请求中的阶段，
/// 一次性占住 tab 标题栏、右侧入口和书籍列表区域，
/// 避免页面出现空白或布局跳动。
class RankingSectionSkeleton extends StatefulWidget {
  /// 当前是否为夜间主题。
  final bool is_dark;

  const RankingSectionSkeleton({super.key, required this.is_dark});

  @override
  State<RankingSectionSkeleton> createState() => _RankingSectionSkeletonState();
}

/// 榜单骨架屏状态类。
///
/// 通过统一的渐变流动动画，让整块榜单区域都保持“正在加载”的反馈感。
class _RankingSectionSkeletonState extends State<RankingSectionSkeleton>
    with SingleTickerProviderStateMixin {
  /// 骨架屏动画控制器。
  late final AnimationController animation_controller;

  /// 骨架屏动画进度。
  late final Animation<double> animation_progress;

  @override
  void initState() {
    super.initState();

    animation_controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: Style.ranking_skeleton_animation_duration_ms,
      ),
    )..repeat();

    animation_progress = CurvedAnimation(
      parent: animation_controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    animation_controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// 当前主题下的骨架底色。
    final Color base_color = widget.is_dark
        ? Style.ranking_skeleton_dark_base_color
        : Style.ranking_skeleton_light_base_color;

    /// 当前主题下的骨架高亮色。
    final Color highlight_color = widget.is_dark
        ? Style.ranking_skeleton_dark_highlight_color
        : Style.ranking_skeleton_light_highlight_color;

    return AnimatedBuilder(
      animation: animation_progress,
      builder: (BuildContext context, Widget? child) {
        /// 控制高亮带从左到右滑过整块榜单区域。
        final double slide_value = Tween<double>(
          begin: -1,
          end: 1,
        ).transform(animation_progress.value);

        return ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment(-1.6 + slide_value, -0.3),
              end: Alignment(1.6 + slide_value, 0.3),
              colors: <Color>[
                base_color,
                base_color,
                highlight_color,
                base_color,
                base_color,
              ],
              stops: Style.ranking_skeleton_gradient_stops,
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: _build_skeleton_content(base_color: base_color),
    );
  }

  /// 构建榜单骨架屏主体内容。
  ///
  /// 参数 `base_color`：
  /// 用于绘制所有占位块的基础颜色，外层 `ShaderMask` 会在此基础上叠加流动高亮。
  Widget _build_skeleton_content({required Color base_color}) {
    return Column(
      children: <Widget>[
        SizedBox(
          height: Style.tab_bar_height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: Style.tab_bar_left_block_width,
                    right: Style.tab_bar_trailing_spacing,
                  ),
                  child: Row(
                    children: <Widget>[
                      _build_block(
                        width: Style.ranking_skeleton_tab_active_width,
                        height: Style.ranking_skeleton_tab_height,
                        border_radius: Style.ranking_skeleton_tab_radius,
                        color: base_color,
                      ),
                      const SizedBox(width: Style.ranking_skeleton_tab_gap),
                      _build_block(
                        width: Style.ranking_skeleton_tab_width,
                        height: Style.ranking_skeleton_tab_height,
                        border_radius: Style.ranking_skeleton_tab_radius,
                        color: base_color,
                      ),
                      const SizedBox(width: Style.ranking_skeleton_tab_gap),
                      _build_block(
                        width: Style.ranking_skeleton_tab_width,
                        height: Style.ranking_skeleton_tab_height,
                        border_radius: Style.ranking_skeleton_tab_radius,
                        color: base_color,
                      ),
                      const SizedBox(width: Style.ranking_skeleton_tab_gap),
                      _build_block(
                        width: Style.ranking_skeleton_tab_width,
                        height: Style.ranking_skeleton_tab_height,
                        border_radius: Style.ranking_skeleton_tab_radius,
                        color: base_color,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  right: Style.ranking_skeleton_more_right_spacing,
                ),
                child: _build_block(
                  width: Style.ranking_skeleton_more_width,
                  height: Style.ranking_skeleton_more_height,
                  border_radius: Style.ranking_skeleton_tab_radius,
                  color: base_color,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: Style.tab_view_height,
          child: Padding(
            padding: Style.story_list_padding,
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: Style.ranking_grid_height,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount:
                        Style.ranking_cross_axis_count *
                        Style.ranking_row_count,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: Style.ranking_cross_axis_count,
                          crossAxisSpacing: Style.ranking_column_spacing,
                          mainAxisSpacing: Style.ranking_row_spacing,
                          mainAxisExtent: Style.ranking_item_height,
                        ),
                    itemBuilder: (BuildContext context, int index) {
                      return _build_story_item_skeleton(base_color: base_color);
                    },
                  ),
                ),
                const SizedBox(height: Style.ranking_more_top_spacing),
                _build_block(
                  width: Style.ranking_skeleton_more_line_width,
                  height: Style.ranking_skeleton_more_line_height,
                  border_radius: Style.ranking_skeleton_line_radius,
                  color: base_color,
                ),
                const SizedBox(height: Style.ranking_more_bottom_spacing),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建单个书籍条目的骨架占位。
  ///
  /// 参数 `base_color`：
  /// 所有占位块统一使用的底色。
  Widget _build_story_item_skeleton({required Color base_color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _build_block(
          width: Style.ranking_cover_width,
          height: Style.ranking_cover_height,
          border_radius: Style.ranking_cover_radius,
          color: base_color,
        ),
        const SizedBox(width: Style.ranking_skeleton_cover_gap),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(
              top: Style.ranking_skeleton_text_top_spacing,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _build_block(
                  width: Style.ranking_skeleton_title_line_width,
                  height: Style.ranking_skeleton_title_line_height,
                  border_radius: Style.ranking_skeleton_line_radius,
                  color: base_color,
                ),
                const SizedBox(height: Style.ranking_skeleton_text_line_gap),
                _build_block(
                  width: Style.ranking_skeleton_subtitle_line_width,
                  height: Style.ranking_skeleton_subtitle_line_height,
                  border_radius: Style.ranking_skeleton_line_radius,
                  color: base_color,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建单个占位块。
  Widget _build_block({
    required double width,
    required double height,
    required double border_radius,
    required Color color,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(border_radius),
      ),
    );
  }
}
