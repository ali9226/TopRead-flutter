import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app/api/post_request.dart';
import 'package:app/components/recommend_book_card/book_list_item.dart';
import 'package:app/components/recommend_book_card/style.dart';
import 'package:app/components/recommend_book_card/index.dart';
import 'package:app/components/recommend_book_card/style.dart' as card_style;
import 'package:app/components/load_more_footer/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/recommend_ranking_item.dart';
import 'package:app/stores/home_store.dart';
import 'package:app/util/novel_navigation/index.dart';

/// 推荐书籍瀑布流组件（带动画重排支持）。
///
/// 使用 [Stack] + [AnimatedPositioned] 实现，
/// 删除卡片后所有剩余卡片会平滑移动到新位置。
/// 统一管理弹窗状态，确保同时只有一个弹窗显示。
///
/// 数据来自后端 `novel/recommend_ranking` 接口，
/// 通过 [no_ids] 排除已加载的小说实现分页。
class AnimatedRecommendWaterfall extends StatefulWidget {
  /// 当前是否为夜间模式。
  final bool is_dark;

  const AnimatedRecommendWaterfall({
    super.key,
    required this.is_dark,
  });

  @override
  State<AnimatedRecommendWaterfall> createState() => AnimatedRecommendWaterfallState();
}

class AnimatedRecommendWaterfallState extends State<AnimatedRecommendWaterfall> {
  /// 所有书籍数据。
  final List<BookListItem> _items = <BookListItem>[];

  /// 正在执行删除动画的卡片 ID。
  final Set<String> _removing_ids = <String>{};

  /// 每个卡片的测量高度（用于计算位置）。
  final Map<String, double> _item_heights = <String, double>{};

  /// 当前列数。
  int _column_count = 2;

  /// 当前总宽度。
  double _total_width = 0;

  /// 首页数据仓库。
  final HomeBannerStore _home_store = Get.find<HomeBannerStore>();

  /// 当前显示弹窗的卡片 ID（null 表示没有弹窗）。
  String? _active_overlay_id;

  /// 是否正在加载更多数据。
  bool _is_loading_more = false;

  /// 是否正在加载首屏数据。
  bool _is_initial_loading = true;

  /// 是否还有更多数据可加载。
  bool _has_more = true;

  /// 标签颜色池。
  static const List<Color> _tag_color_pool = <Color>[
    Color(0xFF2FBF9B),
    Color(0xFF5F8BFF),
    Color(0xFFF56C6C),
    Color(0xFFFF9F5A),
    Color(0xFF8B7CFF),
    Color(0xFFE6A23C),
  ];

  @override
  void initState() {
    super.initState();
    _load_initial_data();
  }

  /// 加载首屏数据。
  Future<void> _load_initial_data() async {
    setState(() {
      _is_initial_loading = true;
    });

    final List<BookListItem> items = await _fetch_recommend_list();

    if (!mounted) return;

    setState(() {
      _items.addAll(items);
      _is_initial_loading = false;
      _has_more = items.isNotEmpty;
    });
  }

  /// 加载更多数据。
  ///
  /// 当滚动到底部时由父组件调用，加载下一页数据并追加到列表。
  Future<void> load_more() async {
    if (_is_loading_more || !_has_more) return;

    setState(() {
      _is_loading_more = true;
    });

    // 收集已加载的小说 ID 作为排除参数。
    final List<int> no_ids = _items
        .where((BookListItem item) => item.is_book)
        .map((BookListItem item) => item.story_id)
        .toList();

    final List<BookListItem> new_items = await _fetch_recommend_list(
      no_ids: no_ids,
    );

    if (!mounted) return;

    setState(() {
      _items.addAll(new_items);
      _has_more = new_items.isNotEmpty;
      _is_loading_more = false;
    });
  }

  /// 请求推荐榜小说列表并映射为 BookListItem。
  ///
  /// [no_ids] - 已加载的小说 ID，用于排除已展示的数据。
  Future<List<BookListItem>> _fetch_recommend_list({
    List<int>? no_ids,
  }) async {
    try {
      final results = await postRequest<List<RecommendRankingItem>>(
        path: 'novel/recommend_ranking',
        showTips: false,
        parameter: <String, dynamic>{
          if (no_ids != null && no_ids.isNotEmpty) 'no_ids': no_ids,
        },
        fromJsonList: (List<dynamic> json) =>
            RecommendRankingItem.from_json_list(json),
      );

      if (!results.status || results.content == null) {
        return <BookListItem>[];
      }

      return _map_to_book_list_items(results.content!);
    } catch (_) {
      return <BookListItem>[];
    }
  }

