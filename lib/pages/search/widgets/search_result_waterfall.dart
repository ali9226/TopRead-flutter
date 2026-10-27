import 'package:flutter/material.dart';

import 'package:app/models/work_search.dart';
import 'package:app/pages/search/style.dart';
import 'package:app/pages/search/widgets/measurable_widget.dart';
import 'package:app/pages/search/widgets/search_result_card.dart';

/// 搜索结果瀑布流组件。
///
/// 使用 Stack + Positioned 实现瀑布流布局，
/// 通过 [_MeasurableWidget] 动态测量每个卡片高度来计算位置。
class SearchResultWaterfall extends StatefulWidget {
  final List<SearchResultItem> items;
  final bool is_dark;

  const SearchResultWaterfall({
    super.key,
    required this.items,
    required this.is_dark,
  });

  @override
  State<SearchResultWaterfall> createState() => _SearchResultWaterfallState();
}

class _SearchResultWaterfallState extends State<SearchResultWaterfall> {
  final Map<String, double> _item_heights = <String, double>{};
  int _column_count = Style.result_min_columns;
  double _total_width = 0;

  Map<String, Rect> _calculate_layout() {
    if (_total_width == 0) return <String, Rect>{};
    final double column_width =
        (_total_width - Style.result_grid_gap * (_column_count - 1)) /
        _column_count;
    final List<double> column_heights = List<double>.filled(_column_count, 0);
    final Map<String, Rect> positions = <String, Rect>{};

    for (int i = 0; i < widget.items.length; i++) {
      final SearchResultItem item = widget.items[i];
      int shortest_column = 0;
      double min_height = column_heights[0];
      for (int c = 1; c < _column_count; c++) {
        if (column_heights[c] < min_height) {
          min_height = column_heights[c];
          shortest_column = c;
        }
      }
      final double x = shortest_column * (column_width + Style.result_grid_gap);
      final double item_height =
          _item_heights[item.id] ?? Style.result_estimated_height;
      positions[item.id] = Rect.fromLTWH(
        x,
        column_heights[shortest_column],
        column_width,
        item_height,
      );
      column_heights[shortest_column] += item_height + Style.result_grid_gap;
    }
    return positions;
  }

  double _calculate_total_height(Map<String, Rect> positions) {
    double max_bottom = 0;
    for (final Rect rect in positions.values) {
      final double bottom = rect.top + rect.height;
      if (bottom > max_bottom) max_bottom = bottom;
    }
    return max_bottom;
  }

  int _resolve_column_count(double total_width) {
    final int estimated =
        ((total_width + Style.result_grid_gap) /
                (Style.result_column_width + Style.result_grid_gap))
            .floor();
    return estimated.clamp(Style.result_min_columns, Style.result_max_columns);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        _total_width = constraints.maxWidth;
        _column_count = _resolve_column_count(_total_width);
        final Map<String, Rect> positions = _calculate_layout();
        final double total_height = _calculate_total_height(positions);

        return SizedBox(
          height: total_height,
          child: Stack(
            children: widget.items.map((SearchResultItem item) {
              final Rect? rect = positions[item.id];
              if (rect == null) return const SizedBox.shrink();

              return Positioned(
                key: ValueKey<String>(item.id),
                left: rect.left,
                top: rect.top,
                width: rect.width,
                child: MeasurableWidget(
                  on_height_measured: (double height) {
                    if (_item_heights[item.id] != height && mounted) {
                      setState(() {
                        _item_heights[item.id] = height;
                      });
                    }
                  },
                  child: SearchResultCard(item: item, is_dark: widget.is_dark),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
