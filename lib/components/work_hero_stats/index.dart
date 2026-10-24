import 'dart:math' as math;

import 'package:app/util/language_util/index.dart';
import 'package:app/components/work_hero_glass_surface/index.dart';
import 'package:flutter/material.dart';

import './style.dart';

/// 调用方提供真实业务数值；统计组件只负责排版，不推断或补造数据。
class WorkHeroStat {
  const WorkHeroStat({
    required this.icon,
    required this.value,
    required this.label,
    this.icon_color,
    this.on_tap,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? icon_color;
  final VoidCallback? on_tap;
}

/// 真实模糊底图的整块统计面板；两项或多项均分空间，大字按自然高度重排。
class WorkHeroStatsRow extends StatelessWidget {
  const WorkHeroStatsRow({
    super.key,
    required this.items,
    required this.on_hero,
    required this.is_dark,
    this.padding = EdgeInsets.zero,
  });

  final List<WorkHeroStat> items;
  final bool on_hero;
  final bool is_dark;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    final value_style = TextStyle(
      color: WorkHeroStatsStyle.value_color(on_hero: on_hero, is_dark: is_dark),
      fontSize: cjk
          ? WorkHeroStatsStyle.value_size_cjk
          : WorkHeroStatsStyle.value_size_alphabetic,
      height: cjk
          ? WorkHeroStatsStyle.value_height_cjk
          : WorkHeroStatsStyle.value_height_alphabetic,
      fontWeight: WorkHeroStatsStyle.value_weight,
    );
    final label_style = TextStyle(
      color: WorkHeroStatsStyle.label_color(on_hero: on_hero, is_dark: is_dark),
      fontSize: cjk
          ? WorkHeroStatsStyle.label_size_cjk
          : WorkHeroStatsStyle.label_size_alphabetic,
      height: cjk
          ? WorkHeroStatsStyle.label_height_cjk
          : WorkHeroStatsStyle.label_height_alphabetic,
      fontWeight: WorkHeroStatsStyle.label_weight,
    );
    return Padding(
      padding: padding,
      child: WorkHeroGlassSurface(
        on_hero: on_hero,
        is_dark: is_dark,
        surface_key: const ValueKey('work_hero_stats_glass_surface'),
        highlight_key: const ValueKey('work_hero_stats_top_highlight'),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: WorkHeroStatsStyle.surface_padding_h,
            vertical: WorkHeroStatsStyle.surface_padding_v,
          ),
          child: _layout(value_style, label_style),
        ),
      ),
    );
  }

  /// 按真实数值宽度分列，避免放大字体后截断数字；标签允许自然多行。
  Widget _layout(TextStyle value_style, TextStyle label_style) => LayoutBuilder(
    builder: (context, constraints) {
      final min_width = _minimum_item_width(context, value_style);
      final columns = math.max(
        1,
        math.min(items.length, (constraints.maxWidth / min_width).floor()),
      );
      final item_width = constraints.maxWidth / columns;
      return Wrap(
        runSpacing: WorkHeroStatsStyle.row_gap,
        children: List.generate(
          items.length,
          (index) => SizedBox(
            // 容差避免浮点相加把最后一项意外挤到下一行。
            width: math.max(
              0,
              item_width - WorkHeroStatsStyle.layout_tolerance,
            ),
            child: _item(
              items[index],
              value_style: value_style,
              label_style: label_style,
              first_in_row: index % columns == 0,
            ),
          ),
        ),
      );
    },
  );

  double _minimum_item_width(BuildContext context, TextStyle value_style) {
    var width = WorkHeroStatsStyle.item_min_width;
    for (final item in items) {
      final painter = TextPainter(
        text: TextSpan(text: item.value, style: value_style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        locale: Localizations.localeOf(context),
      )..layout();
      width = math.max(
        width,
        painter.width + WorkHeroStatsStyle.item_padding_h * 2,
      );
      painter.dispose();
    }
    return width;
  }

  /// 数值、标签和图标均居中；只限制最小触控尺寸，不锁定大字内容高度。
  Widget _item(
    WorkHeroStat item, {
    required TextStyle value_style,
    required TextStyle label_style,
    required bool first_in_row,
  }) {
    final content = ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: WorkHeroStatsStyle.item_min_height,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: first_in_row
              ? null
              : BorderDirectional(
                  start: BorderSide(
                    width: WorkHeroStatsStyle.divider_width,
                    color: WorkHeroStatsStyle.divider_color(
                      on_hero: on_hero,
                      is_dark: is_dark,
                    ),
                  ),
                ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: WorkHeroStatsStyle.item_padding_h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.value, style: value_style, textAlign: TextAlign.center),
              const SizedBox(height: WorkHeroStatsStyle.icon_label_gap),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.icon,
                    size: WorkHeroStatsStyle.icon_size,
                    color: item.icon_color ?? WorkHeroStatsStyle.icon_color,
                  ),
                  const SizedBox(width: WorkHeroStatsStyle.icon_label_gap),
                  Flexible(
                    child: Text(
                      item.label,
                      style: label_style,
                      textAlign: TextAlign.center,
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return Semantics(
      button: item.on_tap != null,
      label: '${item.label} ${item.value}',
      excludeSemantics: true,
      child: item.on_tap == null
          ? content
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: item.on_tap,
              child: content,
            ),
    );
  }
}
