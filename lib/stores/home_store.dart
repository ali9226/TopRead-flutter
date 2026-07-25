import 'dart:async';
import 'package:get/get.dart';
import 'package:app/models/home_classification.dart';
import 'package:app/models/popular_search_item.dart';
import 'package:app/models/recommend_ranking_item.dart';
import 'package:app/models/short_story_item.dart';
import 'package:app/util/language_util/language_change_handler.dart';
import 'package:app/util/storage_util/index.dart';

/// 首页全局数据仓库。
///
/// 负责存储首页分类列表和榜单分类列表，
/// 支持本地缓存以加速冷启动。
class HomeBannerStore extends GetxController {
  /// 首页分类数据本地缓存键。
  static const String _classification_cache_key = 'home_classification_cache';

  /// 榜单分类数据本地缓存键。
  static const String _rankings_cache_key = 'home_rankings_cache';

  /// 推荐榜小说数据本地缓存键。
  static const String _recommend_ranking_cache_key =
      'home_recommend_ranking_cache';

  /// 搜索栏关键词数据本地缓存键。
  static const String _search_list_cache_key = 'home_search_list_cache';

  /// 搜索栏关键词轮播间隔（毫秒）。
  static const int _cycle_interval_ms = 3000;

  /// 首页分类列表。
  final RxList<HomeClassification> home_classification_list =
      <HomeClassification>[].obs;

  /// 榜单分类列表。
  final RxList<HomeClassification> rankings_list = <HomeClassification>[].obs;

  /// 推荐榜小说列表。
  ///
  /// 来自后端 `novel/recommend_ranking` 接口，
  /// 用于首页推荐 Tab 的榜单区域展示。
  final RxList<RecommendRankingItem> recommend_ranking_list =
      <RecommendRankingItem>[].obs;

  /// 完结榜小说列表（id=149）。
  ///
  /// 来自后端 `novel/completed_ranking` 接口，
  /// 只包含已完结的小说。
  final RxList<RecommendRankingItem> completed_ranking_list =
      <RecommendRankingItem>[].obs;

  /// 巅峰榜小说列表（id=150）。
  ///
  /// 来自后端 `novel/peak_ranking` 接口，
  /// 优先展示评分较高的小说。
  final RxList<RecommendRankingItem> peak_ranking_list =
      <RecommendRankingItem>[].obs;

  /// 新书榜小说列表（id=151）。
  ///
  /// 来自后端 `novel/new_book_ranking` 接口，
  /// 优先展示最近发布的小说。
  final RxList<RecommendRankingItem> new_book_ranking_list =
      <RecommendRankingItem>[].obs;

  /// 搜索栏轮播关键词列表。
  final RxList<HomeClassification> search_list = <HomeClassification>[].obs;

  /// 当前搜索栏轮播关键词索引。
  final RxInt _search_hint_index = 0.obs;

  /// 搜索栏轮播定时器。
  Timer? _search_cycle_timer;

  /// 今日推荐卡片弹窗是否打开。
  ///
  /// 当有上下滑动等滚动事件时，监听此变量并关闭弹窗。
  final RxBool is_recommend_overlay_open = false.obs;

  /// 首页 Tab 栏当前选中的索引。
  ///
  /// 用于在页面重建时恢复用户上次所在的 Tab 位置，
  /// 避免导航返回后 Tab 重置到第一个。
  int home_tab_index = 0;

  /// 是否正在加载/刷新数据（用于展示骨架屏）。
  /// 仅在已有缓存数据后的刷新期间为 true，首次加载有缓存时为 false。
  final RxBool is_loading = false.obs;

  /// 是否已有本地缓存数据（用于区分首次加载和语种切换刷新）。
  bool _has_cached_data = false;

  /// 是否已有本地缓存数据。
  bool get has_cached_data => _has_cached_data;

  /// 当前语种对应的缓存键。
  String _language_cache_key(String base_key) {
    return '${base_key}_${LanguageChangeHandler.current_language_code}';
  }

  /// 短篇小说列表数据。
  final RxList<ShortStoryItem> short_story_list = <ShortStoryItem>[].obs;

  /// 短篇小说是否正在加载中（用于骨架屏）。
  final RxBool short_story_loading = false.obs;

  /// 不喜欢理由列表。
  final RxList<HomeClassification> dislike_list = <HomeClassification>[].obs;

  /// 热门搜索标签列表。
  final RxList<PopularSearchItem> popular_searches = <PopularSearchItem>[].obs;

