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
