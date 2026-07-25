import 'package:flutter/material.dart';

import 'package:app/pages/home/widgets/tab_bar_skeleton/style.dart';

/// 首页 Tab 栏骨架屏组件。
///
/// 在分类数据加载完成前展示，模拟 Tab 栏标题的占位效果，
/// 带有流动闪光动画，视觉上更接近真实加载体验。
class TabBarSkeleton extends StatefulWidget {
  final bool is_dark;

  const TabBarSkeleton({super.key, required this.is_dark});

  @override
  State<TabBarSkeleton> createState() => _TabBarSkeletonState();
}

class _TabBarSkeletonState extends State<TabBarSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animation_controller;

  @override
  void initState() {
    super.initState();
    _animation_controller = AnimationController(
      vsync: this,
      duration: TabBarSkeletonStyle.animation_duration,
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

    final Color base_color = is_dark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);

    final Color shimmer_color = is_dark
        ? Colors.white.withValues(alpha: 0.25)
        : Colors.black.withValues(alpha: 0.15);

    return AnimatedBuilder(
      animation: _animation_controller,
      builder: (BuildContext context, Widget? child) {
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(
              left: TabBarSkeletonStyle.start_padding,
            ),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: TabBarSkeletonStyle.item_count,
            itemBuilder: (BuildContext context, int index) {
              final double item_width = TabBarSkeletonStyle.item_width_list[
                  index % TabBarSkeletonStyle.item_width_list.length];

              final double shimmer_offset = _animation_controller.value;

              final double item_delay = index * 0.1;
              final double adjusted_offset =
                  (shimmer_offset + item_delay) % 1.0;

              final double t = adjusted_offset < 0.5
                  ? adjusted_offset * 2
                  : (1.0 - adjusted_offset) * 2;

              final Color item_color = Color.lerp(
                base_color,
                shimmer_color,
                t,
              )!;

              return Container(
                margin: const EdgeInsets.only(
                  right: TabBarSkeletonStyle.item_spacing,
                ),
                width: item_width,
                height: TabBarSkeletonStyle.item_height,
                decoration: BoxDecoration(
                  color: item_color,
                  borderRadius: BorderRadius.circular(
                    TabBarSkeletonStyle.item_radius,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
