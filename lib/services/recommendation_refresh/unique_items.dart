// ignore_for_file: non_constant_identifier_names

/// 按服务端排名保留未占用作品，ID属于同一本作品而非某个分类中的独立卡片。
/// 不修改调用方的占用集合，便于并发换批响应按最新整页状态复核。
List<T> unique_recommendation_items<T>(
  Iterable<T> candidates, {
  required int Function(T item) id_of,
  Set<int> reserved_ids = const {},
  int? limit,
}) {
  final seen = Set<int>.of(reserved_ids);
  final items = <T>[];
  if (limit != null && limit <= 0) return items;
  for (final item in candidates) {
    final id = id_of(item);
    if (id <= 0 || !seen.add(id)) continue;
    items.add(item);
    if (limit != null && items.length >= limit) break;
  }
  return List.unmodifiable(items);
}
