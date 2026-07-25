import 'package:flutter/material.dart';

import 'package:app/components/comment_list/style.dart';

/// 与真实评论项结构一致的骨架屏，带 shimmer 流光动画。
///
/// 头像、昵称、正文行、时间行、点赞按钮的位置和尺寸均与 [CommentItem] 保持一致，
/// 确保骨架屏到真实内容的切换不会产生布局跳变。
class CommentSkeleton extends StatefulWidget {
  /// 是否为夜间模式。
  final bool is_dark;

  /// 骨架屏条目数量。
  final int count;

  const CommentSkeleton({super.key, required this.is_dark, this.count = 5});

  @override
  State<CommentSkeleton> createState() => _CommentSkeletonState();
}

class _CommentSkeletonState extends State<CommentSkeleton>
    with SingleTickerProviderStateMixin {
  /// shimmer 流光动画控制器。
  late final AnimationController _controller;

  /// shimmer 流光动画值（0.0 → 1.0 循环）。
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(
        milliseconds: CommentListStyle.shimmer_animation_duration_ms,
      ),
      vsync: this,
    )..repeat();
    _animation = CurvedAnimation(parent: _controller, curve: Curves.linear);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (BuildContext context, Widget? child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (Rect bounds) {
            /// 构建从左到右扫过的线性渐变，产生流光效果。
            final double slide_offset =
                CommentListStyle.shimmer_gradient_end -
                CommentListStyle.shimmer_gradient_start;
            final double dx = _animation.value * slide_offset;
            return LinearGradient(
              colors: <Color>[
                Colors.transparent,
                Colors.white.withValues(
                  alpha: CommentListStyle.shimmer_base_opacity,
                ),
                Colors.white.withValues(
                  alpha: CommentListStyle.shimmer_peak_opacity,
                ),
                Colors.white.withValues(
                  alpha: CommentListStyle.shimmer_base_opacity,
                ),
                Colors.transparent,
              ],
              stops: const <double>[0.0, 0.3, 0.5, 0.7, 1.0],
              begin: Alignment(
                CommentListStyle.shimmer_gradient_start + dx,
                0.0,
              ),
              end: Alignment(
                CommentListStyle.shimmer_gradient_end + dx,
                0.0,
              ),
            ).createShader(bounds);
          },
          child: ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              vertical: CommentListStyle.list_vertical_padding,
            ),
            itemCount: widget.count,
            itemBuilder: (BuildContext context, int index) {
              return _build_item();
            },
          ),
        );
      },
    );
  }

  /// 构建单条骨架屏评论项。
  ///
  /// 布局与真实 CommentItem 保持一致：
  /// - 头像（36×36 圆形）
  /// - 昵称行（76px 宽色块）
  /// - 正文第一行（满宽色块）
  /// - 正文第二行（190px 宽色块）
  /// - 时间行（50px 宽色块）
  /// - 右侧点赞按钮区域
  Widget _build_item() {
    /// 骨架色块的基础颜色，与输入框背景色一致。
    final Color base_color = widget.is_dark
        ? CommentListStyle.input_dark_bg
        : CommentListStyle.input_light_bg;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CommentListStyle.list_horizontal_padding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(
              top: CommentListStyle.item_top_padding,
              bottom: CommentListStyle.item_bottom_padding,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                /// 头像占位色块（圆形）。
                _block(
                  width: CommentListStyle.avatar_size,
                  height: CommentListStyle.avatar_size,
                  radius: CommentListStyle.avatar_radius,
                  color: base_color,
                ),
                const SizedBox(width: CommentListStyle.avatar_content_gap),

                /// 昵称 + 正文区域。
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      /// 昵称占位色块。
                      _block(
                        width: CommentListStyle.skeleton_nickname_width,
                        height: CommentListStyle.skeleton_text_height,
                        radius: CommentListStyle.skeleton_block_radius,
                        color: base_color,
                      ),
                      const SizedBox(
                        height: CommentListStyle.content_top_spacing,
                      ),

                      /// 正文第一行（满宽）。
                      _block(
                        width: double.infinity,
                        height: CommentListStyle.skeleton_text_height,
                        radius: CommentListStyle.skeleton_block_radius,
                        color: base_color,
                      ),
                      const SizedBox(
                        height: CommentListStyle.skeleton_line_spacing,
                      ),

                      /// 正文第二行（短行）。
                      _block(
                        width: CommentListStyle.skeleton_short_line_width,
                        height: CommentListStyle.skeleton_text_height,
                        radius: CommentListStyle.skeleton_block_radius,
                        color: base_color,
                      ),
                      const SizedBox(
                        height: CommentListStyle.metadata_top_spacing,
                      ),

                      /// 时间行占位色块。
                      _block(
                        width: CommentListStyle.skeleton_time_width,
                        height: CommentListStyle.skeleton_text_height,
                        radius: CommentListStyle.skeleton_block_radius,
                        color: base_color,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: CommentListStyle.input_action_spacing),

                /// 点赞按钮占位区域。
                Column(
                  children: <Widget>[
                    const SizedBox(
                      height: CommentListStyle.like_main_top_padding,
                    ),
                    _block(
                      width: CommentListStyle.like_icon_size,
                      height: CommentListStyle.like_icon_size,
                      radius: CommentListStyle.skeleton_block_radius,
                      color: base_color,
                    ),
                    const SizedBox(
                      height: CommentListStyle.like_icon_count_spacing,
                    ),
                    _block(
                      width: CommentListStyle.skeleton_like_width,
                      height: CommentListStyle.skeleton_text_height,
                      radius: CommentListStyle.skeleton_block_radius,
                      color: base_color,
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// 分割线占位。
          Padding(
            padding: const EdgeInsets.only(
              left: CommentListStyle.divider_indent,
            ),
            child: Divider(
              height: CommentListStyle.divider_thickness,
              thickness: CommentListStyle.divider_thickness,
              color: widget.is_dark
                  ? CommentListStyle.divider_dark_color
                  : CommentListStyle.divider_light_color,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建单个骨架色块。
  Widget _block({
    required double width,
    required double height,
    required double radius,
    required Color color,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: SizedBox(width: width, height: height),
    );
  }
}
