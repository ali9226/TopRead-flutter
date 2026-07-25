// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:flutter/material.dart';

import 'package:app/components/home/style.dart';

/// 首页轮播图骨架屏。
///
/// 仅在首屏请求首页海报数据时展示，
/// 语种切换触发的静默刷新不会再次显示该骨架屏。
class HomeBannerSkeleton extends StatefulWidget {
  /// 当前是否为夜间主题。
  final bool is_dark;

  const HomeBannerSkeleton({super.key, required this.is_dark});

  @override
  State<HomeBannerSkeleton> createState() => _HomeBannerSkeletonState();
}

class _HomeBannerSkeletonState extends State<HomeBannerSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation_controller;
  late final Animation<double> _slide_animation;

  @override
  void initState() {
    super.initState();
    _animation_controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: Style.banner_skeleton_animation_duration_ms,
      ),
    )..repeat();

    _slide_animation = Tween<double>(
      begin: -1.2,
      end: 1.2,
    ).animate(_animation_controller);
  }

  @override
  void dispose() {
    _animation_controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color base_color = widget.is_dark
        ? Style.banner_skeleton_dark_base_color
        : Style.banner_skeleton_light_base_color;

    final Color highlight_color = widget.is_dark
        ? Style.banner_skeleton_dark_highlight_color
        : Style.banner_skeleton_light_highlight_color;

    return ClipRRect(
      borderRadius: BorderRadius.circular(Style.banner_radius),
      child: AnimatedBuilder(
        animation: _slide_animation,
        builder: (BuildContext context, Widget? child) {
          final double slide_value = _slide_animation.value;

          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(
                  Style.banner_skeleton_gradient_begin.x + slide_value,
                  Style.banner_skeleton_gradient_begin.y,
                ),
                end: Alignment(
                  Style.banner_skeleton_gradient_end.x + slide_value,
                  Style.banner_skeleton_gradient_end.y,
                ),
                colors: <Color>[
                  base_color,
                  base_color,
                  highlight_color,
                  base_color,
                  base_color,
                ],
                stops: Style.banner_skeleton_gradient_stops,
              ),
            ),
            child: child,
          );
        },
        child: _build_skeleton_content(base_color: base_color),
      ),
    );
  }

  /// 构建轮播图骨架结构。
  Widget _build_skeleton_content({required Color base_color}) {
    return SizedBox(
      height: Style.banner_height,
      child: Padding(
        padding: Style.banner_padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Align(
              alignment: Alignment.topRight,
              child: _build_block(
                width: Style.banner_skeleton_badge_width,
                height: Style.banner_skeleton_badge_height,
                border_radius: Style.banner_skeleton_badge_radius,
                color: base_color,
              ),
            ),
            const Spacer(),
            _build_block(
              width: Style.banner_skeleton_title_width,
              height: Style.banner_skeleton_title_height,
              border_radius: Style.banner_skeleton_line_radius,
              color: base_color,
            ),
            const SizedBox(height: Style.banner_title_top_spacing),
            _build_block(
              width: Style.banner_skeleton_subtitle_width,
              height: Style.banner_skeleton_subtitle_height,
              border_radius: Style.banner_skeleton_line_radius,
              color: base_color,
            ),
            const SizedBox(height: Style.banner_highlight_top_spacing),
            _build_block(
              width: Style.banner_skeleton_highlight_width,
              height: Style.banner_skeleton_highlight_height,
              border_radius: Style.banner_highlight_radius,
              color: base_color,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建骨架色块。
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
