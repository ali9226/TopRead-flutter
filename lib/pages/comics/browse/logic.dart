// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/api/comics_discovery.dart';
import 'package:app/models/comics.dart';
import 'package:app/models/comics_discovery.dart';
import 'package:flutter/foundation.dart';

typedef ComicBrowseCategoriesLoader =
    Future<List<Map<String, dynamic>>> Function();
typedef ComicBrowsePageLoader =
    Future<ComicDiscoveryPage> Function({
      required int category_id,
      required int page,
      required int page_size,
      String? seed,
      String? language,
    });

/// 每个真实分类单独保留分页游标、随机种子和失败状态，切回时无需重新请求。
class ComicBrowseCategoryState {
  final List<ComicItem> items = [];
  int page = 0;
  int total = 0;
  String? seed;
  bool loaded = false;
  bool profile_pending = false;
  bool loading = false;
  bool refreshing = false;
  bool loading_more = false;
  String? error;
  bool failed_more = false;
  bool exhausted = false;
  int revision = 0;
  double scroll_offset = 0;
  int snapshot_revision = 0;

  bool get busy => loading || refreshing || loading_more;
  bool get has_more => loaded && !exhausted && items.length < total;
}

/// 分类页的请求生命周期；刷新可以替代旧请求，但分页始终只允许一个在途请求。
class ComicBrowseLogic extends ChangeNotifier {
  ComicBrowseLogic({
    int initial_category_id = 0,
    ComicBrowseCategoriesLoader? categories_loader,
    ComicBrowsePageLoader? page_loader,
  }) : selected_category_id = initial_category_id,
       _categories_loader =
           categories_loader ?? load_comics_discovery_categories,
       _page_loader = page_loader ?? load_comics_discovery_page;

  static const int page_size = 24;
  final ComicBrowseCategoriesLoader _categories_loader;
  final ComicBrowsePageLoader _page_loader;
  final Map<int, ComicBrowseCategoryState> _states = {};
  List<Map<String, dynamic>> categories = [];
  int selected_category_id;
  bool loading_categories = false;
  // TODO 尚未请求不等于分类为空；只有成功返回后才能展示真实空态。
  bool categories_loaded = false;
  String? categories_error;
  String? language;
  int context_revision = 0;
  int _categories_revision = 0;
  bool _disposed = false;
  bool _initialized = false;

  ComicBrowseCategoryState state_for(int category_id) =>
      _states.putIfAbsent(category_id, ComicBrowseCategoryState.new);

  int get selected_index => categories.indexWhere(
    (category) => comics_int(category['id']) == selected_category_id,
  );

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize({String? language}) async {
    if (_initialized || _disposed) return;
    _initialized = true;
    this.language = language;
    // 深链接可直接开始加载指定分类，同时获取横向分类栏。
    if (selected_category_id > 0) {
      unawaited(ensure_loaded(selected_category_id));
    }
    await load_categories();
  }

  /// 身份或语种切换先同步失效旧快照；旧请求捕获的状态对象同样递增版本。
  void prepare_context({String? language}) {
    if (_disposed) return;
    this.language = language ?? this.language;
    context_revision++;
    _categories_revision++;
    for (final state in _states.values) {
      state.revision++;
    }
    _states.clear();
    categories = [];
    categories_error = null;
    loading_categories = false;
    categories_loaded = false;
    _emit();
  }

  /// 配置刷新阶段结束后才使用新身份/语种发请求，避免旧个性化种子被沿用。
  Future<void> refresh_context({String? language, bool reset = true}) async {
    if (_disposed) return;
    if (reset) prepare_context(language: language);
    this.language = language ?? this.language;
    if (selected_category_id > 0) {
      unawaited(ensure_loaded(selected_category_id));
    }
    await load_categories();
  }

  Future<void> load_categories() async {
    if (_disposed || loading_categories) return;
    final revision = ++_categories_revision;
    loading_categories = true;
    categories_error = null;
    _emit();
    try {
      final result = await _categories_loader();
      if (_disposed || revision != _categories_revision) return;
      final seen = <int>{};
      categories = result.where((category) {
        final id = comics_int(category['id']);
        return id > 0 && seen.add(id);
      }).toList();
      categories_loaded = true;
      if (categories.isNotEmpty) {
        if (selected_index < 0) {
          selected_category_id = comics_int(categories.first['id']);
        }
        unawaited(ensure_loaded(selected_category_id));
      }
    } catch (failure) {
      if (_disposed || revision != _categories_revision) return;
      categories_error = failure.toString();
    } finally {
      if (!_disposed && revision == _categories_revision) {
        loading_categories = false;
        _emit();
      }
    }
  }

  void select_category(int category_id) {
    if (_disposed || category_id <= 0) return;
    if (selected_category_id != category_id) {
      selected_category_id = category_id;
      _emit();
    }
    unawaited(ensure_loaded(category_id));
  }

  Future<void> ensure_loaded(int category_id) {
    final state = state_for(category_id);
    if (_disposed || state.loaded || state.busy) return Future.value();
    return _load(category_id);
  }

  Future<void> load_more(int category_id) {
    final state = state_for(category_id);
    if (_disposed || state.busy || !state.has_more) return Future.value();
    return _load(category_id, more: true);
  }

  /// 下拉刷新使用新种子；旧内容持续显示，只有成功后才原子替换。
  Future<void> refresh(int category_id) async {
    if (_disposed) return;
    unawaited(load_categories());
    await _load(category_id);
  }

  Future<void> retry(int category_id) {
    final state = state_for(category_id);
    return state.failed_more ? load_more(category_id) : _load(category_id);
  }

  Future<void> _load(int category_id, {bool more = false}) async {
    if (_disposed) return;
    final state = state_for(category_id);
    final revision = ++state.revision;
    final next_page = more ? state.page + 1 : 1;
    state.loading = state.items.isEmpty && !more;
    state.refreshing = !more && state.items.isNotEmpty;
    state.loading_more = more;
    state.error = null;
    state.failed_more = false;
    _emit();
    try {
      final result = await _page_loader(
        category_id: category_id,
        page: next_page,
        page_size: page_size,
        seed: more ? state.seed : null,
        language: language,
      );
      if (_disposed || revision != state.revision) return;
      // 服务端可能因种子过期或身份变化，把分页请求重置为新的第一页。
      // 新快照只能整体替换，不能把两轮随机排序拼接在一起。
      final reset_snapshot =
          more &&
          (result.page <= state.page ||
              (result.seed.isNotEmpty && result.seed != state.seed));
      final append = more && !reset_snapshot;
      final seen = <int>{if (append) ...state.items.map((item) => item.id)};
      final next_items = result.items
          .where((item) => seen.add(item.id))
          .toList();
      if (!append) state.items.clear();
      if (reset_snapshot) {
        state.scroll_offset = 0;
        state.snapshot_revision++;
      }
      state.items.addAll(next_items);
      state.page = result.page;
      state.total = result.total;
      state.seed = result.seed;
      state.profile_pending = result.profile_pending;
      state.loaded = true;
      // 空页或重复页不能触发无限自动重试，即使服务端总数有短暂延迟。
      state.exhausted = result.items.isEmpty || (append && next_items.isEmpty);
    } catch (failure) {
      if (_disposed || revision != state.revision) return;
      state.error = failure.toString();
      state.failed_more = more;
    } finally {
      if (!_disposed && revision == state.revision) {
        state.loading = false;
        state.refreshing = false;
        state.loading_more = false;
        _emit();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _categories_revision++;
    for (final state in _states.values) {
      state.revision++;
    }
    super.dispose();
  }
}