  /// 将推荐榜数据映射为 BookListItem 列表。
  List<BookListItem> _map_to_book_list_items(
    List<RecommendRankingItem> source,
  ) {
    return source.map((RecommendRankingItem item) {
      // 标签：取分类列表前 2 个，颜色从池中按索引选取。
      final List<BookListTagItem> tags = item.category_list
          .take(2)
          .toList()
          .asMap()
          .entries
          .map((MapEntry<int, String> entry) {
        final Color color = _tag_color_pool[
            (item.id * 7 + entry.key * 3) % _tag_color_pool.length];
        return BookListTagItem(label: entry.value, color: color);
      }).toList();

      // 封面左下角附加信息：评分或热度。
      String meta_text = '';
      if (item.score > 0) {
        meta_text = '${item.score.toStringAsFixed(1)}分';
      }

      return BookListItem(
        id: 'recommend_${item.id}',
        story_id: item.id,
        type: BookListItemType.book,
        title: item.title,
        description: item.introduction,
        cover_url: item.cover_url,
        cover_badge: item.publish_status == 2 ? '完结' : '',
        cover_meta_text: meta_text,
        tag_list: tags,
        ad_image_url_list: const <String>[],
        publish_status: item.publish_status,
      );
    }).toList();
  }

  /// 是否正在加载更多数据。
  bool get is_loading_more => _is_loading_more;

  /// 显示指定卡片的弹窗。
  void _show_overlay(String item_id) {
    if (_active_overlay_id == item_id) return;
    setState(() {
      _active_overlay_id = item_id;
    });
    _home_store.is_recommend_overlay_open.value = true;
  }

  /// 关闭当前弹窗。
  void close_overlay() {
    if (_active_overlay_id == null) return;
    setState(() {
      _active_overlay_id = null;
    });
    _home_store.is_recommend_overlay_open.value = false;
  }

  /// 删除指定索引的卡片。
  void remove_at(int index) {
    if (index < 0 || index >= _items.length) return;
    if (_removing_ids.contains(_items[index].id)) return;

    final String id = _items[index].id;

    setState(() {
      _removing_ids.add(id);
      // 如果删除的是当前显示弹窗的卡片，关闭弹窗
      if (_active_overlay_id == id) {
        _active_overlay_id = null;
      }
    });

    // 动画完成后移除数据
    Future<void>.delayed(
      Duration(milliseconds: card_style.RecommendBookCardStyle.delete_animation_duration_ms),
    ).then((_) {
      if (mounted) {
        setState(() {
          _items.removeWhere((BookListItem item) => item.id == id);
          _removing_ids.remove(id);
          _item_heights.remove(id);
        });
      }
    });
  }

  /// 计算每个卡片的位置和尺寸。
  Map<String, Rect> _calculate_layout() {
    if (_total_width == 0) return <String, Rect>{};

    final double column_width =
        (_total_width - RecommendBookCardStyle.column_spacing * (_column_count - 1)) /
            _column_count;

    final List<double> column_heights = List<double>.filled(_column_count, 0);
    final Map<String, Rect> positions = <String, Rect>{};

    for (int i = 0; i < _items.length; i++) {
      final BookListItem item = _items[i];
      final bool is_removing = _removing_ids.contains(item.id);

      int shortest_column = 0;
      double min_height = column_heights[0];
      for (int c = 1; c < _column_count; c++) {
        if (column_heights[c] < min_height) {
          min_height = column_heights[c];
          shortest_column = c;
        }
      }

      final double x = shortest_column * (column_width + RecommendBookCardStyle.column_spacing);
      final double item_height = _item_heights[item.id] ?? card_style.RecommendBookCardStyle.default_card_height;
      final double effective_height = is_removing ? 0 : item_height;

      positions[item.id] = Rect.fromLTWH(
        x,
        column_heights[shortest_column],
        column_width,
        effective_height,
      );

      if (!is_removing) {
        column_heights[shortest_column] += item_height + RecommendBookCardStyle.item_spacing;
      }
    }

    return positions;
  }

  /// 计算总高度。
  double _calculate_total_height(Map<String, Rect> positions) {
    double max_bottom = 0;
    for (final Rect rect in positions.values) {
      final double bottom = rect.top + rect.height;
      if (bottom > max_bottom) {
        max_bottom = bottom;
      }
    }
    return max_bottom;
  }

