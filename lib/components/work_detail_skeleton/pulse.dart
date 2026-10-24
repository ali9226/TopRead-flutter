import 'package:flutter/material.dart';

import 'style.dart';
import 'package:app/config/color_config.dart';

/// 同一加载区域共用一个时钟；每帧只更新绘制，不重建任何页面布局。
class SkeletonPulse extends StatefulWidget {
  const SkeletonPulse({super.key, required this.is_dark, required this.child});

  final bool is_dark;
  final Widget child;

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: WorkDetailSkeletonStyle.sweep_duration,
  );
  bool _motion_enabled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 系统减少动态效果及离屏 TickerMode 均真正停止时钟。
    _motion_enabled =
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (_motion_enabled && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!_motion_enabled) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _SkeletonScope(
    animation: _controller,
    is_dark: widget.is_dark,
    motion_enabled: _motion_enabled,
    child: widget.child,
  );
}

class _SkeletonScope extends InheritedWidget {
  const _SkeletonScope({
    required this.animation,
    required this.is_dark,
    required this.motion_enabled,
    required super.child,
  });

  final Animation<double> animation;
  final bool is_dark;
  final bool motion_enabled;

  @override
  bool updateShouldNotify(_SkeletonScope old_widget) =>
      old_widget.animation != animation ||
      old_widget.is_dark != is_dark ||
      old_widget.motion_enabled != motion_enabled;
}

/// 真实内容位置的圆角占位；需放在 [SkeletonPulse] 内共用主题与动画。
class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({
    super.key,
    this.width,
    required this.height,
    this.radius = WorkDetailSkeletonStyle.radius,
    this.on_hero = false,
  }) : assert(height >= 0),
       assert(radius >= 0);

  final double? width;
  final double height;
  final double radius;
  final bool on_hero;

  @override
  Widget build(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_SkeletonScope>();
    assert(scope != null, 'SkeletonBlock must be inside SkeletonPulse.');
    final is_dark = scope?.is_dark ?? false;
    return ExcludeSemantics(
      child: SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: CustomPaint(
          painter: _SkeletonPainter(
            animation: scope?.animation,
            motion_enabled: scope?.motion_enabled ?? false,
            radius: radius,
            base: on_hero && is_dark
                ? WorkDetailSkeletonStyle.hero_base
                : is_dark
                ? WorkDetailSkeletonStyle.dark_base
                : WorkDetailSkeletonStyle.light_base,
            highlight: on_hero && is_dark
                ? WorkDetailSkeletonStyle.hero_highlight
                : is_dark
                ? WorkDetailSkeletonStyle.dark_highlight
                : WorkDetailSkeletonStyle.light_highlight,
            reversed: Directionality.of(context) == TextDirection.rtl,
          ),
        ),
      ),
    );
  }
}

/// 只订阅绘制时钟。动画期间既不触发 build，也不重新计算详情高度。
class _SkeletonPainter extends CustomPainter {
  _SkeletonPainter({
    required this.animation,
    required this.motion_enabled,
    required this.radius,
    required this.base,
    required this.highlight,
    required this.reversed,
  }) : super(repaint: animation);

  final Animation<double>? animation;
  final bool motion_enabled;
  final double radius;
  final Color base;
  final Color highlight;
  final bool reversed;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final paint = Paint()..color = base;
    if (motion_enabled) {
      // Shader 已包含半透明海报色；Paint 再乘一次 alpha 会让占位几乎消失。
      paint.color = ColorConstants.whiteColor;
      final progress = animation?.value ?? 0;
      final position =
          (reversed ? 1 - progress : progress) *
              WorkDetailSkeletonStyle.sweep_extent -
          WorkDetailSkeletonStyle.sweep_extent / 2;
      paint.shader = LinearGradient(
        begin: Alignment(position - 1, -0.2),
        end: Alignment(position + 1, 0.2),
        colors: [base, base, highlight, base, base],
        stops: WorkDetailSkeletonStyle.sweep_stops,
      ).createShader(rect);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      paint,
    );
  }

  @override
  bool shouldRepaint(_SkeletonPainter old_delegate) =>
      old_delegate.animation != animation ||
      old_delegate.motion_enabled != motion_enabled ||
      old_delegate.radius != radius ||
      old_delegate.base != base ||
      old_delegate.highlight != highlight ||
      old_delegate.reversed != reversed;
}
