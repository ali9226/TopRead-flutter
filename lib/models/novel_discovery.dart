// ignore_for_file: non_constant_identifier_names

/// 发现页仅解析展示与导航所需数据，同时兼容推荐接口及小说详情的字段。
int novel_discovery_int(dynamic value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};

List<Map<String, dynamic>> novel_discovery_maps(dynamic value) => value is List
    ? value.whereType<Map>().map((item) => _map(item)).toList()
    : [];

String _first_text(List<dynamic> values) => values
    .map((value) => value?.toString().trim() ?? '')
    .firstWhere((value) => value.isNotEmpty, orElse: () => '');

/// 精简书目保持服务端推荐顺序，不在客户端按热度重新排序。
class NovelDiscoveryItem {
  const NovelDiscoveryItem({
    required this.id,
    required this.title,
    required this.cover_url,
    this.author = '',
    this.categories = const [],
  });

  final int id;
  final String title;
  final String cover_url;
  final String author;
  final List<Map<String, dynamic>> categories;

  factory NovelDiscoveryItem.from_json(Map<String, dynamic> json) {
    final language_info = _map(json['language_info']);
    var categories = novel_discovery_maps(json['categories']);
    if (categories.isEmpty && json['category_list'] is List) {
      categories = (json['category_list'] as List)
          .whereType<String>()
          .where((name) => name.trim().isNotEmpty)
          .map((name) => <String, dynamic>{'name': name.trim()})
          .toList();
    }
    final category_name = _first_text([json['category_name']]);
    if (categories.isEmpty && category_name.isNotEmpty) {
      categories = [
        {'name': category_name},
      ];
    }
    return NovelDiscoveryItem(
      id: novel_discovery_int(json['id']),
      title: _first_text([json['name'], language_info['title'], json['title']]),
      cover_url: _first_text([
        json['cover'],
        json['cover_url'],
        language_info['cover_url'],
      ]),
      author: _first_text([json['author_name'], json['author']]),
      categories: categories,
    );
  }
}

List<NovelDiscoveryItem> _items(dynamic value) {
  final seen = <int>{};
  return novel_discovery_maps(value)
      .map(NovelDiscoveryItem.from_json)
      .where((item) => item.id > 0 && seen.add(item.id))
      .toList();
}

class NovelDiscoverySection {
  const NovelDiscoverySection({
    required this.category,
    required this.items,
    required this.total,
    this.seed = '',
  });
  final Map<String, dynamic> category;
  final List<NovelDiscoveryItem> items;
  final int total;
  final String seed;
  int get id => novel_discovery_int(category['id']);

  factory NovelDiscoverySection.from_json(Map<String, dynamic> json) =>
      NovelDiscoverySection(
        category: _map(json['category']),
        items: _items(json['list']).take(6).toList(),
        total: novel_discovery_int(json['total']),
        seed: json['seed']?.toString() ?? '',
      );
}

class NovelDiscoveryFeed {
  const NovelDiscoveryFeed({
    required this.sections,
    required this.categories,
    this.seed = '',
    this.profile_pending = false,
  });
  final List<NovelDiscoverySection> sections;
  final List<Map<String, dynamic>> categories;
  final String seed;
  final bool profile_pending;

  factory NovelDiscoveryFeed.from_json(Map<String, dynamic> json) {
    final seen = <int>{};
    final sections = novel_discovery_maps(json['list'])
        .map(NovelDiscoverySection.from_json)
        .where(
          (section) =>
              section.id > 0 &&
              section.items.isNotEmpty &&
              seen.add(section.id),
        )
        .toList();
    final categories = novel_discovery_maps(json['categories']);
    return NovelDiscoveryFeed(
      sections: sections,
      categories: categories.isNotEmpty
          ? categories
          : sections.map((section) => section.category).toList(),
      seed: json['seed']?.toString() ?? '',
      profile_pending: json['profile_pending'] == true,
    );
  }
}

/// 排序种子绑定服务端身份与语种；过期时服务端明确返回新种子的第一页。
class NovelDiscoveryPage {
  const NovelDiscoveryPage({
    required this.items,
    required this.total,
    required this.page,
    required this.page_size,
    this.seed = '',
    this.profile_pending = false,
  });
  final List<NovelDiscoveryItem> items;
  final int total;
  final int page;
  final int page_size;
  final String seed;
  final bool profile_pending;

  factory NovelDiscoveryPage.from_json(Map<String, dynamic> json) =>
      NovelDiscoveryPage(
        items: _items(json['list']),
        total: novel_discovery_int(json['total']),
        page: novel_discovery_int(json['page']),
        page_size: novel_discovery_int(json['page_size']),
        seed: json['seed']?.toString() ?? '',
        profile_pending: json['profile_pending'] == true,
      );
}
