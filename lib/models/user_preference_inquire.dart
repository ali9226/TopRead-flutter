// ignore_for_file: non_constant_identifier_names

/* TODO
 * 用户偏好查询响应模型。
 *
 * 对应 `user_preference/user_inquire` 接口返回的数据。
 * 包含用户已选择的偏好选项 id 列表。
 */
class UserPreferenceInquire {
  /// TODO 用户已选择的偏好选项 id 列表。
  final List<int> ids;

  const UserPreferenceInquire({
    required this.ids,
  });

  /// TODO 创建空数据。
  const UserPreferenceInquire.empty() : ids = const [];

  /// TODO 从接口返回的 json 中解析业务对象。
  factory UserPreferenceInquire.from_json(Map<String, dynamic> json) {
    return UserPreferenceInquire(
      ids: _parse_ids(json['ids']),
    );
  }

  /// TODO 解析 id 列表，兼容各种类型。
  static List<int> _parse_ids(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<dynamic>()
        .map((dynamic item) => _to_int(item))
        .toList();
  }

  /// TODO 统一把动态值转换成 int。
  static int _to_int(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}
