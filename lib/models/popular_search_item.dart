// ignore_for_file: non_constant_identifier_names

/// 热门搜索标签数据模型。
///
/// 对应 `redis/get` 接口返回的 `popular_searches` 数组中的单条记录。
/// 包含标题、类型和关联ID，用于搜索页面的热门标签展示。
class PopularSearchItem {
  /// 标签标题（多语种）。
  final String title;

  /// 类型：1=分类，2=小说。
  final int type;

  /// 关联ID：type=1时为分类ID，type=2时为小说ID。
  final int id;

  /// 额外值（可选）。
  final String value;

  const PopularSearchItem({
    required this.title,
    required this.type,
    required this.id,
    this.value = '',
  });

  /// 从接口返回的原始 json 解析单条热门搜索标签。
  factory PopularSearchItem.from_json(Map<String, dynamic> json) {
    final Map<String, dynamic> note = json['note'] is Map
        ? Map<String, dynamic>.from(json['note'] as Map)
        : <String, dynamic>{};

    return PopularSearchItem(
      title: json['title']?.toString() ?? '',
      type: _parse_int(note['type']),
      id: _parse_int(note['id']),
      value: note['value']?.toString() ?? '',
    );
  }

  /// 从 json 列表解析热门搜索标签列表。
  static List<PopularSearchItem> from_json_list(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (dynamic item) => PopularSearchItem.from_json(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  /// 安全解析 int 类型字段。
  static int _parse_int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
