// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart' as easy;

import 'package:app/api/post_request.dart';
import 'package:app/components/recommend_book_card/book_list_item.dart';
import 'package:app/components/recommend_book_card/logic.dart';
import 'package:app/components/recommend_book_card/style.dart';
import 'package:app/components/recommend_book_card/index.dart';
import 'package:app/components/recommend_book_card/style.dart' as card_style;
import 'package:app/components/recommend_book_card/widgets/recommend_waterfall_skeleton.dart';
import 'package:app/components/recommend_book_card/widgets/masonry_native_ad_card.dart';
import 'package:app/components/load_more_footer/index.dart';
import 'package:app/models/recommend_ranking_item.dart';
import 'package:app/services/masonry_native_ad_pool.dart';
import 'package:app/stores/home_store.dart';
import 'package:app/stores/project_config_store.dart';
import 'package:app/stores/recommend_waterfall_store.dart';
import 'package:app/util/ad_display_policy.dart';
import 'package:app/util/language_util/language_change_handler.dart';
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
  /// 当前瀑布流在 App 进程内的稳定唯一标识。
  ///
  /// 不同页面或 Tab 必须传入不同值，同一页面重建时必须
  /// 保持不变，以便独立恢复数据、排版与广告。
  final String waterfall_id;

  /// 当前是否为夜间模式。
  final bool is_dark;

  const AnimatedRecommendWaterfall({
    super.key,
    required this.waterfall_id,
    required this.is_dark,
  });

  @override
  State<AnimatedRecommendWaterfall> createState() =>
      AnimatedRecommendWaterfallState();
}

