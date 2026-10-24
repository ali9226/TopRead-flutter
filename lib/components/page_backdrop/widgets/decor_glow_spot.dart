import 'package:flutter/material.dart';

import '../style.dart';

/// 背景装饰光斑：半透明圆形色块，必须放在 Stack 的 children 中。
///
/// 用于在渐变底板上叠加氛围光，忽略指针事件避免拦截点击。
class DecorGlowSpot extends StatelessWidget {
  const DecorGlowSpot({
    super.key,
    required this.size,
    required this.color,
    this.top,
    this.left,
    this.right,
  });

  /// 圆形光斑的直径。
  final double size;

  /// 光斑颜色，一般使用带透明度的主题色或辅助色。
  final Color color;

  /// 距 Stack 顶部偏移；与 [top] 同时仅垂直定位。
  final double? top;

  /// 距 Stack 左侧偏移。
  final double? left;

  /// 距 Stack 右侧偏移。
  final double? right;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: PageBackdropStyle.glow_shape,
            color: color,
          ),
        ),
      ),
    );
  }
}
