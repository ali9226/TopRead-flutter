// ignore_for_file: non_constant_identifier_names

/* TODO
 * 偏好数据模型。
 *
 * 对应 `redis/get` 接口返回的 `preference_list` 中的单条偏好类别记录。
 */
class Preference {
  /// TODO 偏好类别唯一 id。
  final int id;

  /// TODO 选择模式：1 单选，2 多选。
  final int single_select;

  /// TODO 偏好类别标题。
  final String title;

  /// TODO 该类别下的所有偏好选项列表。
  final List<PreferenceItem> data_list;

  const Preference({
    required this.id,
    required this.single_select,
    required this.title,
    required this.data_list,
  });

  /// TODO 创建空数据，避免外部判空分支过多。
  const Preference.empty()
    : id = 0,
      single_select = 1,
      title = '',
      data_list = const [];

  /// TODO 当前类别是否为单选模式。
  bool get is_single_select => single_select == 1;

  /// TODO 从接口返回的单条 json 中解析业务对象。
  factory Preference.from_json(Map<String, dynamic> json) {
    return Preference(
      id: _to_int(json['id']),
      single_select: _to_int(json['single_select'], 1),
      title: _to_string(json['title']),
      data_list: _parse_data_list(json['data_list']),
    );
  }

  /// TODO 批量解析接口返回数组。
  static List<Preference> from_json_list(List<dynamic> json_list) {
    return json_list
        .whereType<Map>()
        .map(
          (dynamic item) =>
              Preference.from_json(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  /// TODO 解析偏好选项子列表。
  static List<PreferenceItem> _parse_data_list(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (dynamic item) =>
              PreferenceItem.from_json(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  /// TODO 输出回 json，便于后续缓存或调试。
  Map<String, dynamic> to_json() {
    return <String, dynamic>{
      'id': id,
      'single_select': single_select,
      'title': title,
      'data_list': data_list.map((PreferenceItem item) => item.to_json()).toList(),
    };
  }
}

/* TODO
 * 偏好选项数据模型。
 *
 * 对应 `preference_list` 中每个类别下的单条选项记录。
 */
class PreferenceItem {
  /// TODO 选项唯一 id。
  final int id;

  /// TODO 选项所属类型（与父级类别 id 对应）。
  final int type;

  /// TODO 选项标题。
  final String title;

  const PreferenceItem({
    required this.id,
    required this.type,
    required this.title,
  });

  /// TODO 创建空数据。
  const PreferenceItem.empty()
    : id = 0,
      type = 0,
      title = '';

  /// TODO 从接口返回的单条 json 中解析业务对象。
  factory PreferenceItem.from_json(Map<String, dynamic> json) {
    return PreferenceItem(
      id: _to_int(json['id']),
      type: _to_int(json['type']),
      title: _to_string(json['title']),
    );
  }

  /// TODO 输出回 json，便于后续缓存或调试。
  Map<String, dynamic> to_json() {
    return <String, dynamic>{
      'id': id,
      'type': type,
      'title': title,
    };
  }
}

/// TODO 统一把动态值转换成 int。
int _to_int(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

/// TODO 统一把动态值转换成字符串。
String _to_string(dynamic value) {
  return value?.toString() ?? '';
}
