import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';

import 'pulse.dart';
import 'style.dart';

/// 保留真实文字行框及系统文字缩放，只在字形墨迹处绘制骨架条。
class SkeletonTextLine extends StatelessWidget {
  const SkeletonTextLine({
    super.key,
    required this.font_size,
    required this.line_height,
    this.width,
    this.width_factor = 1,
    this.on_hero = false,
    this.alignment = AlignmentDirectional.centerStart,
    this.text_style,
  });

  final double font_size;
  final double line_height;
  final double? width;
  final double width_factor;
  final bool on_hero;
  final AlignmentGeometry alignment;
  final TextStyle? text_style;

  @override
  Widget build(BuildContext context) {
    final scaled_size = MediaQuery.textScalerOf(context).scale(font_size);
    // Flutter 的首尾行框包含字体升部/降部及像素取整，直接乘字号会累积误差。
    final painter = TextPainter(
      text: TextSpan(
        text: 'Ag',
        style: DefaultTextStyle.of(context).style.merge(
          text_style ??
              TextStyle(
                fontSize: font_size,
                height: line_height,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
              ),
        ),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.localeOf(context),
    )..layout();
    final measured_height = painter.height;
    painter.dispose();
    return SizedBox(
      height: measured_height,
      child: Align(
        alignment: alignment,
        child: FractionallySizedBox(
          widthFactor: width_factor,
          child: Align(
            alignment: alignment,
            child: SkeletonBlock(
              width: width,
              height: scaled_size * WorkDetailSkeletonStyle.text_ink_ratio,
              on_hero: on_hero,
            ),
          ),
        ),
      ),
    );
  }
}
