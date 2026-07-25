import 'package:flutter/material.dart';

import 'package:app/components/network_cover_image/style.dart';

/// 网络封面加载中的渐变骨架屏。
///
/// 这个组件负责在网络图片尚未返回时展示一个持续流动的高亮渐变，
/// 让用户明确知道封面区域还在加载，而不是误以为页面卡住或图片丢失。
class NetworkCoverLoadingSkeleton extends StatefulWidget {
  /// 骨架屏宽度。
  final double width;

  /// 骨架屏高度。
  final double height;

  /// 骨架屏圆角。
  final double border_radius;

  /// 当前是否为夜间主题。
  final bool is_dark;

  const NetworkCoverLoadingSkeleton({
    super.key,
    required this.width,
    required this.height,
    required this.border_radius,
    required this.is_dark,
  });

  @override
  State<NetworkCoverLoadingSkeleton> createState() =>
      _NetworkCoverLoadingSkeletonState();
}

/// 渐变骨架屏状态类。
///
/// 这里使用 AnimationController 持续驱动渐变位置变化，
/// 目的是做出比单纯闪烁更明确的“正在加载中”提示。
class _NetworkCoverLoadingSkeletonState
    extends State<NetworkCoverLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  /// 骨架屏位移动画控制器。
  late final AnimationController animation_controller;

  /// 骨架屏渐变滑动进度动画。
  late final Animation<double> animation_progress;

  @override
  void initState() {
    super.initState();

    animation_controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds:
            NetworkCoverImageStyle.skeleton_animation_duration_ms,
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
        ? NetworkCoverImageStyle.dark_skeleton_base_color
        : NetworkCoverImageStyle.light_skeleton_base_color;

    /// 当前主题下的骨架高亮色。
    final Color highlight_color = widget.is_dark
        ? NetworkCoverImageStyle.dark_skeleton_highlight_color
        : NetworkCoverImageStyle.light_skeleton_highlight_color;

    return AnimatedBuilder(
      animation: animation_progress,
      builder: (BuildContext context, Widget? child) {
        /// 通过线性插值让高亮区域从左向右持续滑动。
        final double slide_value = Tween<double>(
          begin: -1,
          end: 1,
        ).transform(animation_progress.value);

        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.border_radius),
            gradient: LinearGradient(
              begin: Alignment(
                NetworkCoverImageStyle.skeleton_gradient_begin.x + slide_value,
                NetworkCoverImageStyle.skeleton_gradient_begin.y,
              ),
              end: Alignment(
                NetworkCoverImageStyle.skeleton_gradient_end.x + slide_value,
                NetworkCoverImageStyle.skeleton_gradient_end.y,
              ),
              colors: <Color>[
                base_color,
                base_color,
                highlight_color,
                base_color,
                base_color,
              ],
              stops: NetworkCoverImageStyle.skeleton_gradient_stops,
            ),
          ),
        );
      },
    );
  }
}
