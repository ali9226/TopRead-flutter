import 'package:flutter/material.dart';

import 'package:app/pages/short_story_read/style.dart';

/// 骨架屏组件。
///
/// 模拟页面加载时的占位效果，包含：
/// - 内容区域骨架（标题、标签、正文段落）
/// - 底部评论栏骨架（输入框、评论图标、点赞图标）
///
/// 所有骨架条使用呼吸灯动画（明暗交替）提升加载体验。
class SkeletonScreen extends StatefulWidget {
  /// 是否为夜间模式。
  final bool is_dark;

  const SkeletonScreen({
    super.key,
    required this.is_dark,
  });

  @override
  State<SkeletonScreen> createState() => _SkeletonScreenState();
}

class _SkeletonScreenState extends State<SkeletonScreen>
    with SingleTickerProviderStateMixin {
  /// 骨架屏呼吸灯动画控制器（无限循环）。
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    // 初始化呼吸灯动画（1.5 秒一个周期，无限循环）。
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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

    /// 背景色（用于底部栏骨架）。
    final Color bg_color = widget.is_dark
        ? ShortStoryReadStyle.bg_dark_color
        : ShortStoryReadStyle.bg_light_color;

    return Column(
      children: <Widget>[
        /// 内容区域骨架（可滚动）。
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              ShortStoryReadStyle.page_horizontal_padding,
              ShortStoryReadStyle.page_top_padding,
              ShortStoryReadStyle.page_horizontal_padding,
              ShortStoryReadStyle.page_bottom_padding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                /// 标题骨架（宽度 180px）。
                _buildAnimatedBar(
                  width: 180,
                  height: 18,
                  base_color: base_color,
                  highlight_color: highlight_color,
                  delay: 0,
                ),

                const SizedBox(
                    height: ShortStoryReadStyle.title_bottom_spacing),

                /// 标签骨架（3 个不同宽度的标签占位）。
                Row(
                  children: <Widget>[
                    _buildAnimatedBar(
                      width: 60,
                      height: 22,
                      base_color: base_color,
                      highlight_color: highlight_color,
                      delay: 0.1,
                    ),
                    const SizedBox(width: 8),
                    _buildAnimatedBar(
                      width: 50,
                      height: 22,
                      base_color: base_color,
                      highlight_color: highlight_color,
                      delay: 0.15,
                    ),
                    const SizedBox(width: 8),
                    _buildAnimatedBar(
                      width: 45,
                      height: 22,
                      base_color: base_color,
                      highlight_color: highlight_color,
                      delay: 0.2,
                    ),
                  ],
                ),

                const SizedBox(
                    height: ShortStoryReadStyle.tag_bottom_spacing + 8),

                /// 正文骨架（10 行段落占位，每 3 行中第 1 行较短）。
                ...List<Widget>.generate(10, (int index) {
                  final double width = index % 3 == 0 ? 160 : double.infinity;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildAnimatedBar(
                      width: width,
                      height: 14,
                      base_color: base_color,
                      highlight_color: highlight_color,
                      delay: 0.25 + index * 0.05,
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        /// 底部操作栏骨架（包含进度条骨架 + 四个操作项骨架）。
        Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewPaddingOf(context).bottom,
          ),
          decoration: BoxDecoration(
            color: bg_color,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              /// 进度条骨架（上一篇文字 + 轨道 + 下一篇文字）。
              SizedBox(
                height: ShortStoryReadStyle.progress_bar_height,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ShortStoryReadStyle.progress_area_horizontal_padding,
                  ),
                  child: Row(
                    children: <Widget>[
                      /// 上一篇文字骨架（宽度 42）。
                      _buildAnimatedBar(
                        width: 42,
                        height: 14,
                        base_color: base_color,
                        highlight_color: highlight_color,
                        delay: 0.7,
                      ),

                      /// 进度条轨道骨架（占满中间）。
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: _buildAnimatedBar(
                            width: double.infinity,
                            height: ShortStoryReadStyle.progress_track_height,
                            base_color: base_color,
                            highlight_color: highlight_color,
                            delay: 0.75,
                          ),
                        ),
                      ),

                      /// 下一篇文字骨架（宽度 42）。
                      _buildAnimatedBar(
                        width: 42,
                        height: 14,
                        base_color: base_color,
                        highlight_color: highlight_color,
                        delay: 0.8,
                      ),
                    ],
                  ),
                ),
              ),

              /// 四个操作项骨架。
              SizedBox(
                height: ShortStoryReadStyle.bottom_bar_height,
                child: Row(
                  children: List<Widget>.generate(4, (int index) {
                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          /// 图标骨架（22x22 圆角方形）。
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: base_color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),

                          /// 文字骨架（宽度 28）。
                          Container(
                            width: 28,
                            height: 11,
                            decoration: BoxDecoration(
                              color: base_color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建带动画的骨架条。
  ///
  /// 通过 [delay] 参数实现相邻骨架条的动画错开效果，
  /// 使呼吸灯效果从左到右、从上到下依次传递。
  ///
  /// 参数：
  /// - [width] 骨架条宽度。
  /// - [height] 骨架条高度。
  /// - [base_color] 骨架条底色。
  /// - [highlight_color] 骨架条高亮色。
  /// - [delay] 动画延迟（0.0 ~ 1.0，相对于动画周期的偏移量）。
  Widget _buildAnimatedBar({
    required double width,
    required double height,
    required Color base_color,
    required Color highlight_color,
    required double delay,
  }) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
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
      },
    );
  }
}
