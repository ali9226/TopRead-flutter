import 'package:flutter/material.dart';

import 'package:app/pages/short_story_read/style.dart';

/// 骨架屏内容组件。
///
/// 在内容加载时展示占位动画效果，包含：
/// - 标题骨架
/// - 标签骨架（3 个）
/// - 正文骨架（8 行段落）
///
/// 与 [SkeletonScreen] 的区别：
/// - [SkeletonScreen] 包含完整的页面骨架（含底部栏），用于页面级加载。
/// - [SkeletonContent] 仅包含内容区域骨架，用于卡片级加载。
///
/// 使用呼吸灯动画（明暗交替），相邻骨架条动画错开。
class SkeletonContent extends StatefulWidget {
  /// 是否为夜间模式。
  final bool is_dark;

  const SkeletonContent({
    super.key,
    required this.is_dark,
  });

  @override
  State<SkeletonContent> createState() => _SkeletonContentState();
}

class _SkeletonContentState extends State<SkeletonContent>
    with SingleTickerProviderStateMixin {
  /// 呼吸灯动画控制器（无限循环）。
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    // 初始化呼吸灯动画（1.5 秒一个周期，无限循环）。
    _controller = AnimationController(
      vsync: this,
      duration: ShortStoryReadStyle.skeleton_animation_duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// 骨架屏底色。
    final Color base_color = widget.is_dark
        ? ShortStoryReadStyle.skeleton_dark_base
        : ShortStoryReadStyle.skeleton_light_base;

    /// 骨架屏高亮色。
    final Color highlight_color = widget.is_dark
        ? ShortStoryReadStyle.skeleton_dark_highlight
        : ShortStoryReadStyle.skeleton_light_highlight;

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            /// 标题骨架（宽度 200px）。
            _buildBar(
              width: 200,
              height: 28,
              delay: 0,
              base_color: base_color,
              highlight_color: highlight_color,
            ),
            const SizedBox(height: ShortStoryReadStyle.title_bottom_spacing),

            /// 标签骨架（3 个不同宽度的标签占位）。
            Row(
              children: <Widget>[
                _buildBar(
                  width: 60,
                  height: 24,
                  delay: 0.1,
                  base_color: base_color,
                  highlight_color: highlight_color,
                ),
                const SizedBox(width: 8),
                _buildBar(
                  width: 50,
                  height: 24,
                  delay: 0.15,
                  base_color: base_color,
                  highlight_color: highlight_color,
                ),
                const SizedBox(width: 8),
                _buildBar(
                  width: 45,
                  height: 24,
                  delay: 0.2,
                  base_color: base_color,
                  highlight_color: highlight_color,
                ),
              ],
            ),
            const SizedBox(height: ShortStoryReadStyle.tag_bottom_spacing),

            /// 正文骨架（8 行段落占位，每 3 行中第 1 行较短）。
            ...List<Widget>.generate(8, (int index) {
              final double width = index % 3 == 0 ? 160 : double.infinity;
              return Padding(
                padding: const EdgeInsets.only(
                  bottom: ShortStoryReadStyle.paragraph_spacing,
                ),
                child: _buildBar(
                  width: width,
                  height: 16,
                  delay: 0.25 + index * 0.05,
                  base_color: base_color,
                  highlight_color: highlight_color,
                ),
              );
            }),
          ],
        );
      },
    );
  }

  /// 构建单个骨架条。
  ///
  /// 通过 [delay] 参数实现相邻骨架条的动画错开效果。
  ///
  /// 参数：
  /// - [width] 骨架条宽度。
  /// - [height] 骨架条高度。
  /// - [delay] 动画延迟（0.0 ~ 1.0，相对于动画周期的偏移量）。
  /// - [base_color] 骨架条底色。
  /// - [highlight_color] 骨架条高亮色。
  Widget _buildBar({
    required double width,
    required double height,
    required double delay,
    required Color base_color,
    required Color highlight_color,
  }) {
    /// 调整后的动画值（加入延迟偏移后取模）。
    final double adjusted = (_controller.value + delay) % 1.0;

    /// 呼吸灯插值因子（0 → 1 → 0 的三角波）。
    final double t = adjusted < 0.5 ? adjusted * 2 : (1.0 - adjusted) * 2;

    /// 当前帧的骨架条颜色。
    final Color color = Color.lerp(base_color, highlight_color, t)!;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
