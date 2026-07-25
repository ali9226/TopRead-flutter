// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';

/* TODO
 * 语种数据模型。
 *
 * 对应 `language_list/inquire` 接口返回的单条语种记录。
 */
class LanguageInfo {
  /// TODO 语种唯一 id。
  final int id;

  /// TODO 语种名称。
  final String title;

  /// TODO 语种代码。
  final String code;

  /// TODO 是否已删除。
  final int remove_status;

  /// TODO 备注。
  final String remark;

  /// TODO 更新时间。
  final String update_time;

  /// TODO 排序值。
  final int sorting;

  /// TODO 是否默认语种：1 否，2 是。
  final int default_language;

  /// TODO 图标地址。
  final String icon;

  /// TODO 所属国家。
  final String country;

  /// TODO 简拼。
  final String logogram;

  /// TODO 手机区号。
  final String phone_code;

  /// TODO 是否展示：1 展示，2 不展示。
  final int show_status;

  const LanguageInfo({
    this.id = 0,
    this.title = '',
    this.code = '',
    this.remove_status = 0,
    this.remark = '',
    this.update_time = '',
    this.sorting = 0,
    this.default_language = 1,
    this.icon = '',
    this.country = '',
    this.logogram = '',
    this.phone_code = '',
    this.show_status = 1,
  });

  /// TODO 当前语种是否为默认语种。
  bool get is_default_language => default_language == 2;

  /// TODO 当前语种是否允许展示。
  bool get can_show => show_status == 1 && !is_removed;

  /// TODO 当前语种是否已删除。
  bool get is_removed => remove_status == 2;

  /// TODO 归一化后的语种代码。
  ///
  /// 例如：
  /// - `en-US` => `en`
  /// - `zh_CN` => `zh`
  String get language_code {
    final String normalized_code = code.trim().toLowerCase();
    if (normalized_code.isEmpty) {
      return '';
    }

    final String separator = normalized_code.contains('-') ? '-' : '_';
    return normalized_code.split(separator).first;
  }

  /// TODO 转成 Flutter `Locale`。
  Locale get locale => Locale(language_code);

  /// TODO 解析接口原始 json。
  factory LanguageInfo.from_json(Map<String, dynamic> json) {
    return LanguageInfo(
      id: _parse_int(json['id']),
      title: json['title']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      remove_status: _parse_int(json['remove_status']),
      remark: json['remark']?.toString() ?? '',
      update_time: json['update_time']?.toString() ?? '',
      sorting: _parse_int(json['sorting']),
      default_language: _parse_int(json['default_language'], 1),
      icon: json['icon']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      logogram: json['logogram']?.toString() ?? '',
      phone_code: json['phone_code']?.toString() ?? '',
      show_status: _parse_int(json['show_status'], 1),
    );
  }

  Map<String, dynamic> to_json() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'code': code,
      'remove_status': remove_status,
      'remark': remark,
      'update_time': update_time,
      'sorting': sorting,
      'default_language': default_language,
      'icon': icon,
      'country': country,
      'logogram': logogram,
      'phone_code': phone_code,
      'show_status': show_status,
    };
  }

  static int _parse_int(dynamic value, [int fallback = 0]) {
    if (value == null) {
      return fallback;
    }
    if (value is int) {
      return value;
    }
    return int.tryParse(value.toString()) ?? fallback;
  }
}

/* TODO
 * 语种列表响应模型。
 *
 * 统一负责把接口返回数组转换成强类型列表。
 */
class LanguageInfoListResponse {
  /// TODO 语种列表。
  final List<LanguageInfo> list;

  const LanguageInfoListResponse({required this.list});

  /// TODO 从数组解析语种列表。
  factory LanguageInfoListResponse.from_json_list(List<dynamic> json) {
    return LanguageInfoListResponse(
      list: json
          .whereType<Map>()
          .map(
            (dynamic item) =>
                LanguageInfo.from_json(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }
}
