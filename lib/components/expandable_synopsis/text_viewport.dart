// ignore_for_file: non_constant_identifier_names

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
  });
  final String key_prefix;
  final String description;
  final bool expanded;
  final TextStyle style;
  final VoidCallback on_collapse;

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
        maxLines: ExpandableSynopsisStyle.collapsed_lines,
      )..layout(maxWidth: constraints.maxWidth);
      final full_height = full.height;
      final collapsed_height = collapsed.height;
      full.dispose();
      collapsed.dispose();

      return ClipRect(
        child: AnimatedContainer(
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
              onTap: expanded ? on_collapse : null,
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
        ),
      );
    },
  );
}
