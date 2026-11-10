import 'dart:math' as math;

import 'package:app/components/work_hero_glass_surface/index.dart';
import 'package:app/components/work_hero_stats/index.dart';
import 'package:app/config/font_config.dart';
import 'package:app/util/language_util/index.dart';
import 'package:flutter/material.dart';

import 'book_detail_header_style.dart';

/// TODO 评分、阅读和收藏组成一块玻璃表面，大字体按真实数值宽度自然换行。
class BookHeaderStatistics extends StatelessWidget {
  const BookHeaderStatistics({
    super.key,
    required this.items,
    required this.is_dark,
    required this.compact,
  });

  final List<WorkHeroStat> items;
  final bool is_dark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bool cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    final value_style = DefaultTextStyle.of(context).style.merge(
      TextStyle(
        color: BookDetailHeaderStyle.ink,
        fontSize: compact
            ? (cjk
                  ? BookDetailHeaderStyle.compact_statistic_value_size_cjk
                  : BookDetailHeaderStyle
                        .compact_statistic_value_size_alphabetic)
            : (cjk
                  ? BookDetailHeaderStyle.statistic_value_size_cjk
                  : BookDetailHeaderStyle.statistic_value_size_alphabetic),
        height: BookDetailHeaderStyle.statistic_line_height,
        fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
        shadows: BookDetailHeaderStyle.title_shadows,
      ),
    );
    final label_style = TextStyle(
      color: BookDetailHeaderStyle.muted_ink,
      fontSize: cjk
          ? BookDetailHeaderStyle.statistic_label_size_cjk
          : BookDetailHeaderStyle.statistic_label_size_alphabetic,
      height: BookDetailHeaderStyle.statistic_label_height,
      fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
      shadows: BookDetailHeaderStyle.title_shadows,
    );
    final double icon_size = compact
        ? BookDetailHeaderStyle.compact_statistic_icon_size
        : BookDetailHeaderStyle.statistic_icon_size;

    return WorkHeroGlassSurface(
      on_hero: true,
      is_dark: is_dark,
      surface_key: const ValueKey('directory_header_statistics_glass'),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: BookDetailHeaderStyle.statistics_padding_h,
          vertical: compact
              ? BookDetailHeaderStyle.compact_statistics_padding_v
              : BookDetailHeaderStyle.statistics_padding_v,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            double min_width = compact
                ? BookDetailHeaderStyle.compact_statistic_min_width
                : BookDetailHeaderStyle.statistic_min_width;
            for (final item in items) {
              final painter = TextPainter(
                text: TextSpan(text: item.value, style: value_style),
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
              )..layout();
              min_width = math.max(
                min_width,
                painter.width +
                    icon_size +
                    BookDetailHeaderStyle.statistic_icon_gap +
                    BookDetailHeaderStyle.statistic_item_padding * 2,
              );
              painter.dispose();
            }
            final columns = math.max(
              1,
              math.min(
                items.length,
                (constraints.maxWidth / min_width).floor(),
              ),
            );
            final width = math.max(
              0.0,
              constraints.maxWidth / columns -
                  BookDetailHeaderStyle.layout_tolerance,
            );
            return Wrap(
              runSpacing: BookDetailHeaderStyle.statistic_row_gap,
              children: List.generate(items.length, (index) {
                final item = items[index];
                return Semantics(
                  label: '${item.value} ${item.label}',
                  excludeSemantics: true,
                  child: Container(
                    width: width,
                    padding: const EdgeInsets.symmetric(
                      horizontal: BookDetailHeaderStyle.statistic_item_padding,
                    ),
                    decoration: BoxDecoration(
                      border: index % columns == 0
                          ? null
                          : BorderDirectional(
                              start: BorderSide(
                                width: BookDetailHeaderStyle
                                    .statistic_divider_width,
                                color: BookDetailHeaderStyle.ink.withValues(
                                  alpha: BookDetailHeaderStyle
                                      .statistic_divider_opacity,
                                ),
                              ),
                            ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.icon,
                              size: icon_size,
                              color: BookDetailHeaderStyle.accent,
                            ),
                            const SizedBox(
                              width: BookDetailHeaderStyle.statistic_icon_gap,
                            ),
                            Flexible(
                              child: Text(item.value, style: value_style),
                            ),
                          ],
                        ),
                        if (!compact) ...[
                          const SizedBox(
                            height: BookDetailHeaderStyle.statistic_label_gap,
                          ),
                          Text(
                            item.label,
                            textAlign: TextAlign.center,
                            style: label_style,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
