// ignore_for_file: non_constant_identifier_names

import 'package:app/components/novel_cover/adaptive_cover.dart';
import 'package:app/components/recommend_book_card/book_list_item.dart';
import 'package:app/models/recommend_ranking_item.dart';
import 'package:app/models/short_story_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('推荐小说模型解析并缓存封面宽高', () {
    final RecommendRankingItem item =
        RecommendRankingItem.from_json(<String, dynamic>{
          'id': 1,
          'title': 'Novel',
          'cover_url': 'https://cdn.example.com/cover.jpg',
          'cover_width': '600',
          'cover_height': 900,
        });

    expect(item.cover_width, 600);
    expect(item.cover_height, 900);
    expect(item.to_json()['cover_width'], 600);
    expect(item.to_json()['cover_height'], 900);
  });

  test('瀑布流优先使用后端宽高计算首帧比例', () {
    const BookListItem item = BookListItem(
      id: 'book_1',
      story_id: 1,
      type: BookListItemType.book,
      title: 'Novel',
      description: '',
      cover_url: 'https://cdn.example.com/cover.jpg',
      cover_width: 600,
      cover_height: 900,
      cover_badge: '',
      cover_meta_text: '',
      tag_list: <BookListTagItem>[],
      ad_image_url_list: <String>[],
    );

    expect(item.has_known_cover_dimensions, isTrue);
    expect(item.should_resolve_cover_dimensions, isFalse);
    expect(item.effective_cover_aspect_ratio, closeTo(2 / 3, 0.000001));
  });

  test('旧数据没有宽高时保留网络尺寸解析回退能力', () {
    const BookListItem item = BookListItem(
      id: 'book_2',
      story_id: 2,
      type: BookListItemType.book,
      title: 'Novel',
      description: '',
      cover_url: 'https://cdn.example.com/cover.jpg',
      cover_aspect_ratio: 0.74,
      cover_badge: '',
      cover_meta_text: '',
      tag_list: <BookListTagItem>[],
      ad_image_url_list: <String>[],
    );
    const AdaptiveNovelCover cover = AdaptiveNovelCover(
      image_url: 'https://cdn.example.com/cover.jpg',
      width: 120,
      default_aspect_ratio: 0.74,
      resolve_image_dimensions: true,
    );

    expect(item.has_known_cover_dimensions, isFalse);
    expect(item.should_resolve_cover_dimensions, isTrue);
    expect(item.effective_cover_aspect_ratio, 0.74);
    expect(cover.resolve_image_dimensions, isTrue);
  });

  test('短篇列表模型同步解析封面宽高', () {
    final ShortStoryItem item = ShortStoryItem.from_json(<String, dynamic>{
      'id': 3,
      'title': 'Short',
      'cover_width': 480,
      'cover_height': '720',
      'like_count': 0,
      'category_list': <String>[],
    });

    expect(item.cover_width, 480);
    expect(item.cover_height, 720);
  });
}
