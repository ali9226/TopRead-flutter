import 'package:get/get.dart';
import 'package:app/models/recommend_ranking_item.dart';

/// 完整榜单页面缓存仓库。
///
/// 负责管理每个榜单Tab的缓存数据，包括：
/// - 每个Tab的选中分类状态
/// - 每个Tab每个分类的已加载数据
/// - 每个Tab每个分类的分页状态
///
/// 使用方式：
/// ```dart
/// final store = Get.find<RankingFullListStore>();
/// store.get_or_create_tab_state(ranking_tab_id);
/// ```
class RankingFullListStore extends GetxController {
  /// 单例实例。
  static RankingFullListStore get instance => Get.find<RankingFullListStore>();

  /// 每个Tab的状态缓存，key为ranking_tab_id。
  final Map<int, RankingTabState> _tab_states = <int, RankingTabState>{};

  /// 获取或创建指定Tab的状态。
  ///
  /// 如果Tab状态不存在则创建一个新的。
  RankingTabState get_or_create_tab_state(int ranking_tab_id) {
    return _tab_states.putIfAbsent(ranking_tab_id, () => RankingTabState());
  }

  /// 获取指定Tab的选中分类id。
  int? get_selected_category_id(int ranking_tab_id) {
    return _tab_states[ranking_tab_id]?.selected_category_id;
  }

  /// 设置指定Tab的选中分类id。
  void set_selected_category_id(int ranking_tab_id, int? category_id) {
    final RankingTabState? state = _tab_states[ranking_tab_id];
    if (state != null) {
      state.selected_category_id = category_id;
    }
  }

  /// 获取指定Tab指定分类的缓存数据。
  ///
  /// 如果缓存不存在返回null。
  RankingCategoryCache? get_category_cache(int ranking_tab_id, int? category_id) {
    final RankingTabState? state = _tab_states[ranking_tab_id];
    if (state == null) return null;
    return state.get_category_cache(category_id);
  }

  /// 设置指定Tab指定分类的缓存数据。
  void set_category_cache(
    int ranking_tab_id,
    int? category_id, {
    required List<RecommendRankingItem> items,
    required bool has_more,
  }) {
    final RankingTabState state = get_or_create_tab_state(ranking_tab_id);
    state.set_category_cache(
      category_id,
      items: items,
      has_more: has_more,
    );
  }

  /// 追加指定Tab指定分类的数据。
  void append_category_cache(
    int ranking_tab_id,
    int? category_id, {
    required List<RecommendRankingItem> new_items,
    required bool has_more,
  }) {
    final RankingTabState state = get_or_create_tab_state(ranking_tab_id);
    state.append_category_cache(
      category_id,
      new_items: new_items,
      has_more: has_more,
    );
  }

  /// 清除指定Tab的缓存。
  void clear_tab(int ranking_tab_id) {
    _tab_states.remove(ranking_tab_id);
  }

  /// 清除所有缓存。
  void clear_all() {
    _tab_states.clear();
  }
}

/// 单个Tab的状态。
class RankingTabState {
  /// 当前选中的分类id（null表示未筛选）。
  int? selected_category_id;

  /// 每个分类的缓存数据，key为category_id（null表示未筛选分类）。
  final Map<int?, RankingCategoryCache> _category_caches = <int?, RankingCategoryCache>{};

  /// 获取指定分类的缓存。
  RankingCategoryCache? get_category_cache(int? category_id) {
    return _category_caches[category_id];
  }

  /// 设置指定分类的缓存。
  void set_category_cache(
    int? category_id, {
    required List<RecommendRankingItem> items,
    required bool has_more,
  }) {
    _category_caches[category_id] = RankingCategoryCache(
      items: items,
      has_more: has_more,
    );
  }

  /// 追加指定分类的数据。
  void append_category_cache(
    int? category_id, {
    required List<RecommendRankingItem> new_items,
    required bool has_more,
  }) {
    final RankingCategoryCache? existing = _category_caches[category_id];
    if (existing != null) {
      existing.items.addAll(new_items);
      existing.has_more = has_more;
    } else {
      set_category_cache(
        category_id,
        items: new_items,
        has_more: has_more,
      );
    }
  }
}

/// 单个分类的缓存数据。
class RankingCategoryCache {
  /// 已加载的数据列表。
  final List<RecommendRankingItem> items;

  /// 是否还有更多数据可加载。
  bool has_more;

  RankingCategoryCache({
    required this.items,
    required this.has_more,
  });
}
