// ignore_for_file: non_constant_identifier_names

class Rotation {
  /// 数据唯一 id。
  final int id;

  /// 业务类型。
  final int type;

  /// 标题。
  final String title;

  /// 排序值，值越大越靠前。
  final int sorting;

  /// 备注。
  final String note;

  /// 删除状态。
  final int remove_status;

  /// 图标地址。
  final String address;

  /// 跳转地址或账号。
  final String jump;

  /// 跳转类型。
  final int format;

  /// 描述字段。
  final String represent;

  /// 所属语种。
  final String language;

  /// 点击次数。
  final int clicks_number;

  /// 语种 id。
  final int language_id;

  /// 语种代码。
  final String language_code;

  const Rotation({
    required this.id,
    required this.type,
    required this.title,
    required this.sorting,
    required this.note,
    required this.remove_status,
    required this.address,
    required this.jump,
    required this.format,
    required this.represent,
    required this.language,
    required this.clicks_number,
    required this.language_id,
    required this.language_code,
  });

  /// 创建空数据，避免外部判空分支过多。
  const Rotation.empty()
    : id = 0,
      type = 0,
      title = '',
      sorting = 0,
      note = '',
      remove_status = 0,
      address = '',
      jump = '',
      format = 0,
      represent = '',
      language = '',
      clicks_number = 0,
      language_id = 0,
      language_code = '';

  /// 从接口返回的单条 json 中解析业务对象。
  factory Rotation.from_json(Map<String, dynamic> json) {
    return Rotation(
      id: _to_int(json['id']),
      type: _to_int(json['type']),
      title: _to_string(json['title']),
      sorting: _to_int(json['sorting']),
      note: _to_string(json['note']),
      remove_status: _to_int(json['remove_status'], 1),
      address: _to_string(json['address']),
      jump: _to_string(json['jump']),
      format: _to_int(json['format']),
      represent: _to_string(json['represent']),
      language: _to_string(json['language']),
      clicks_number: _to_int(json['clicks_number']),
      language_id: _to_int(json['language_id']),
      language_code: _to_string(json['language_code']),
    );
  }

  /// 批量解析接口返回数组。
  static List<Rotation> from_json_list(List<dynamic> json_list) {
    return json_list
        .whereType<Map>()
        .map(
          (dynamic item) => Rotation.from_json(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  /// 输出回 json，便于后续缓存或调试。
  Map<String, dynamic> to_json() {
    return <String, dynamic>{
      'id': id,
      'type': type,
      'title': title,
      'sorting': sorting,
      'note': note,
      'remove_status': remove_status,
      'address': address,
      'jump': jump,
      'format': format,
      'represent': represent,
      'language': language,
      'clicks_number': clicks_number,
      'language_id': language_id,
      'language_code': language_code,
    };
  }
}

/// 统一把动态值转换成 int。
int _to_int(dynamic value, [int fallback = 0]) {
  if (value == null) {
    return fallback;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString()) ?? fallback;
}

/// 统一把动态值转换成字符串。
String _to_string(dynamic value) {
  return value?.toString() ?? '';
}
