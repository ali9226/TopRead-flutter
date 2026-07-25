import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/api/post_request.dart';
import 'package:app/components/fixed_bottom_navigation/style.dart'
    as fixed_nav_style;
import 'package:app/components/floating_back_to_top/index.dart';
import 'package:app/components/floating_back_to_top/style.dart'
    as floating_back_to_top_style;
import 'package:app/components/recommend_book_card/animated_waterfall.dart';
import 'package:app/models/recommend_ranking_item.dart';
import 'package:app/models/short_story_item.dart';
import 'package:app/models/story_item.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/home_store.dart';
import 'package:app/util/language_util/language_change_handler.dart';
import 'package:app/util/router/router_util.dart';
import 'package:app/pages/home/widgets/tab_contents/recommend_tab/widgets/ranking_section/style.dart';
import 'package:app/pages/home/widgets/tab_contents/recommend_tab/style.dart';
import 'package:app/pages/home/widgets/tab_contents/recommend_tab/widgets/ranking_section/index.dart';

/// 推荐 Tab 内容组件。
///
/// 包含两个主要区域：
/// 1. 榜单区域 - 展示各类书籍榜单，支持横向滚动和分类切换
/// 2. 今日推荐 - 展示推荐书籍瀑布流列表
///
/// 榜单区域根据当前选中的 Tab id 懒加载不同接口：
/// - id=148（推荐榜）→ `novel/recommend_ranking`
/// - id=149（完结榜）→ `novel/completed_ranking`
/// - id=150（巅峰榜）→ `novel/peak_ranking`
/// - id=151（新书榜）→ `novel/new_book_ranking`
/// - id=157（短篇榜）→ `novel/short_story`
///
/// 数据仅在用户切换到对应 Tab 时才发起请求（懒加载），
/// 下拉刷新仅更新当前选中 Tab 的数据。
class RecommendTabContent extends StatefulWidget {
  const RecommendTabContent({super.key});

  @override
  State<RecommendTabContent> createState() => _RecommendTabContentState();
}

