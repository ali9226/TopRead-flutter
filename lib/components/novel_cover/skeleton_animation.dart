import 'package:flutter/material.dart';

import 'package:app/components/novel_cover/style.dart';

/// 骨架屏动画组件。
///
/// 封面图片加载期间展示的闪烁占位效果。
class NovelCoverSkeletonAnimation extends StatefulWidget {
  /// 骨架屏底色。
  final Color base_color;

  /// 骨架屏高亮色。
  final Color highlight_color;

  /// 组件宽度。
  final double width;

  /// 组件高度。
  final double height;

  /// 圆角大小。
  final double border_radius;

  const NovelCoverSkeletonAnimation({
    super.key,
    required this.base_color,
    required this.highlight_color,
    required this.width,
    required this.height,
    required this.border_radius,
  });

  @override
  State<NovelCoverSkeletonAnimation> createState() =>
      _NovelCoverSkeletonAnimationState();
}

class _NovelCoverSkeletonAnimationState
    extends State<NovelCoverSkeletonAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation_controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animation_controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: NovelCoverStyle.skeleton_animation_duration_ms,
      ),
    )..repeat();

    _animation = CurvedAnimation(
      parent: _animation_controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animation_controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.border_radius),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (BuildContext context, Widget? child) {
          final double slide_value = Tween<double>(
            begin: -1,
            end: 1,
          ).transform(_animation.value);

          return ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                begin: Alignment(-1.6 + slide_value, -0.3),
                end: Alignment(1.6 + slide_value, 0.3),
                colors: <Color>[
                  widget.base_color,
                  widget.base_color,
                  widget.highlight_color,
                  widget.base_color,
                  widget.base_color,
                ],
                stops: NovelCoverStyle.skeleton_gradient_stops,
              ).createShader(bounds);
            },
            blendMode: BlendMode.srcATop,
            child: Container(
              width: widget.width,
              height: widget.height,
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }
}
