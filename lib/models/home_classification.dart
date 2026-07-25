// ignore_for_file: non_constant_identifier_names

/// 首页分类数据模型。
///
/// 对应 `redis/get` 接口返回的 `home_classification` 数组中的单条分类记录。
class HomeClassification {
  /// 分类 ID。
  final int id;

  /// 分类标题。
  final String title;

  const HomeClassification({
    required this.id,
    required this.title,
  });

  /// 从原始 json 解析单条分类对象。
  factory HomeClassification.from_json(Map<String, dynamic> json) {
    return HomeClassification(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
    );
  }

  /// 从 json 列表解析分类对象列表。
  static List<HomeClassification> from_json_list(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (dynamic item) =>
              HomeClassification.from_json(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  /// 转换为 json 对象，用于本地缓存。
  Map<String, dynamic> to_json() {
    return <String, dynamic>{
      'id': id,
      'title': title,
    };
  }

  /// 从 json 列表转换为分类对象列表（用于读取缓存）。
  static List<HomeClassification> from_cache_list(List<dynamic> raw) {
    return raw
        .whereType<Map>()
        .map(
          (dynamic item) =>
              HomeClassification.from_json(Map<String, dynamic>.from(item)),
        )
        .toList();
  }
}
