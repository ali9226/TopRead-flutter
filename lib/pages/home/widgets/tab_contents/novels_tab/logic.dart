// ignore_for_file: non_constant_identifier_names

import 'package:app/api/novel_discovery.dart';
import 'package:app/models/novel_discovery.dart';
import 'package:app/services/recommendation_refresh/unique_items.dart';
import 'package:flutter/foundation.dart';

/// 首页和单组请求分开注入，测试可控制异步顺序而不访问网络。
typedef NovelsHomeLoader =
    Future<NovelDiscoveryFeed> Function({String? language, String? seed});
typedef NovelsCategoryLoader =
    Future<NovelDiscoverySection> Function({
      required int category_id,
      required List<int> exclude_ids,
      List<int>? reserved_ids,
      String? language,
      String? seed,
    });

/// 首页分组推荐状态：刷新整页，换批只替换对应分组并保留其他位置。
class NovelsTabLogic extends ChangeNotifier {
  NovelsTabLogic({
    NovelsHomeLoader? home_loader,
    NovelsCategoryLoader? category_loader,
  }) : _home_loader = home_loader ?? load_novel_home_sections,
       _category_loader = category_loader ?? shuffle_novel_category;

  final NovelsHomeLoader _home_loader;
  final NovelsCategoryLoader _category_loader;
  List<NovelDiscoverySection> sections = const [];
  bool loading = false;
  bool has_loaded = false;
  bool profile_pending = false;
  int get request_revision => _generation;
  String? error;
  String? _language;
  String _seed = '';
  bool _disposed = false;
  int _generation = 0;
  final Set<int> _shuffling = {};
  final Map<int, String> _shuffle_errors = {};
  final Map<int, int> _section_revisions = {};

  bool is_shuffling(int category_id) => _shuffling.contains(category_id);
  String? shuffle_error(int category_id) => _shuffle_errors[category_id];
  int section_revision(int category_id) => _section_revisions[category_id] ?? 0;

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  /// 语种或身份变更立即废弃旧响应，避免旧身份的数据闪回新页面。
  void prepare_refresh({String? language}) {
    if (_disposed) return;
    _generation++;
    _language = language ?? _language;
    sections = const [];
    profile_pending = false;
    loading = true;
    error = null;
    _shuffling.clear();
    _shuffle_errors.clear();
    _emit();
  }

  /// 下拉刷新保留原分组；只有语种与账号变化时主动清空旧内容。
  Future<void> refresh({String? language, bool clear = false}) async {
    if (_disposed) return;
    final generation = ++_generation;
    _language = language ?? _language;
    if (clear) sections = const [];
    loading = true;
    error = null;
    _shuffling.clear();
    _shuffle_errors.clear();
    _emit();
    try {
      // 不复用上一页seed，完整刷新由服务端重新生成推荐顺序。
      final feed = await _home_loader(language: _language);
      if (_disposed || generation != _generation) return;
      final seen_categories = <int>{};
      final occupied = <int>{};
      final unique_sections = <NovelDiscoverySection>[];
      for (final section in feed.sections) {
        if (section.id <= 0 ||
            section.items.isEmpty ||
            !seen_categories.add(section.id)) {
          continue;
        }
        final items = unique_recommendation_items(
          section.items,
          id_of: (item) => item.id,
          reserved_ids: occupied,
        );
        if (items.isEmpty) continue;
        occupied.addAll(items.map((item) => item.id));
        unique_sections.add(
          NovelDiscoverySection(
            category: section.category,
            items: items,
            total: section.total,
            seed: section.seed,
          ),
        );
      }
      sections = List.unmodifiable(unique_sections);
      _seed = feed.seed;
      profile_pending = feed.profile_pending;
      for (final section in sections) {
        _section_revisions[section.id] = section_revision(section.id) + 1;
      }
      has_loaded = true;
    } catch (failure) {
      if (_disposed || generation != _generation) return;
      error = failure.toString();
    } finally {
      if (!_disposed && generation == _generation) {
        loading = false;
        _emit();
      }
    }
  }

  /// 当前组换新优先，其他组已占用的作品严格排除；仍允许各组独立加载。
  Future<void> shuffle(int category_id) async {
    if (_disposed || loading || _shuffling.contains(category_id)) return;
    final index = sections.indexWhere((section) => section.id == category_id);
    if (index < 0) return;
    final current = sections[index];
    final generation = _generation;
    _shuffling.add(category_id);
    _shuffle_errors.remove(category_id);
    _emit();
    try {
      final seed = current.seed.isEmpty ? _seed : current.seed;
      final next = await _category_loader(
        category_id: category_id,
        exclude_ids: current.items.map((item) => item.id).toSet().toList(),
        reserved_ids: _reserved_ids(category_id).toList(),
        language: _language,
        seed: seed.isEmpty ? null : seed,
      );
      if (_disposed || generation != _generation) return;
      if (next.id != category_id) throw StateError('Unexpected category');
      final next_sections = List<NovelDiscoverySection>.of(sections);
      final target = next_sections.indexWhere(
        (section) => section.id == category_id,
      );
      if (target < 0) return;
      if (next.items.isEmpty) {
        next_sections.removeAt(target);
      } else {
        // 其他分组可能已先完成并占用同一新作品，应用响应时再次复核最新整页。
        final reserved = _reserved_ids(category_id);
        var items = unique_recommendation_items(
          next.items,
          id_of: (item) => item.id,
          reserved_ids: reserved,
        );
        if (items.length < next.items.length) {
          // 仅为并发冲突补回本组原卡片，不把服务端真实库存不足擅自补满。
          items = unique_recommendation_items(
            [...items, ...current.items],
            id_of: (item) => item.id,
            reserved_ids: reserved,
            limit: next.items.length,
          );
        }
        if (items.isEmpty) {
          next_sections.removeAt(target);
        } else {
          next_sections[target] = NovelDiscoverySection(
            category: next.category,
            items: items,
            total: next.total,
            seed: next.seed,
          );
        }
      }
      sections = List.unmodifiable(next_sections);
      _section_revisions[category_id] = section_revision(category_id) + 1;
    } catch (failure) {
      if (_disposed || generation != _generation) return;
      _shuffle_errors[category_id] = failure.toString();
    } finally {
      if (!_disposed && generation == _generation) {
        _shuffling.remove(category_id);
        _emit();
      }
    }
  }

  Set<int> _reserved_ids(int category_id) => sections
      .where((section) => section.id != category_id)
      .expand((section) => section.items)
      .map((item) => item.id)
      .where((id) => id > 0)
      .toSet();

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