class _RecommendTabContentState extends State<RecommendTabContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // ==================== Tab ID 常量 ====================

  /// 推荐榜 Tab 的固定 id。
  static const int _recommend_ranking_id = 148;

  /// 完结榜 Tab 的固定 id。
  static const int _completed_ranking_id = 149;

  /// 巅峰榜 Tab 的固定 id。
  static const int _peak_ranking_id = 150;

  /// 新书榜 Tab 的固定 id。
  static const int _new_book_ranking_id = 151;

  /// 短篇榜 Tab 的固定 id。
  static const int _short_story_ranking_id = 157;

  /// 榜单区域固定高度（Tab 栏 + 内容区 + 查看更多按钮 + 底部间距）。
  ///
  /// 切换 Tab 时骨架屏和真实内容高度必须一致，
  /// 否则高度变化会导致下方内容被顶上去产生闪烁。
  static const double _ranking_section_fixed_height =
      RankingSectionStyle.tab_bar_height +
      RankingSectionStyle.rows_per_column * RankingSectionStyle.item_height +
      (RankingSectionStyle.rows_per_column - 1) * RankingSectionStyle.row_gap +
      5 + // RankingContent 内部额外间距
      RankingSectionStyle.view_more_top_spacing +
      22 + // "查看更多"按钮高度（文字 + 图标 + 下划线）
      RankingSectionStyle.view_more_bottom_spacing +
      RankingSectionStyle.ranking_bottom_spacing;

  // ==================== 状态 ====================

  /// 滚动控制器，用于监听滚动事件和返回顶部。
  final ScrollController _scroll_controller = ScrollController();

  /// 返回顶部按钮是否可见。
  bool _is_back_to_top_visible = false;

  /// 今日推荐瀑布流组件的 GlobalKey。
  final GlobalKey<AnimatedRecommendWaterfallState> _recommend_waterfall_key =
      GlobalKey();

  /// 首页数据仓库。
  final HomeBannerStore _home_store = Get.find<HomeBannerStore>();

  /// 当前选中的榜单 Tab 索引（响应式，驱动 Obx 局部刷新）。
  final RxInt _selected_ranking_tab_index = 0.obs;

  /// 已加载过的 Tab id 集合（懒加载标记）。
  ///
  /// 避免重复请求同一个 Tab 的数据。
  final Set<int> _loaded_tab_ids = <int>{};

  /// 各 Tab 独立的加载状态（用于骨架屏）。
  final RxMap<int, bool> _loading_tab_ids = <int, bool>{}.obs;

  /// 语种刷新任务订阅。
  late final LanguageRefreshSubscription _language_refresh_subscription;

  /// 切换语种前选中的榜单 id。
  int _retained_ranking_tab_id = 0;

  @override
  void initState() {
    super.initState();
    _scroll_controller.addListener(_handle_scroll);
    _language_refresh_subscription =
        LanguageChangeHandler.register_refresh_task(
          phase: LanguageRefreshPhase.content,
          on_prepare: _prepare_language_refresh,
          on_refresh: _refresh_for_language,
        );

    // 首次加载时，标记已在启动阶段获取过的 Tab 为已加载。
    if (_home_store.recommend_ranking_list.isNotEmpty) {
      _loaded_tab_ids.add(_recommend_ranking_id);
    }
    if (_home_store.short_story_list.isNotEmpty) {
      _loaded_tab_ids.add(_short_story_ranking_id);
    }

    // 首次进入时触发当前 Tab 的数据加载。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensure_tab_loaded(_current_tab_id);
    });
  }

  @override
  void dispose() {
    _language_refresh_subscription.dispose();
    _scroll_controller.removeListener(_handle_scroll);
    _scroll_controller.dispose();
    super.dispose();
  }

  /// Locale 切换前保存当前榜单选择并让旧请求失效。
  void _prepare_language_refresh(LanguageRefreshContext refresh_context) {
    _retained_ranking_tab_id = _current_tab_id;
    _loaded_tab_ids.clear();
    _loading_tab_ids.clear();
  }

  /// 基础分类刷新完成后，恢复同一榜单并请求新语种内容。
  Future<void> _refresh_for_language(
    LanguageRefreshContext refresh_context,
  ) async {
    if (!mounted || !refresh_context.is_current) return;

    final List<int> tab_ids = rankings_id_list;
    if (tab_ids.isEmpty) return;

    final int retained_index = tab_ids.indexOf(_retained_ranking_tab_id);
    _selected_ranking_tab_index.value = retained_index >= 0
        ? retained_index
        : 0;
    await _fetch_ranking_for_tab(
      _current_tab_id,
      request_revision: refresh_context.revision,
    );
  }

  // ==================== 滚动处理 ====================

  /// 距离底部多少像素时触发自动加载更多。
  static const double _load_more_trigger_distance = 300;

  /// 处理滚动事件：控制返回顶部按钮显隐、关闭推荐弹窗、触发加载更多。
  void _handle_scroll() {
    final bool should_show_back_to_top =
        _scroll_controller.hasClients &&
        _scroll_controller.offset >
            RecommendTabStyle.back_to_top_visible_offset;

    if (_is_back_to_top_visible != should_show_back_to_top) {
      setState(() {
        _is_back_to_top_visible = should_show_back_to_top;
      });
    }

    if (_home_store.is_recommend_overlay_open.value) {
      _recommend_waterfall_key.currentState?.close_overlay();
    }

    if (_scroll_controller.position.pixels >=
        _scroll_controller.position.maxScrollExtent -
            _load_more_trigger_distance) {
      _recommend_waterfall_key.currentState?.load_more();
    }
  }

  /// 平滑滚动到顶部。
  void _scroll_to_top() {
    if (!_scroll_controller.hasClients) return;

    _scroll_controller.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  // ==================== 下拉刷新 ====================

  /// 下拉刷新当前选中 Tab 的数据。
  ///
  /// 清除该 Tab 的已加载标记后重新请求。
  Future<void> _on_refresh() async {
    final int tab_id = _current_tab_id;
    _loaded_tab_ids.remove(tab_id);
    await _fetch_ranking_for_tab(tab_id);
  }

  // ==================== Tab 相关 ====================

  /// 获取榜单 Tab 标题列表（从 store 的 rankings_list 获取）。
  List<String> get rankings_title_list {
    try {
      final HomeBannerStore store = Get.find<HomeBannerStore>();
      if (store.rankings_list.isNotEmpty) {
        return store.rankings_list.map((e) => e.title).toList();
      }
    } catch (_) {}
    return <String>[];
  }

  /// 获取榜单 Tab id 列表（从 store 的 rankings_list 获取）。
  List<int> get rankings_id_list {
    try {
      final HomeBannerStore store = Get.find<HomeBannerStore>();
      if (store.rankings_list.isNotEmpty) {
        return store.rankings_list.map((e) => e.id).toList();
      }
    } catch (_) {}
    return <int>[];
  }

  /// 榜单分类列表是否已加载。
  bool get _is_rankings_loading {
    try {
      return _home_store.rankings_list.isEmpty;
    } catch (_) {
      return true;
    }
  }

  /// 获取当前选中 Tab 的 id。
  int get _current_tab_id {
    final List<int> ids = rankings_id_list;
    if (ids.isEmpty || _selected_ranking_tab_index.value >= ids.length)
      return 0;
    return ids[_selected_ranking_tab_index.value];
  }

  /// 指定 Tab 的数据是否已就绪。
  bool _is_tab_data_ready(int tab_id) {
    switch (tab_id) {
      case _recommend_ranking_id:
        return _home_store.recommend_ranking_list.isNotEmpty;
      case _completed_ranking_id:
        return _home_store.completed_ranking_list.isNotEmpty;
      case _peak_ranking_id:
        return _home_store.peak_ranking_list.isNotEmpty;
      case _new_book_ranking_id:
        return _home_store.new_book_ranking_list.isNotEmpty;
      case _short_story_ranking_id:
        return _home_store.short_story_list.isNotEmpty;
      default:
        return _home_store.recommend_ranking_list.isNotEmpty;
    }
  }

  /// 榜单 Tab 切换回调。
  ///
  /// 切换后触发新 Tab 的懒加载。
  void _on_ranking_tab_changed(int index) {
    if (_selected_ranking_tab_index.value == index) return;
    _selected_ranking_tab_index.value = index;
    _ensure_tab_loaded(_current_tab_id);
  }

  /// 确保指定 Tab 的数据已加载（懒加载）。
  ///
  /// 如果该 Tab 已加载过，直接跳过；否则发起请求。
  Future<void> _ensure_tab_loaded(int tab_id) async {
    if (tab_id == 0) return;
    if (_loaded_tab_ids.contains(tab_id)) return;
    await _fetch_ranking_for_tab(tab_id);
  }

  // ==================== 数据请求 ====================

  /// 根据 Tab id 请求对应的榜单数据。
  ///
  /// 请求完成后将数据保存到 HomeBannerStore，
  /// 并标记该 Tab 为已加载。
  Future<void> _fetch_ranking_for_tab(
    int tab_id, {
    int? request_revision,
  }) async {
    if (tab_id == 0 || _loading_tab_ids[tab_id] == true) return;
    final int revision =
        request_revision ?? LanguageChangeHandler.current_revision;

    // 设置该 Tab 的加载状态（响应式，驱动 Obx 局部刷新）。
    _loading_tab_ids[tab_id] = true;

    bool success = false;
    try {
      switch (tab_id) {
        case _recommend_ranking_id:
          success = await _fetch_recommend_ranking(revision);
          break;
        case _completed_ranking_id:
          success = await _fetch_completed_ranking(revision);
          break;
        case _peak_ranking_id:
          success = await _fetch_peak_ranking(revision);
          break;
        case _new_book_ranking_id:
          success = await _fetch_new_book_ranking(revision);
          break;
        case _short_story_ranking_id:
          success = await _fetch_short_story_ranking(revision);
          break;
      }
    } finally {
      if (mounted && LanguageChangeHandler.is_current_revision(revision)) {
        _loading_tab_ids[tab_id] = false;
        if (success) {
          _loaded_tab_ids.add(tab_id);
        }
      }
    }
  }

  /// 请求推荐榜数据。
  Future<bool> _fetch_recommend_ranking(int revision) async {
    final results = await postRequest<List<RecommendRankingItem>>(
      path: 'novel/recommend_ranking',
      showTips: false,
      fromJsonList: (List<dynamic> json) =>
          RecommendRankingItem.from_json_list(json),
    );
    if (results.status &&
        results.content != null &&
        LanguageChangeHandler.is_current_revision(revision)) {
      _home_store.save_recommend_ranking_list(results.content!);
      return true;
    }
    return false;
  }

  /// 请求完结榜数据。
  Future<bool> _fetch_completed_ranking(int revision) async {
    final results = await postRequest<List<RecommendRankingItem>>(
      path: 'novel/completed_ranking',
      showTips: false,
      fromJsonList: (List<dynamic> json) =>
          RecommendRankingItem.from_json_list(json),
    );
    if (results.status &&
        results.content != null &&
        LanguageChangeHandler.is_current_revision(revision)) {
      _home_store.save_completed_ranking_list(results.content!);
      return true;
    }
    return false;
  }

  /// 请求巅峰榜数据。
  Future<bool> _fetch_peak_ranking(int revision) async {
    final results = await postRequest<List<RecommendRankingItem>>(
      path: 'novel/peak_ranking',
      showTips: false,
      fromJsonList: (List<dynamic> json) =>
          RecommendRankingItem.from_json_list(json),
    );
    if (results.status &&
        results.content != null &&
        LanguageChangeHandler.is_current_revision(revision)) {
      _home_store.save_peak_ranking_list(results.content!);
      return true;
    }
    return false;
  }

  /// 请求新书榜数据。
  Future<bool> _fetch_new_book_ranking(int revision) async {
    final results = await postRequest<List<RecommendRankingItem>>(
      path: 'novel/new_book_ranking',
      showTips: false,
      fromJsonList: (List<dynamic> json) =>
          RecommendRankingItem.from_json_list(json),
    );
    if (results.status &&
        results.content != null &&
        LanguageChangeHandler.is_current_revision(revision)) {
      _home_store.save_new_book_ranking_list(results.content!);
      return true;
    }
    return false;
  }

  /// 请求短篇榜数据。
  Future<bool> _fetch_short_story_ranking(int revision) async {
    final results = await postRequest<List<ShortStoryItem>>(
      path: 'novel/short_story',
      showTips: false,
      fromJsonList: (List<dynamic> json) => ShortStoryItem.from_json_list(json),
    );
    if (results.status &&
        results.content != null &&
        LanguageChangeHandler.is_current_revision(revision)) {
      _home_store.short_story_list.assignAll(results.content!);
      return true;
    }
    return false;
  }

  // ==================== 数据映射 ====================

  /// 根据当前选中的 Tab id 构建榜单数据。
  ///
  /// 不同 Tab id 对应不同数据源，返回的列表结构与 [RankingSection.all_ranking_data] 一致。
  List<List<StoryItem>> _build_ranking_data_from_store() {
    final List<int> tab_ids = rankings_id_list;
    if (tab_ids.isEmpty) return <List<StoryItem>>[];

    return List<List<StoryItem>>.generate(tab_ids.length, (int index) {
      final int tab_id = tab_ids[index];

      switch (tab_id) {
        case _completed_ranking_id:
          return _map_recommend_ranking_to_story_item(
            _home_store.completed_ranking_list,
          );
        case _peak_ranking_id:
          return _map_recommend_ranking_to_story_item(
            _home_store.peak_ranking_list,
          );
        case _new_book_ranking_id:
          return _map_recommend_ranking_to_story_item(
            _home_store.new_book_ranking_list,
          );
        case _short_story_ranking_id:
          return _map_short_story_to_story_item(_home_store.short_story_list);
        case _recommend_ranking_id:
        default:
          return _map_recommend_ranking_to_story_item(
            _home_store.recommend_ranking_list,
          );
      }
    });
  }

  /// 将推荐榜类小说数据映射为 StoryItem 列表。
  List<StoryItem> _map_recommend_ranking_to_story_item(
    List<RecommendRankingItem> source,
  ) {
    if (source.isEmpty) return <StoryItem>[];
    final String language_code = Localizations.localeOf(context).languageCode;
    return source
        .map(
          (RecommendRankingItem item) => StoryItem(
            id: item.id,
            title: item.title,
            introduction: item.introduction,
            cover_url: item.cover_url,
            popularity_count: '',
            category_text: item.formatted_categories,
            heat_text: item.formatted_read_count_for(language_code),
            publish_status: item.publish_status,
          ),
        )
        .toList();
  }

  /// 将短篇小说数据映射为 StoryItem 列表。
  List<StoryItem> _map_short_story_to_story_item(List<ShortStoryItem> source) {
    if (source.isEmpty) return <StoryItem>[];
    return source
        .map(
          (ShortStoryItem item) => StoryItem(
            id: item.id,
            title: item.title,
            introduction: item.description,
            cover_url: '',
            popularity_count: '',
            category_text: item.tags.isNotEmpty ? item.tags.join('·') : '',
            heat_text: _format_short_story_heat(item),
            publish_status: 4,
          ),
        )
        .toList();
  }

  /// 格式化短篇小说的阅读数展示文本（多语种）。
  String _format_short_story_heat(ShortStoryItem item) {
    final String language_code = Localizations.localeOf(context).languageCode;
    return RecommendRankingItem.format_count_text(
      item.read_count,
      language_code,
    );
  }

  // ==================== UI ====================

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 要求调用

    final DeviceInfo device_info = Get.find<DeviceInfo>();

    return Obx(() {
      final bool is_dark = device_info.theme.value == ThemeMode.dark;
      final Color panel_bg = is_dark ? const Color(0xFF171C28) : Colors.white;
      final List<String> ranking_titles = rankings_title_list;
      final List<List<StoryItem>> all_ranking_data =
          _build_ranking_data_from_store();

      // 当前 Tab 是否需要展示骨架屏。
      // 仅在数据完全不存在且正在请求时才展示，
      // 如果 store 中已有数据（即使是上次缓存的），直接展示数据，不闪骨架屏。
      final int current_id = _current_tab_id;
      final bool is_current_loading =
          _is_rankings_loading ||
          (_loading_tab_ids[current_id] == true &&
              !_is_tab_data_ready(current_id));

      return Stack(
        children: <Widget>[
          RefreshIndicator(
            onRefresh: _on_refresh,
            child: ListView(
              controller: _scroll_controller,
              padding: EdgeInsets.zero,
              children: <Widget>[
                // 榜单区域
                Container(
                  margin: RecommendTabStyle.ranking_margin,
                  decoration: BoxDecoration(
                    color: panel_bg,
                    borderRadius: BorderRadius.circular(
                      RecommendTabStyle.ranking_border_radius,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    height: _ranking_section_fixed_height,
                    child: RankingSection(
                      sub_tab_list: ranking_titles,
                      sub_tab_id_list: rankings_id_list,
                      all_ranking_data: all_ranking_data,
                      is_dark: is_dark,
                      panel_bg: panel_bg,
                      language_code: context.locale.languageCode,
                      is_loading: is_current_loading,
                      on_tab_changed: _on_ranking_tab_changed,
                      on_full_ranking_tap: (int tab_id) {
                        routerUtil(
                          path: '/ranking_full_list?id=$tab_id',
                          type: 'push',
                        );
                      },
                      on_reload: _on_refresh,
                    ),
                  ),
                ),
                // 榜单与今日推荐之间的间距
                const SizedBox(height: RecommendTabStyle.recommend_top_spacing),
                // 今日推荐瀑布流区域
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: AnimatedRecommendWaterfall(
                    key: _recommend_waterfall_key,
                    is_dark: is_dark,
                  ),
                ),
                const SizedBox(
                  height: RecommendTabStyle.recommend_bottom_spacing,
                ),
              ],
            ),
          ),
          // 返回顶部按钮
          FloatingBackToTop(
            show: _is_back_to_top_visible,
            isDark: is_dark,
            onTap: _scroll_to_top,
            right: floating_back_to_top_style.FloatingBackToTopStyle.right,
            visibleBottom:
                fixed_nav_style.Style.bar_height +
                floating_back_to_top_style
                    .FloatingBackToTopStyle
                    .offset_from_bottom_nav +
                MediaQuery.paddingOf(context).bottom,
            hiddenBottom:
                fixed_nav_style.Style.bar_height +
                floating_back_to_top_style
                    .FloatingBackToTopStyle
                    .hidden_offset +
                MediaQuery.paddingOf(context).bottom,
          ),
        ],
      );
    });
  }
}
