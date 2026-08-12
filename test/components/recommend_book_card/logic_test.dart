// ignore_for_file: non_constant_identifier_names

import 'package:app/components/recommend_book_card/book_list_item.dart';
import 'package:app/components/recommend_book_card/logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecommendBookCardLogic.exclude_duplicate_items', () {
    test('过滤接口单次响应中的重复卡片并保持原始顺序', () {
      final List<BookListItem> result =
          RecommendBookCardLogic.exclude_duplicate_items(
            candidates: <BookListItem>[
              _build_item('recommend_409', 409),
              _build_item('recommend_410', 410),
              _build_item('recommend_409', 409),
            ],
          );

      expect(result.map((BookListItem item) => item.id), <String>[
        'recommend_409',
        'recommend_410',
      ]);
    });

    test('过滤加载更多响应中已经展示的卡片', () {
      final List<BookListItem> result =
          RecommendBookCardLogic.exclude_duplicate_items(
            existing_items: <BookListItem>[_build_item('recommend_409', 409)],
            candidates: <BookListItem>[
              _build_item('recommend_409', 409),
              _build_item('recommend_411', 411),
            ],
          );

      expect(result.map((BookListItem item) => item.id), <String>[
        'recommend_411',
      ]);
    });
  });

  test('原生广告槽位不会被识别为小说数据', () {
    final BookListItem ad_slot = BookListItem.ad_slot(id: 'masonry_ad_2_3');

    expect(ad_slot.id, 'masonry_ad_2_3');
    expect(ad_slot.is_ad, isTrue);
    expect(ad_slot.is_book, isFalse);
    expect(ad_slot.story_id, 0);
    expect(ad_slot.has_ad_images, isFalse);
  });

  group('RecommendBookCardLogic.insert_ad_in_batch_middle', () {
    test('首屏偶数批次把广告插入中点而不是列表底部', () {
      final BookListItem ad_slot = BookListItem.ad_slot(id: 'ad_initial');
      final List<BookListItem> result =
          RecommendBookCardLogic.insert_ad_in_batch_middle(
            batch: List<BookListItem>.generate(
              10,
              (int index) => _build_item('book_$index', index),
            ),
            ad_slot: ad_slot,
          );

      expect(result.indexOf(ad_slot), 5);
      expect(result.last.is_book, isTrue);
    });

    test('每次加载更多按本批数据重新计算广告中点', () {
      final BookListItem ad_slot = BookListItem.ad_slot(id: 'ad_load_more');
      final List<BookListItem> result =
          RecommendBookCardLogic.insert_ad_in_batch_middle(
            batch: <BookListItem>[
              _build_item('book_11', 11),
              _build_item('book_12', 12),
              _build_item('book_13', 13),
            ],
            ad_slot: ad_slot,
          );

      expect(result.map((BookListItem item) => item.id), <String>[
        'book_11',
        'book_12',
        'ad_load_more',
        'book_13',
      ]);
    });
  });
}

BookListItem _build_item(String id, int story_id) {
  return BookListItem(
    id: id,
    story_id: story_id,
    type: BookListItemType.book,
    title: id,
    description: '',
    cover_url: '',
    cover_badge: '',
    cover_meta_text: '',
    tag_list: const <BookListTagItem>[],
    ad_image_url_list: const <String>[],
  );
}
