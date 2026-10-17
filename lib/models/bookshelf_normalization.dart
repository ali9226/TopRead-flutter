// ignore_for_file: non_constant_identifier_names

/// TODO 混合书架沿用小说接口字段；漫画 DTO 归一化作品 ID，避免两个表的同号记录冲突。
Map<String, dynamic> normalize_bookshelf_json(Map<String, dynamic> source) {
  final data = Map<String, dynamic>.from(source);
  final is_comic =
      source['content_type'] == 'comic' ||
      (int.tryParse('${source['comic_id'] ?? ''}') ?? 0) > 0;
  if (is_comic) {
    final id = '${source['comic_id'] ?? source['novel_id'] ?? ''}';
    data['content_type'] = 'comic';
    data['novel_id'] = id;
    data['id'] = id.isNotEmpty ? 'comic:$id' : 'comic:${source['id'] ?? ''}';
    data['novel_language_id'] =
        source['comic_language_id'] ?? source['novel_language_id'] ?? '';
    data['novel_title'] =
        source['novel_title'] ??
        source['language_title'] ??
        source['title'] ??
        '';
    data['introduction'] =
        source['introduction'] ?? source['description'] ?? '';
    data['create_time'] = source['update_time'] ?? source['create_time'] ?? '';
    data['favorite_time'] =
        source['favorite_time'] ?? source['create_time'] ?? '';
  } else {
    data['content_type'] = 'novel';
  }
  if (data['category_names'] is! String) {
    final categories = data['categories'];
    data['category_names'] = categories is List
        ? categories
              .whereType<Map>()
              .map((item) => '${item['name'] ?? item['label'] ?? ''}')
              .where((name) => name.isNotEmpty)
              .join(',')
        : '';
  }
  return data;
}
