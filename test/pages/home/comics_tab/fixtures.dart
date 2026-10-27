import 'package:app/models/comics.dart';
import 'package:app/models/comics_discovery.dart';

ComicDiscoverySection discovery_section(
  int id, {
  int first_id = 1,
  int count = 6,
  String seed = '',
  List<String> cover_urls = const [],
}) => ComicDiscoverySection(
  category: {
    'id': id,
    'name': 'Category $id',
    'translations': {'en': 'Category $id', 'zh': '分类 $id'},
  },
  items: List.generate(
    count,
    (index) => ComicItem.from_json({
      'id': first_id + index,
      'title': 'A journey beyond the stars ${first_id + index}',
      'author_name': 'Artist',
      'cover_url': cover_urls.isEmpty
          ? ''
          : cover_urls[index % cover_urls.length],
      'categories': [
        {
          'id': id,
          'name': 'Fantasy',
          'translations': {'en': 'Fantasy', 'zh': '奇幻'},
        },
        {
          'id': 80,
          'name': 'Adventure',
          'translations': {'en': 'Adventure', 'zh': '冒险'},
        },
      ],
    }),
  ),
  total: 40,
  seed: seed,
);

ComicDiscoveryFeed discovery_feed(
  List<ComicDiscoverySection> sections, {
  String seed = 'home-seed',
}) => ComicDiscoveryFeed(
  sections: sections,
  categories: sections.map((section) => section.category).toList(),
  seed: seed,
);
