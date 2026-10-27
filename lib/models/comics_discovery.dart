// ignore_for_file: non_constant_identifier_names

import 'comics.dart';

/// 推荐与分页都使用服务端排名；客户端只去除非法或重复记录。
List<ComicItem> _discovery_items(dynamic value) {
  final ids = <int>{};
  return comics_list(value)
      .map(ComicItem.from_json)
      .where((item) => item.id > 0 && ids.add(item.id))
      .toList();
}

class ComicDiscoverySection {
  const ComicDiscoverySection({
    required this.category,
    required this.items,
    required this.total,
    this.seed = '',
  });

  final Map<String, dynamic> category;
  final List<ComicItem> items;
  final int total;
  final String seed;
  int get id => comics_int(category['id']);

  factory ComicDiscoverySection.from_json(Map<String, dynamic> json) =>
      ComicDiscoverySection(
        category: comics_map(json['category']),
        items: _discovery_items(json['list']).take(6).toList(),
        total: comics_int(json['total']),
        seed: json['seed']?.toString() ?? '',
      );
}

class ComicDiscoveryFeed {
  const ComicDiscoveryFeed({
    required this.sections,
    required this.categories,
    this.seed = '',
    this.profile_pending = false,
  });

  final List<ComicDiscoverySection> sections;
  final List<Map<String, dynamic>> categories;
  final String seed;
  final bool profile_pending;

  factory ComicDiscoveryFeed.from_json(Map<String, dynamic> json) {
    final ids = <int>{};
    final sections = comics_list(json['list'])
        .map(ComicDiscoverySection.from_json)
        .where(
          (section) =>
              section.id > 0 && section.items.isNotEmpty && ids.add(section.id),
        )
        .toList();
    final categories = comics_list(json['categories']);
    return ComicDiscoveryFeed(
      sections: sections,
      categories: categories.isEmpty
          ? sections.map((section) => section.category).toList()
          : categories,
      seed: json['seed']?.toString() ?? '',
      profile_pending: json['profile_pending'] == true,
    );
  }
}

/// seed 固定同一轮推荐的排序，翻页时原样回传，刷新才获取新一轮。
class ComicDiscoveryPage {
  const ComicDiscoveryPage({
    required this.items,
    required this.total,
    required this.page,
    required this.page_size,
    this.seed = '',
    this.profile_pending = false,
  });

  final List<ComicItem> items;
  final int total;
  final int page;
  final int page_size;
  final String seed;
  final bool profile_pending;

  factory ComicDiscoveryPage.from_json(Map<String, dynamic> json) =>
      ComicDiscoveryPage(
        items: _discovery_items(json['list']),
        total: comics_int(json['total']),
        page: comics_int(json['page']),
        page_size: comics_int(json['page_size']),
        seed: json['seed']?.toString() ?? '',
        profile_pending: json['profile_pending'] == true,
      );
}
