import 'package:flutter/material.dart';
import 'package:app/components/page_top_gradient_overlay/style.dart';
import 'package:app/components/top_header_gradient/index.dart';

/// 页面顶部渐变过渡公共组件。
class PageTopGradientOverlay extends StatefulWidget {
  /// 页面背景色。
  final Color background_color;

  /// 默认常显，既有页面沿用原外观；阅读页通过透明度连续切换。
  final bool visible;

  const PageTopGradientOverlay({
    super.key,
    required this.background_color,
    this.visible = true,
  });

  @override
  State<PageTopGradientOverlay> createState() => _PageTopGradientOverlayState();
}

class _PageTopGradientOverlayState extends State<PageTopGradientOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _visibility_controller = AnimationController(
    vsync: this,
    value: widget.visible ? 1 : 0,
  );
  bool _disable_animations = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disable_animations = MediaQuery.disableAnimationsOf(context);
    if (_disable_animations != disable_animations) {
      _disable_animations = disable_animations;
      _sync_visibility();
    }
  }

  @override
  void didUpdateWidget(covariant PageTopGradientOverlay old_widget) {
    super.didUpdateWidget(old_widget);
    if (old_widget.visible != widget.visible) _sync_visibility();
  }

  /// 反向切换始终从当前透明度开始；系统减少动画时同步停止并到达目标。
  void _sync_visibility() {
    final target = widget.visible ? 1.0 : 0.0;
    if (_disable_animations) {
      _visibility_controller.stop();
      _visibility_controller.value = target;
      return;
    }
    _visibility_controller.animateTo(
      target,
      duration: PageTopGradientOverlayStyle.visibility_duration,
      curve: PageTopGradientOverlayStyle.visibility_curve,
    );
  }

  @override
  void dispose() {
    _visibility_controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _visibility_controller,
          child: TopHeaderGradient(
            background_color: widget.background_color,
            height: PageTopGradientOverlayStyle.height,
            start_opacity: PageTopGradientOverlayStyle.start_opacity,
            middle_opacity: PageTopGradientOverlayStyle.middle_opacity,
          ),
        ),
      ),
    );
  }
}