class AnimatedRecommendWaterfallState
    extends State<AnimatedRecommendWaterfall> {
  /// 当前组件对应的全局独立会话。
  late RecommendWaterfallSession _session;

  List<BookListItem> get _items => _session.items;
  Set<String> get _removing_ids => _session.removing_ids;
  Map<String, double> get _item_heights => _session.item_heights;

  String? get _active_overlay_id => _session.active_overlay_id;
  set _active_overlay_id(String? value) => _session.active_overlay_id = value;

  bool get _is_loading_more => _session.is_loading_more;
  set _is_loading_more(bool value) => _session.is_loading_more = value;

  bool get _is_initial_loading => _session.is_initial_loading;
  set _is_initial_loading(bool value) => _session.is_initial_loading = value;

  bool get _has_more => _session.has_more;
  set _has_more(bool value) => _session.has_more = value;

  int get _request_generation => _session.request_generation;
  set _request_generation(int value) => _session.request_generation = value;

  /// 当前列数。
  int _column_count = 2;

  /// 当前总宽度。
  double _total_width = 0;

  /// 首页数据仓库。
  final HomeBannerStore _home_store = Get.find<HomeBannerStore>();

  /// 语种刷新任务订阅。
  late final LanguageRefreshSubscription _language_refresh_subscription;

  /// 项目广告开关变更监听器。
  late final Worker _ad_policy_worker;

  /// 上一次已应用到瀑布流会话的广告展示状态。
  late bool _can_show_ads;

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
    _attach_session();
    _can_show_ads = AdDisplayPolicy.can_show_ads();
    _ad_policy_worker = ever(
      Get.find<ProjectConfigStore>().config_revision,
      (_) => _on_ad_policy_changed(),
    );
    _language_refresh_subscription =
        LanguageChangeHandler.register_refresh_task(
          phase: LanguageRefreshPhase.content,
          on_prepare: _prepare_language_refresh,
          on_refresh: _refresh_for_language,
        );
    final int current_revision = LanguageChangeHandler.current_revision;
    if (!_session.has_initialized ||
        _session.language_revision != current_revision) {
      _load_initial_data(language_revision: current_revision);
    }
  }

  @override
  void didUpdateWidget(AnimatedRecommendWaterfall old_widget) {
    super.didUpdateWidget(old_widget);
    if (old_widget.waterfall_id == widget.waterfall_id) return;
    _session.removeListener(_on_session_changed);
    _attach_session();
    final int current_revision = LanguageChangeHandler.current_revision;
    if (!_session.has_initialized ||
        _session.language_revision != current_revision) {
      _load_initial_data(language_revision: current_revision);
    }
  }

  @override
  void dispose() {
    _session.removeListener(_on_session_changed);
    _ad_policy_worker.dispose();
    _language_refresh_subscription.dispose();
    super.dispose();
  }

  /// 连接稳定 ID 对应的全局会话。
  void _attach_session() {
    _session = Get.find<RecommendWaterfallStore>().obtain(widget.waterfall_id);
    _session.addListener(_on_session_changed);
  }

  /// 全局会话被异步请求或其他挂载实例更新后刷新 UI。
  void _on_session_changed() {
    if (!mounted) return;
    setState(() {});
  }

  /// 同步远端广告平台开关到当前瀑布流会话。
  ///
  /// 关闭时立即移除并释放全部广告槽位；开启时为已经加载的小说批次补充
  /// 一个新广告槽位，后续分页仍按每批一个广告槽位处理。
  void _on_ad_policy_changed() {
    final bool can_show_ads = AdDisplayPolicy.can_show_ads();
    if (_can_show_ads == can_show_ads) return;
    _can_show_ads = can_show_ads;

    if (!can_show_ads) {
      final List<String> ad_slot_ids = _session.items
          .where((BookListItem item) => item.is_ad)
          .map((BookListItem item) => item.id)
          .toList();
      MasonryNativeAdPool.remove_all(ad_slot_ids);
      _update_session(() {
        _session.items.removeWhere((BookListItem item) => item.is_ad);
        for (final String slot_id in ad_slot_ids) {
          _session.item_heights.remove(slot_id);
        }
      });
      return;
    }

    if (_session.items.any((BookListItem item) => item.is_ad)) return;
    final List<BookListItem> books = _session.items
        .where((BookListItem item) => item.is_book)
        .toList();
    if (books.isEmpty) return;
    _update_session(() {
      _session.items
        ..clear()
        ..addAll(
          _insert_fresh_ad_in_batch_middle(books, target_session: _session),
        );
    });
  }

  /// 原子更新当前会话并通知所有挂载页面。
  void _update_session(VoidCallback update) {
    _update_target_session(_session, update);
  }

  /// 原子更新指定会话，保证旧请求不会写入后续切换的会话。
  void _update_target_session(
    RecommendWaterfallSession target_session,
    VoidCallback update,
  ) {
    update();
    target_session.mark_changed();
  }

  /// 释放已明确从会话数据中移除的广告槽位。
  void _release_ad_slots(RecommendWaterfallSession target_session) {
    MasonryNativeAdPool.remove_all(
      target_session.items
          .where((BookListItem item) => item.is_ad)
          .map((BookListItem item) => item.id),
    );
  }

  /// Locale 切换前立即隐藏旧语种瀑布流并让旧请求失效。
  void _prepare_language_refresh(LanguageRefreshContext refresh_context) {
    _release_ad_slots(_session);
    _request_generation++;
    _home_store.is_recommend_overlay_open.value = false;
    _update_session(() {
      _items.clear();
      _removing_ids.clear();
      _item_heights.clear();
      _active_overlay_id = null;
      _is_initial_loading = true;
      _is_loading_more = false;
      _has_more = true;
      _session.has_initialized = false;
      _session.is_initial_request_active = false;
      _session.language_revision = refresh_context.revision;
    });
  }

  /// 基础配置刷新后重新请求当前语种瀑布流。
  Future<void> _refresh_for_language(
    LanguageRefreshContext refresh_context,
  ) async {
    if (!mounted || !refresh_context.is_current) return;
    await _load_initial_data(language_revision: refresh_context.revision);
  }

  /// 加载首屏数据。
  Future<void> _load_initial_data({int? language_revision}) async {
    final RecommendWaterfallSession target_session = _session;
    final int revision =
        language_revision ?? LanguageChangeHandler.current_revision;
    if (target_session.is_initial_request_active &&
        target_session.language_revision == revision) {
      return;
    }

    final int generation = ++target_session.request_generation;
    _release_ad_slots(target_session);
    _update_target_session(target_session, () {
      target_session.has_initialized = true;
      target_session.is_initial_request_active = true;
      target_session.language_revision = revision;
      target_session.is_initial_loading = true;
      target_session.is_loading_more = false;
      target_session.items.clear();
      target_session.removing_ids.clear();
      target_session.item_heights.clear();
      target_session.has_more = true;
    });

    final List<BookListItem> items = await _fetch_recommend_list();

    if (generation != target_session.request_generation ||
        !LanguageChangeHandler.is_current_revision(revision)) {
      return;
    }

    _update_target_session(target_session, () {
      if (items.isNotEmpty) {
        target_session.items.addAll(
          _insert_fresh_ad_in_batch_middle(
            items,
            target_session: target_session,
          ),
        );
      }
      target_session.is_initial_loading = false;
      target_session.is_initial_request_active = false;
      target_session.has_more = items.isNotEmpty;
    });
  }

  /// 加载更多数据。
  ///
  /// 当滚动到底部时由父组件调用，加载下一页数据并追加到列表。
  Future<void> load_more() async {
    final RecommendWaterfallSession target_session = _session;
    if (target_session.is_initial_loading ||
        target_session.is_loading_more ||
        !target_session.has_more) {
      return;
    }
    final int generation = target_session.request_generation;
    final int revision = LanguageChangeHandler.current_revision;

    _update_target_session(target_session, () {
      target_session.is_loading_more = true;
    });

    // 收集已加载的小说 ID 作为排除参数。
    final List<int> no_ids = target_session.items
        .where((BookListItem item) => item.is_book)
        .map((BookListItem item) => item.story_id)
        .toList();

    final List<BookListItem> new_items = await _fetch_recommend_list(
      no_ids: no_ids,
    );

    if (generation != target_session.request_generation ||
        !LanguageChangeHandler.is_current_revision(revision)) {
      return;
    }

    final List<BookListItem> unique_new_items =
        RecommendBookCardLogic.exclude_duplicate_items(
          candidates: new_items,
          existing_items: target_session.items,
        );

    _update_target_session(target_session, () {
      if (unique_new_items.isNotEmpty) {
        // 每一次成功分页都在本批数据中间创建新槽位和新 NativeAd，
        // 不复用首屏或上一页的广告对象。
        target_session.items.addAll(
          _insert_fresh_ad_in_batch_middle(
            unique_new_items,
            target_session: target_session,
          ),
        );
      }
      target_session.has_more = unique_new_items.isNotEmpty;
      target_session.is_loading_more = false;
    });
  }

  /// 在本批小说的中间插入一个实例内唯一的原生广告槽位。
  ///
  /// 槽位刚创建时高度为 0，不会因等待后端配置、UMP 或 AdMob
  /// 填充而留下空白占位。广告加载完成后由测量组件驱动重排。
  List<BookListItem> _insert_fresh_ad_in_batch_middle(
    List<BookListItem> batch, {
    required RecommendWaterfallSession target_session,
  }) {
    if (!AdDisplayPolicy.can_show_ads()) {
      return List<BookListItem>.of(batch);
    }
    final String slot_id = target_session.create_ad_slot_id();
    target_session.item_heights[slot_id] = 0;
    return RecommendBookCardLogic.insert_ad_in_batch_middle(
      batch: batch,
      ad_slot: BookListItem.ad_slot(id: slot_id),
    );
  }

  /// 请求推荐榜小说列表并映射为 BookListItem。
  ///
  /// [no_ids] - 已加载的小说 ID，用于排除已展示的数据。
  Future<List<BookListItem>> _fetch_recommend_list({List<int>? no_ids}) async {
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

      return RecommendBookCardLogic.exclude_duplicate_items(
        candidates: _map_to_book_list_items(results.content!),
      );
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
            final Color color =
                _tag_color_pool[(item.id * 7 + entry.key * 3) %
                    _tag_color_pool.length];
            return BookListTagItem(label: entry.value, color: color);
          })
          .toList();

      // 封面左下角附加信息：评分或热度。
      String meta_text = '';
      if (item.score > 0) {
        meta_text = easy.tr(
          'home.book_rating',
          namedArgs: <String, String>{'rating': item.score.toStringAsFixed(1)},
        );
      }

      return BookListItem(
        id: 'recommend_${item.id}',
        story_id: item.id,
        type: BookListItemType.book,
        title: item.title,
        description: item.introduction,
        cover_url: item.cover_url,
        cover_badge: item.publish_status == 2
            ? easy.tr('bookshelf.tags.completed')
            : '',
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
    _update_session(() {
      _active_overlay_id = item_id;
    });
    _home_store.is_recommend_overlay_open.value = true;
  }

  /// 关闭当前弹窗。
  void close_overlay() {
    if (_active_overlay_id == null) return;
    _update_session(() {
      _active_overlay_id = null;
    });
    _home_store.is_recommend_overlay_open.value = false;
  }

  /// 删除指定索引的卡片。
  void remove_at(int index) {
    if (index < 0 || index >= _items.length) return;
    if (_removing_ids.contains(_items[index].id)) return;

    final String id = _items[index].id;
    final RecommendWaterfallSession target_session = _session;
    final int generation = target_session.request_generation;

    _update_session(() {
      _removing_ids.add(id);
      // 如果删除的是当前显示弹窗的卡片，关闭弹窗
      if (_active_overlay_id == id) {
        _active_overlay_id = null;
      }
    });

    // 动画完成后移除数据
    Future<void>.delayed(
      Duration(
        milliseconds:
            card_style.RecommendBookCardStyle.delete_animation_duration_ms,
      ),
    ).then((_) {
      if (generation != target_session.request_generation) return;
      target_session.items.removeWhere((BookListItem item) => item.id == id);
      target_session.removing_ids.remove(id);
      target_session.item_heights.remove(id);
      target_session.mark_changed();
    });
  }

  /// 计算每个卡片的位置和尺寸。
  Map<String, Rect> _calculate_layout() {
    if (_total_width == 0) return <String, Rect>{};

    final double column_width =
        (_total_width -
            RecommendBookCardStyle.column_spacing * (_column_count - 1)) /
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

      final double x =
          shortest_column *
          (column_width + RecommendBookCardStyle.column_spacing);
      final double item_height =
          _item_heights[item.id] ??
          card_style.RecommendBookCardStyle.default_card_height;
      final double effective_height = is_removing ? 0 : item_height;

      positions[item.id] = Rect.fromLTWH(
        x,
        column_heights[shortest_column],
        column_width,
        effective_height,
      );

      if (!is_removing && item_height > 0) {
        column_heights[shortest_column] +=
            item_height + RecommendBookCardStyle.item_spacing;
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
      return RecommendWaterfallSkeleton(is_dark: widget.is_dark);
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
                      milliseconds: card_style
                          .RecommendBookCardStyle
                          .reorder_animation_duration_ms,
                    ),
                    curve: Curves.easeOutCubic,
                    left: rect.left,
                    top: rect.top,
                    width: rect.width,
                    child: AnimatedOpacity(
                      duration: const Duration(
                        milliseconds: card_style
                            .RecommendBookCardStyle
                            .fade_out_animation_duration_ms,
                      ),
                      opacity: is_removing ? 0.0 : 1.0,
                      curve: Curves.easeOut,
                      child: _MeasurableWidget(
                        on_height_measured: (double height) {
                          if (_item_heights[item.id] != height && mounted) {
                            _update_session(() {
                              _item_heights[item.id] = height;
                            });
                          }
                        },
                        child: item.is_ad
                            ? MasonryNativeAdCard(
                                slot_id: item.id,
                                is_dark: widget.is_dark,
                              )
                            : RecommendBookCard(
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
              is_loading: _is_loading_more,
              has_more: _has_more,
              on_load_more: load_more,
            ),
          ],
        );
      },
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
      child: SizeChangedLayoutNotifier(child: widget.child),
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