  /// 当前搜索栏轮播提示文字。
  ///
  /// 如果 [search_list] 为空则返回空字符串，
  /// 由调用方自行决定使用默认占位文案。
  String get current_search_hint {
    if (search_list.isEmpty) return '';
    return search_list[_search_hint_index.value % search_list.length].title;
  }

  @override
  void onInit() {
    super.onInit();
    _load_cached_classification_list();
    _load_cached_rankings_list();
    _load_cached_recommend_ranking_list();
    _load_cached_search_list();
  }

  @override
  void onClose() {
    _search_cycle_timer?.cancel();
    super.onClose();
  }

  /// 保存首页分类列表。
  ///
  /// 参数 [data]：
  /// 接口返回的首页分类列表。
  void save_home_classification_list(List<HomeClassification> data) {
    home_classification_list.assignAll(data);
    _has_cached_data = data.isNotEmpty;
    is_loading.value = false;
    _save_classification_list_to_cache(data);
  }

  /// 保存榜单分类列表。
  ///
  /// 参数 [data]：
  /// 接口返回的榜单分类列表。
  void save_rankings_list(List<HomeClassification> data) {
    rankings_list.assignAll(data);
    _save_rankings_list_to_cache(data);
  }

  /// 保存推荐榜小说列表。
  ///
  /// 参数 [data]：
  /// 后端 `novel/recommend_ranking` 接口返回的小说列表。
  void save_recommend_ranking_list(List<RecommendRankingItem> data) {
    recommend_ranking_list.assignAll(data);
    _save_recommend_ranking_list_to_cache(data);
  }

  /// 保存完结榜小说列表。
  ///
  /// 参数 [data]：
  /// 后端 `novel/completed_ranking` 接口返回的小说列表。
  void save_completed_ranking_list(List<RecommendRankingItem> data) {
    completed_ranking_list.assignAll(data);
  }

  /// 保存巅峰榜小说列表。
  ///
  /// 参数 [data]：
  /// 后端 `novel/peak_ranking` 接口返回的小说列表。
  void save_peak_ranking_list(List<RecommendRankingItem> data) {
    peak_ranking_list.assignAll(data);
  }

  /// 保存新书榜小说列表。
  ///
  /// 参数 [data]：
  /// 后端 `novel/new_book_ranking` 接口返回的小说列表。
  void save_new_book_ranking_list(List<RecommendRankingItem> data) {
    new_book_ranking_list.assignAll(data);
  }

  /// 保存搜索栏轮播关键词列表。
  ///
  /// 参数 [data]：
  /// 接口返回的搜索栏关键词列表。
  void save_search_list(List<HomeClassification> data) {
    search_list.assignAll(data);
    _search_hint_index.value = 0;
    _save_search_list_to_cache(data);
    _restart_search_cycle_timer();
  }

  /// 保存不喜欢理由列表。
  ///
  /// 参数 [data]：
  /// 接口返回的不喜欢理由列表。
  void save_dislike_list(List<HomeClassification> data) {
    dislike_list.assignAll(data);
  }

  /// 保存热门搜索标签列表。
  ///
  /// 参数 [data]：
  /// 接口返回的热门搜索标签列表。
  void save_popular_searches(List<PopularSearchItem> data) {
    popular_searches.assignAll(data);
  }

  /// 清空所有榜单数据。
  ///
  /// 语种切换时调用，确保下次请求使用新语种获取数据。
  void clear_all_ranking_data() {
    recommend_ranking_list.clear();
    completed_ranking_list.clear();
    peak_ranking_list.clear();
    new_book_ranking_list.clear();
    short_story_list.clear();
  }

  /// 进入语种切换刷新态。
  ///
  /// 旧语种数据必须在 Locale 切换前统一失效，避免新旧语种同屏。
  void begin_language_refresh() {
    is_loading.value = true;
    _has_cached_data = false;
    home_classification_list.clear();
    rankings_list.clear();
    clear_all_ranking_data();
    search_list.clear();
    dislike_list.clear();
    popular_searches.clear();
    _search_hint_index.value = 0;
    _search_cycle_timer?.cancel();
  }

  /// 完成语种配置刷新。
  void finish_language_refresh() {
    is_loading.value = false;
  }

  /// 启动搜索栏关键词轮播定时器。
  void _restart_search_cycle_timer() {
    _search_cycle_timer?.cancel();
    if (search_list.length <= 1) return;
    _search_cycle_timer = Timer.periodic(
      const Duration(milliseconds: _cycle_interval_ms),
      (_) {
        _search_hint_index.value =
            (_search_hint_index.value + 1) % search_list.length;
      },
    );
  }

