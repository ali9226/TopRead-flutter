import 'package:app/models/novel_discovery.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('推荐字段与详情字段兼容，保留分类翻译以供当前语言展示', () {
    final recommended = NovelDiscoveryItem.from_json({
      'id': '42',
      'name': 'The Garden',
      'cover': 'https://fixtures.invalid/garden.jpg',
      'author': 'Author',
      'categories': [
        {
          'id': 9,
          'name': 'Fantasy',
          'translations': [
            {'language': 'zh', 'name': '奇幻'},
          ],
        },
      ],
    });
    expect(recommended.id, 42);
    expect(recommended.title, 'The Garden');
    expect(recommended.cover_url, endsWith('garden.jpg'));
    expect(recommended.categories.single['translations'], isA<List>());
    final detailed = NovelDiscoveryItem.from_json({
      'id': 7,
      'title': 'Original',
      'language_info': {'title': '本地化标题', 'cover_url': 'localized.jpg'},
      'category_list': ['冒险', '奇幻'],
    });
    expect(detailed.title, '本地化标题');
    expect(detailed.cover_url, 'localized.jpg');
    expect(detailed.categories.map((item) => item['name']), ['冒险', '奇幻']);
  });

  test('首页去除空分类和非法重复记录，最多六本且不足不凑数', () {
    final feed = NovelDiscoveryFeed.from_json({
      'seed': 'snapshot',
      'list': [
        {
          'category': {'id': 2},
          'list': [
            {'id': 7},
            {'id': 7},
            null,
            {'id': 0},
            {'id': 8},
          ],
          'total': '2',
        },
        {
          'category': {'id': 3},
          'list': [],
        },
        {
          'category': {'id': 2},
          'list': [
            {'id': 99},
          ],
        },
        {
          'category': {'id': 5},
          'list': List.generate(9, (index) => {'id': index + 20}),
        },
      ],
    });
    expect(feed.sections.map((section) => section.id), [2, 5]);
    expect(feed.sections.first.items.map((item) => item.id), [7, 8]);
    expect(feed.sections.last.items, hasLength(6));
    expect(feed.categories.map((item) => item['id']), [2, 5]);
    expect(feed.seed, 'snapshot');
  });

  test('分页保留后端顺序、种子与总数，不把重复ID渲染成新作品', () {
    final page = NovelDiscoveryPage.from_json({
      'page': '3',
      'page_size': 24,
      'total': '80',
      'seed': 'stable',
      'list': [
        {'id': 9},
        {'id': 2},
        {'id': 9},
        'bad',
      ],
    });
    expect(page.items.map((item) => item.id), [9, 2]);
    expect(page.page, 3);
    expect(page.total, 80);
    expect(page.seed, 'stable');
  });
}
