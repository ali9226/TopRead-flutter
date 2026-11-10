// ignore_for_file: non_constant_identifier_names

import 'package:app/components/recommend_book_card/book_list_item.dart';
import 'package:app/stores/recommend_waterfall_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('不同 waterfall_id 的数据、高度与广告序号完全隔离', () {
    final RecommendWaterfallStore store = RecommendWaterfallStore();
    final RecommendWaterfallSession home = store.obtain('home_recommend');
    final RecommendWaterfallSession search = store.obtain('search_recommend');

    home.items.add(_build_item('home_book', 1));
    home.item_heights['home_book'] = 280;
    final String home_ad_id = home.create_ad_slot_id();
    final String search_ad_id = search.create_ad_slot_id();

    expect(search.items, isEmpty);
    expect(search.item_heights, isEmpty);
    expect(home_ad_id, 'masonry_ad_home_recommend_1');
    expect(search_ad_id, 'masonry_ad_search_recommend_1');
    expect(store.session_count, 2);

    store.onClose();
  });

  test('同一 waterfall_id 在页面重建后恢复原会话对象', () {
    final RecommendWaterfallStore store = RecommendWaterfallStore();
    final RecommendWaterfallSession first = store.obtain('home_recommend');
    first.items.add(_build_item('book_1', 1));
    first.item_heights['book_1'] = 312;
    first.has_initialized = true;

    final RecommendWaterfallSession restored = store.obtain('home_recommend');

    expect(restored, same(first));
    expect(restored.items.single.id, 'book_1');
    expect(restored.item_heights['book_1'], 312);
    expect(restored.has_initialized, isTrue);

    store.onClose();
  });

  test('未挂载瀑布流刷新后废弃旧数据和请求，保留独立会话及广告序号', () {
    final RecommendWaterfallStore store = RecommendWaterfallStore();
    final RecommendWaterfallSession home = store.obtain('home_recommend');
    final RecommendWaterfallSession search = store.obtain('search_recommend');
    home.items.addAll(<BookListItem>[
      _build_item('old_book', 1),
      BookListItem.ad_slot(id: home.create_ad_slot_id()),
    ]);
    home.item_heights['old_book'] = 312;
    home.removing_ids.add('old_book');
    home.skipped_ad_slot_ids.add('old_ad');
    home.active_overlay_id = 'old_book';
    home.has_initialized = true;
    home.is_initial_request_active = true;
    home.is_initial_loading = false;
    home.is_loading_more = true;
    home.has_more = false;
    final int old_generation = home.request_generation;
    search.items.add(_build_item('search_book', 2));
    int changes = 0;
    home.addListener(() => changes++);

    store.invalidate('home_recommend');

    expect(store.obtain('home_recommend'), same(home));
    expect(home.request_generation, greaterThan(old_generation));
    expect(home.items, isEmpty);
    expect(home.item_heights, isEmpty);
    expect(home.removing_ids, isEmpty);
    expect(home.skipped_ad_slot_ids, isEmpty);
    expect(home.active_overlay_id, isNull);
    expect(home.has_initialized, isFalse);
    expect(home.is_initial_request_active, isFalse);
    expect(home.is_initial_loading, isTrue);
    expect(home.is_loading_more, isFalse);
    expect(home.has_more, isTrue);
    expect(home.create_ad_slot_id(), 'masonry_ad_home_recommend_2');
    expect(search.items.single.id, 'search_book');
    expect(changes, 1);

    store.onClose();
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