  @override
  Widget build(BuildContext context) {
    // 首屏加载中时展示骨架屏。
    if (_is_initial_loading) {
      return _build_skeleton();
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        _total_width = constraints.maxWidth;
        _column_count = _resolve_column_count(_total_width);

        final Map<String, Rect> positions = _calculate_layout();
        final double total_height = _calculate_total_height(positions);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height: total_height,
              child: Stack(
                children: _items.map((BookListItem item) {
                  final Rect? rect = positions[item.id];
                  if (rect == null) return const SizedBox.shrink();

                  final bool is_removing = _removing_ids.contains(item.id);
                  final bool is_active = _active_overlay_id == item.id;

                  return AnimatedPositioned(
                    key: ValueKey<String>(item.id),
                    duration: const Duration(
                      milliseconds: card_style.RecommendBookCardStyle.reorder_animation_duration_ms,
                    ),
                    curve: Curves.easeOutCubic,
                    left: rect.left,
                    top: rect.top,
                    width: rect.width,
                    child: AnimatedOpacity(
                      duration: const Duration(
                        milliseconds: card_style.RecommendBookCardStyle.fade_out_animation_duration_ms,
                      ),
                      opacity: is_removing ? 0.0 : 1.0,
                      curve: Curves.easeOut,
                      child: _MeasurableWidget(
                        on_height_measured: (double height) {
                          if (_item_heights[item.id] != height && mounted) {
                            setState(() {
                              _item_heights[item.id] = height;
                            });
                          }
                        },
                          child: RecommendBookCard(
                            item: item,
                            is_dark: widget.is_dark,
                            show_overlay: is_active,
                            on_long_press: () {
                              _show_overlay(item.id);
                            },
                            on_overlay_close: close_overlay,
                            on_tap: () {
                              // 如果点击的卡片有弹窗，只关闭弹窗，不跳转
                              if (_active_overlay_id == item.id) {
                                close_overlay();
                                return;
                              }
                              // 如果其他卡片有弹窗，关闭弹窗并跳转
                              if (_active_overlay_id != null) {
                                close_overlay();
                              }
                              navigate_to_novel(
                                id: item.story_id,
                                title: item.title,
                                publish_status: item.publish_status,
                              );
                            },
                            on_dislike: () {
                              final int index = _items.indexOf(item);
                              if (index >= 0) {
                                remove_at(index);
                              }
                            },
                          ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            // 加载更多 / 没有了 底部组件
            LoadMoreFooter(
              is_dark: widget.is_dark,
              isLoading: _is_loading_more,
              hasMore: _has_more,
              onLoadMore: load_more,
            ),
          ],
        );
      },
    );
  }

  /// 构建首屏骨架屏。
  Widget _build_skeleton() {
    final Color base_color = widget.is_dark
        ? const Color(0xFF252836)
        : const Color(0xFFF0F1F5);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(3, (int index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // 左列骨架
              Expanded(
                child: Container(
                  height: 200 + (index % 2) * 30.0,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: base_color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              // 右列骨架
              Expanded(
                child: Container(
                  height: 220 - (index % 2) * 20.0,
                  margin: const EdgeInsets.only(left: 6),
                  decoration: BoxDecoration(
                    color: base_color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  /// 根据可用宽度推导出当前列数。
  int _resolve_column_count(double total_width) {
    final int estimated =
        ((total_width + RecommendBookCardStyle.column_spacing) /
                (RecommendBookCardStyle.min_item_width +
                    RecommendBookCardStyle.column_spacing))
            .floor();

    return estimated.clamp(
      RecommendBookCardStyle.min_column_count,
      RecommendBookCardStyle.max_column_count,
    );
  }
}

/// 可测量高度的 Widget 包装。
///
/// 用于自动测量子组件的实际高度，并通过回调通知父组件。
/// 当子组件高度发生变化时（如文本内容变化、布局更新），
/// 会自动触发 [on_height_measured] 回调，确保瀑布流布局正确计算位置。
class _MeasurableWidget extends StatefulWidget {
  /// 需要测量高度的子组件。
  final Widget child;

  /// 高度变化回调，参数为子组件的实际高度（像素）。
  final ValueChanged<double> on_height_measured;

  const _MeasurableWidget({
    required this.child,
    required this.on_height_measured,
  });

  @override
  State<_MeasurableWidget> createState() => _MeasurableWidgetState();
}

class _MeasurableWidgetState extends State<_MeasurableWidget> {
  /// 上次测量的高度，用于避免重复触发回调。
  double _last_height = 0;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (_) {
        _measure();
        return false;
      },
      child: SizeChangedLayoutNotifier(
        child: widget.child,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measure();
    });
  }

  /// 测量子组件高度，当高度变化超过 1 像素时触发回调。
  void _measure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final double height = box.size.height;
        if ((height - _last_height).abs() > 1) {
          _last_height = height;
          widget.on_height_measured(height);
        }
      }
    });
  }
}
