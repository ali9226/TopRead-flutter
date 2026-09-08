import 'package:flutter/foundation.dart';

import 'models/creator_backend_models.dart';

typedef CreatorPageLoader = Future<Map<String, dynamic>?> Function(int page);

/// 每个分类独立持有分页和请求序号，刷新后忽略旧的加载更多响应。
class CreatorTabState extends ChangeNotifier {
  CreatorTabState({required this.loadPage, this.isDraftList = false});

  final CreatorPageLoader loadPage;
  final bool isDraftList;
  List<CreatorWorkModel> works = [];
  int page = 0;
  int total = 0;
  bool hasMore = false;
  bool isLoading = false;
  bool isLoadingMore = false;
  String? error;
  String? loadMoreError;
  int _generation = 0;
  bool _disposed = false;

  Future<void> refresh() => _load(refresh: true);

  Future<void> loadMore() async {
    if (isLoading || isLoadingMore || !hasMore) return;
    await _load(refresh: false);
  }

  Future<void> _load({required bool refresh}) async {
    final generation = refresh ? ++_generation : _generation;
    final nextPage = refresh ? 1 : page + 1;
    if (refresh) {
      isLoading = true;
      isLoadingMore = false;
      error = null;
      loadMoreError = null;
    } else {
      isLoadingMore = true;
      loadMoreError = null;
    }
    notifyListeners();
    try {
      final result = await loadPage(nextPage);
      if (_disposed || generation != _generation) return;
      if (result == null || result['list'] is! List) {
        throw const FormatException('作品列表加载失败');
      }
      final incoming = (result['list'] as List).map((item) {
        final json = Map<String, dynamic>.from(item as Map);
        return isDraftList
            ? CreatorWorkModel.fromDraftJson(json)
            : CreatorWorkModel.fromJson(json);
      }).toList();
      final byId = <int, CreatorWorkModel>{
        if (!refresh)
          for (final work in works) work.id: work,
        for (final work in incoming) work.id: work,
      };
      works = byId.values.toList()
        ..sort((a, b) {
          final timeOrder = b.updatedAt.compareTo(a.updatedAt);
          return timeOrder != 0 ? timeOrder : b.id.compareTo(a.id);
        });
      total = int.tryParse('${result['total']}') ?? works.length;
      page = nextPage;
      hasMore =
          incoming.isNotEmpty &&
          (result['has_more'] is bool
              ? result['has_more'] as bool
              : works.length < total);
    } catch (_) {
      if (_disposed || generation != _generation) return;
      if (refresh) {
        error = '作品加载失败，请下拉刷新或点击重试';
      } else {
        loadMoreError = '加载更多失败，点击重试';
      }
    } finally {
      if (!_disposed && generation == _generation) {
        isLoading = false;
        isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
