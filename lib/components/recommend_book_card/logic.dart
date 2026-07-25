// ignore_for_file: non_constant_identifier_names

import 'package:app/components/recommend_book_card/book_list_item.dart';

/// 推荐书籍卡片列表逻辑。
class RecommendBookCardLogic {
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
        .toList(growable: false);
  }
}
