import 'package:flutter/material.dart';

/// 顶部渐变过渡遮罩组件。
///
/// 用途：
/// 1. 用于页面顶部从“实色”到“透明”的柔和过渡。
/// 2. 通常放在页面最上层，并配合 `IgnorePointer` 使用，避免遮挡点击。
class TopHeaderGradient extends StatelessWidget {
  /// 基础颜色。
  final Color background_color;

  /// 渐变层高度。
  final double height;

  /// 顶部不透明度。
  final double start_opacity;

  /// 中段不透明度。
  final double middle_opacity;

  const TopHeaderGradient({
    super.key,
    required this.background_color,
    required this.height,
    required this.start_opacity,
    required this.middle_opacity,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              background_color.withValues(alpha: start_opacity),
              background_color.withValues(alpha: middle_opacity),
              background_color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
