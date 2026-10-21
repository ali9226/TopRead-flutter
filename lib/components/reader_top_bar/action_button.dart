// ignore_for_file: non_constant_identifier_names

import 'package:app/components/reader_top_bar/style.dart';
import 'package:app/config/color_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// TODO 返回、分享沿用小说SVG；收藏支持原生心形，均保留弹性缩放和加载交互。
class ReaderTopBarAction extends StatefulWidget {
  const ReaderTopBarAction({
    super.key,
    this.asset,
    this.icon,
    required this.label,
    required this.color,
    required this.on_pressed,
    this.selected,
    this.loading = false,
    this.reverse = false,
    this.elastic = true,
  }) : assert(asset != null || icon != null);
  final String? asset;
  final IconData? icon;
  final String label;
  final Color color;
  final VoidCallback? on_pressed;
  final bool? selected;
  final bool loading;
  final bool reverse;
  final bool elastic;

  @override
  State<ReaderTopBarAction> createState() => _ReaderTopBarActionState();
}

class _ReaderTopBarActionState extends State<ReaderTopBarAction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: ReaderTopBarStyle.elastic_duration,
    value: 1,
  );
  late final Animation<double> _scale = Tween<double>(
    begin: ReaderTopBarStyle.elastic_begin,
    end: 1,
  ).animate(CurvedAnimation(parent: _animation, curve: Curves.elasticOut));

  void _animate() {
    if (widget.elastic && !ReaderTopBarStyle.reduce_motion(context)) {
      _animation.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(covariant ReaderTopBarAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) _animate();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget icon = widget.icon != null
        ? Icon(
            widget.icon,
            key: ValueKey(widget.icon),
            size: ReaderTopBarStyle.icon,
            color: widget.color,
          )
        : SvgPicture.asset(
            'assets/svg/${widget.asset}.svg',
            key: ValueKey(widget.asset),
            width: ReaderTopBarStyle.icon,
            height: ReaderTopBarStyle.icon,
            colorFilter: ColorFilter.mode(widget.color, BlendMode.srcIn),
          );
    if (widget.reverse) icon = RotatedBox(quarterTurns: 2, child: icon);
    return Semantics(
      toggled: widget.selected,
      child: IconButton(
        tooltip: widget.label,
        onPressed: widget.loading || widget.on_pressed == null
            ? null
            : () {
                _animate();
                widget.on_pressed?.call();
              },
        constraints: const BoxConstraints(
          minHeight: ReaderTopBarStyle.target,
          minWidth: ReaderTopBarStyle.target,
        ),
        icon: widget.loading
            ? SizedBox.square(
                dimension: ReaderTopBarStyle.spinner,
                child: CircularProgressIndicator(
                  strokeWidth: ReaderTopBarStyle.stroke,
                  color: ColorConstants.themeColor,
                ),
              )
            : AnimatedBuilder(
                animation: _scale,
                child: icon,
                builder: (_, child) =>
                    Transform.scale(scale: _scale.value, child: child),
              ),
      ),
    );
  }
}
