import 'package:app/models/novel_discovery.dart';

NovelDiscoverySection discovery_section(
  int id, {
  int first_id = 1,
  int count = 6,
  String seed = '',
  List<String> cover_urls = const [],
}) => NovelDiscoverySection(
  category: {
    'id': id,
    'name': ['Fantasy', 'Romance', 'Adventure'][id % 3],
    'translations': [
      {
        'language': 'en',
        'name': ['Fantasy', 'Romance', 'Adventure'][id % 3],
      },
      {
        'language': 'zh',
        'name': ['奇幻', '爱情', '冒险'][id % 3],
      },
    ],
  },
  items: List.generate(
    count,
    (index) => NovelDiscoveryItem.from_json({
      'id': first_id + index,
      'title': [
        'The Secret Garden',
        'A Journey to the Stars',
        'The Lost World',
        'Pride and Prejudice',
        'A Tale of Two Cities',
        'The Last Kingdom',
      ][index % 6],
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

NovelDiscoveryFeed discovery_feed(
  List<NovelDiscoverySection> sections, {
  String seed = 'home-seed',
}) => NovelDiscoveryFeed(
  sections: sections,
  categories: sections.map((section) => section.category).toList(),
  seed: seed,
);
