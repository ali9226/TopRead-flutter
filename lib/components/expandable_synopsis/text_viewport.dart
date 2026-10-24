// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;

import 'package:app/config/color_config.dart';
import './style.dart';
import 'package:flutter/material.dart';

/// 正文始终以完整行数排版，仅动画改变外层裁切高度，收起时不提前删除后续文字。
class ExpandableSynopsisTextViewport extends StatelessWidget {
  const ExpandableSynopsisTextViewport({
    super.key,
    required this.description,
    required this.expanded,
    required this.style,
    required this.on_collapse,
    this.key_prefix = 'synopsis',
    this.fade_surface_color,
    this.collapsed_lines = ExpandableSynopsisStyle.collapsed_lines,
    this.fade_line_ratio = ExpandableSynopsisStyle.fade_line_ratio,
    this.transparent_fade = false,
    this.collapse_on_text_tap = true,
  }) : assert(collapsed_lines > 0),
       assert(fade_line_ratio >= 0);
  final String key_prefix;
  final String description;
  final bool expanded;
  final TextStyle style;
  final VoidCallback on_collapse;
  final int collapsed_lines;

  /// 截断渐变相对于一行正文的高度；漫画两行预览使用更轻的遮罩。
  final double fade_line_ratio;

  /// 磨砂表面直接淡出文字透明度，不以纸面颜色覆盖透出的底图。
  final bool transparent_fade;

  /// 短篇封面简介仅允许双箭头控制展开，正文自身保持只读。
  final bool collapse_on_text_tap;

  /// 所在纸面色，折叠时以对应渐变轻盖截断处；兼容旧独立视口调用。
  final Color? fade_surface_color;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final defaults = DefaultTextStyle.of(context);
      final effective_style = defaults.style.merge(style);
      final scaler = MediaQuery.textScalerOf(context);
      final direction = Directionality.of(context);
      final locale = Localizations.maybeLocaleOf(context);
      final span = TextSpan(text: description, style: effective_style);
      final full = TextPainter(
        text: span,
        textDirection: direction,
        textScaler: scaler,
        locale: locale,
        textHeightBehavior: defaults.textHeightBehavior,
      )..layout(maxWidth: constraints.maxWidth);
      final collapsed = TextPainter(
        text: span,
        textDirection: direction,
        textScaler: scaler,
        locale: locale,
        textHeightBehavior: defaults.textHeightBehavior,
        maxLines: collapsed_lines,
      )..layout(maxWidth: constraints.maxWidth);
      final full_height = full.height;
      final collapsed_height = collapsed.height;
      final truncated = collapsed.didExceedMaxLines;
      final fade_height = math.min(
        collapsed_height,
        scaler.scale(
              effective_style.fontSize ??
                  ExpandableSynopsisStyle.font_size_alphabetic,
            ) *
            (effective_style.height ?? 1) *
            fade_line_ratio,
      );
      full.dispose();
      collapsed.dispose();

      final viewport = AnimatedContainer(
        key: ValueKey('${key_prefix}_viewport'),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : expanded
            ? ExpandableSynopsisStyle.expand_duration
            : ExpandableSynopsisStyle.collapse_duration,
        curve: Curves.easeInOutCubic,
        height: expanded ? full_height : collapsed_height,
        alignment: Alignment.topLeft,
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: constraints.maxWidth,
          maxWidth: constraints.maxWidth,
          minHeight: full_height,
          maxHeight: full_height,
          child: InkWell(
            key: ValueKey('${key_prefix}_text'),
            onTap: expanded && collapse_on_text_tap ? on_collapse : null,
            child: Text(
              description,
              maxLines: null,
              softWrap: true,
              overflow: TextOverflow.visible,
              textHeightBehavior: defaults.textHeightBehavior,
              style: effective_style,
            ),
          ),
        ),
      );
      return ClipRect(
        child: Stack(
          children: [
            if (transparent_fade)
              ShaderMask(
                key: ValueKey('${key_prefix}_fade'),
                blendMode: BlendMode.dstIn,
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: const [
                    ColorConstants.whiteColor,
                    ColorConstants.whiteColor,
                    ColorConstants.transparent_white,
                  ],
                  stops: [
                    0,
                    expanded || !truncated || bounds.height <= 0
                        ? 1
                        : (1 - fade_height / bounds.height).clamp(0, 1),
                    1,
                  ],
                ).createShader(bounds),
                child: viewport,
              )
            else
              viewport,
            if (!expanded &&
                truncated &&
                !transparent_fade &&
                fade_surface_color != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: fade_height,
                child: IgnorePointer(
                  child: DecoratedBox(
                    key: ValueKey('${key_prefix}_fade'),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: ExpandableSynopsisStyle.fade_stops,
                        colors: [
                          fade_surface_color!.withValues(alpha: 0),
                          fade_surface_color!.withValues(
                            alpha: ExpandableSynopsisStyle.fade_middle_alpha,
                          ),
                          fade_surface_color!.withValues(
                            alpha: ExpandableSynopsisStyle.fade_bottom_alpha,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}
