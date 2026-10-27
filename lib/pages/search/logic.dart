// ignore_for_file: non_constant_identifier_names

import 'package:app/api/work_search.dart';
import 'package:app/models/recommend_ranking_item.dart';
import 'package:app/models/work_search.dart';
import 'package:flutter/foundation.dart';

typedef NovelSearchLoader =
    Future<List<RecommendRankingItem>> Function({
      required String keyword,
      required int limit,
      required List<int> no_ids,
    });
typedef ComicSearchLoader =
    Future<ComicSearchPage> Function({
      required String keyword,
      required int page,
      required int page_size,
      required String language,
    });

/// 两种作品并行搜索，各自维护游标与错误，单侧失败仍显示另一侧命中。
class Logic extends ChangeNotifier {
  Logic({NovelSearchLoader? novel_loader, ComicSearchLoader? comic_loader})
    : _novel_loader = novel_loader ?? search_novels,
      _comic_loader = comic_loader ?? search_comics;

  static const int page_size = 20;
  final NovelSearchLoader _novel_loader;
  final ComicSearchLoader _comic_loader;
  final List<SearchResultItem> items = [];
  bool loading = false;
  bool loading_more = false;
  bool novel_failed = false;
  bool comic_failed = false;
  bool _novel_has_more = true;
  bool _comic_has_more = true;
  int _comic_page = 0;
  int _revision = 0;
  bool _disposed = false;
  String _keyword = '';
  String _language = '';

  bool get has_more => _novel_has_more || _comic_has_more;
  bool get has_error => novel_failed || comic_failed;

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  /// 新查询、切换语种及 ID 直达都会同步让所有旧请求失效。
  void reset({bool show_loading = false}) {
    _revision++;
    items.clear();
    loading = show_loading;
    loading_more = false;
    novel_failed = false;
    comic_failed = false;
    _novel_has_more = true;
    _comic_has_more = true;
    _comic_page = 0;
    _keyword = '';
    _emit();
  }

  Future<void> search(String keyword, {required String language}) async {
    if (_disposed || keyword.trim().isEmpty) return;
    reset(show_loading: true);
    _keyword = keyword.trim();
    _language = language;
    await _load_page(_revision);
  }

  /// 失败后保留原游标，用户重试时不会跳过未返回的漫画页。
  Future<void> load_more() async {
    if (_disposed || loading || loading_more || !has_more || _keyword.isEmpty) {
      return;
    }
    loading_more = true;
    _emit();
    await _load_page(_revision);
  }

  Future<void> _load_page(int revision) async {
    // 两个任务分别捕获错误，确保 Future.wait 不会丢弃另一种作品的结果。
    await Future.wait([
      if (_novel_has_more) _load_novels(revision),
      if (_comic_has_more) _load_comics(revision),
    ]);
    if (_disposed || revision != _revision) return;
    loading = false;
    loading_more = false;
    _emit();
  }

  Future<void> _load_novels(int revision) async {
    final no_ids = items
        .where((item) => !item.is_comic)
        .map((item) => item.work_id)
        .toList();
    try {
      final result = await _novel_loader(
        keyword: _keyword,
        limit: page_size,
        no_ids: no_ids,
      );
      if (_disposed || revision != _revision) return;
      final added = _append(result.map(SearchResultItem.novel));
      _novel_has_more = result.length >= page_size && added > 0;
      novel_failed = false;
    } catch (_) {
      if (_disposed || revision != _revision) return;
      novel_failed = true;
    }
  }

  Future<void> _load_comics(int revision) async {
    final next_page = _comic_page + 1;
    try {
      final result = await _comic_loader(
        keyword: _keyword,
        page: next_page,
        page_size: page_size,
        language: _language,
      );
      if (_disposed || revision != _revision) return;
      _append(result.items.map(SearchResultItem.comic));
      _comic_page = next_page;
      _comic_has_more =
          result.items.isNotEmpty && next_page * page_size < result.total;
      comic_failed = false;
    } catch (_) {
      if (_disposed || revision != _revision) return;
      comic_failed = true;
    }
  }

  int _append(Iterable<SearchResultItem> candidates) {
    final seen = items.map((item) => item.id).toSet();
    final additions = candidates
        .where((item) => item.work_id > 0 && seen.add(item.id))
        .toList();
    items.addAll(additions);
    return additions.length;
  }

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    super.dispose();
  }
}
