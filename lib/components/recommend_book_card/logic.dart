// ignore_for_file: non_constant_identifier_names

import 'package:app/components/recommend_book_card/book_list_item.dart';

/// 推荐书籍卡片列表逻辑。
class RecommendBookCardLogic {
  /// 将一个独立广告槽位插入本批小说的中间位置。
  ///
  /// 每一批数据（首屏或一次加载更多）单独计算中点，避免广告总是
  /// 被追加到整个瀑布流末尾。奇数条数据时放在中间小说之后。
  static List<BookListItem> insert_ad_in_batch_middle({
    required List<BookListItem> batch,
    required BookListItem ad_slot,
  }) {
    if (batch.isEmpty) return <BookListItem>[];

    final List<BookListItem> result = List<BookListItem>.of(batch);
    final int insert_index = (result.length + 1) ~/ 2;
    result.insert(insert_index, ad_slot);
    return result;
  }

  /// 过滤候选列表内以及现有列表中重复的卡片。
  ///
  /// [candidates] 本次接口返回并完成映射的候选卡片。
  /// [existing_items] 当前页面已经展示的卡片。
  ///
  /// 卡片的 [BookListItem.id] 同时也是瀑布流 Widget Key，
  /// 因此必须在进入 UI 列表前保证唯一，避免重复数据触发 Duplicate keys。
  static List<BookListItem> exclude_duplicate_items({
    required Iterable<BookListItem> candidates,
    Iterable<BookListItem> existing_items = const <BookListItem>[],
  }) {
    final Set<String> existing_ids = existing_items
        .map((BookListItem item) => item.id)
        .toSet();

    return candidates
        .where((BookListItem item) => existing_ids.add(item.id))
        .toList();
  }
}