  /// 从本地缓存加载首页分类列表。
  ///
  /// 应用启动时调用，优先展示缓存数据，
  /// 后续接口数据到达后会覆盖缓存。
  Future<void> _load_cached_classification_list() async {
    try {
      final List<dynamic>? cached_list = StorageUtil.getList(
        _language_cache_key(_classification_cache_key),
      );
      if (cached_list != null && cached_list.isNotEmpty) {
        final List<HomeClassification> classification_list =
            HomeClassification.from_cache_list(cached_list);
        if (classification_list.isNotEmpty) {
          home_classification_list.assignAll(classification_list);
          _has_cached_data = true;
        }
      }
    } catch (_) {
      // 缓存读取失败时静默忽略，不影响正常流程。
    }
  }

  /// 将首页分类列表保存到本地缓存。
  void _save_classification_list_to_cache(List<HomeClassification> data) {
    try {
      final List<Map<String, dynamic>> json_list = data
          .map((item) => item.to_json())
          .toList();
      StorageUtil.saveList(
        _language_cache_key(_classification_cache_key),
        json_list,
      );
    } catch (_) {
      // 缓存写入失败时静默忽略。
    }
  }

  /// 从本地缓存加载榜单分类列表。
  ///
  /// 应用启动时调用，优先展示缓存数据，
  /// 后续接口数据到达后会覆盖缓存。
  Future<void> _load_cached_rankings_list() async {
    try {
      final List<dynamic>? cached_list = StorageUtil.getList(
        _language_cache_key(_rankings_cache_key),
      );
      if (cached_list != null && cached_list.isNotEmpty) {
        final List<HomeClassification> rankings =
            HomeClassification.from_cache_list(cached_list);
        if (rankings.isNotEmpty) {
          rankings_list.assignAll(rankings);
        }
      }
    } catch (_) {
      // 缓存读取失败时静默忽略，不影响正常流程。
    }
  }

  /// 将榜单分类列表保存到本地缓存。
  void _save_rankings_list_to_cache(List<HomeClassification> data) {
    try {
      final List<Map<String, dynamic>> json_list = data
          .map((item) => item.to_json())
          .toList();
      StorageUtil.saveList(_language_cache_key(_rankings_cache_key), json_list);
    } catch (_) {
      // 缓存写入失败时静默忽略。
    }
  }

  /// 从本地缓存加载推荐榜小说列表。
  ///
  /// 应用启动时调用，优先展示缓存数据，
  /// 后续接口数据到达后会覆盖缓存。
  Future<void> _load_cached_recommend_ranking_list() async {
    try {
      final List<dynamic>? cached_list = StorageUtil.getList(
        _language_cache_key(_recommend_ranking_cache_key),
      );
      if (cached_list != null && cached_list.isNotEmpty) {
        final List<RecommendRankingItem> list =
            RecommendRankingItem.from_cache_list(cached_list);
        if (list.isNotEmpty) {
          recommend_ranking_list.assignAll(list);
        }
      }
    } catch (_) {
      // 缓存读取失败时静默忽略，不影响正常流程。
    }
  }

  /// 将推荐榜小说列表保存到本地缓存。
  void _save_recommend_ranking_list_to_cache(List<RecommendRankingItem> data) {
    try {
      final List<Map<String, dynamic>> json_list = data
          .map((item) => item.to_json())
          .toList();
      StorageUtil.saveList(
        _language_cache_key(_recommend_ranking_cache_key),
        json_list,
      );
    } catch (_) {
      // 缓存写入失败时静默忽略。
    }
  }

  /// 从本地缓存加载搜索栏关键词列表。
  ///
  /// 应用启动时调用，优先展示缓存数据，
  /// 后续接口数据到达后会覆盖缓存。
  Future<void> _load_cached_search_list() async {
    try {
      final List<dynamic>? cached_list = StorageUtil.getList(
        _language_cache_key(_search_list_cache_key),
      );
      if (cached_list != null && cached_list.isNotEmpty) {
        final List<HomeClassification> list =
            HomeClassification.from_cache_list(cached_list);
        if (list.isNotEmpty) {
          search_list.assignAll(list);
          _restart_search_cycle_timer();
        }
      }
    } catch (_) {
      // 缓存读取失败时静默忽略，不影响正常流程。
    }
  }

  /// 将搜索栏关键词列表保存到本地缓存。
  void _save_search_list_to_cache(List<HomeClassification> data) {
    try {
      final List<Map<String, dynamic>> json_list = data
          .map((item) => item.to_json())
          .toList();
      StorageUtil.saveList(
        _language_cache_key(_search_list_cache_key),
        json_list,
      );
    } catch (_) {
      // 缓存写入失败时静默忽略。
    }
  }
}
