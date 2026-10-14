// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';

import 'package:app/models/comics.dart';
import 'package:app/models/preference.dart';
import 'package:app/pages/comics/style.dart';

/// 首页漫画 Tab 的分类适配逻辑。
///
/// 把漫画分类（含多语种翻译）转换成 [CategoryFilter] 所需的
/// [PreferenceItem] 列表，并提供筛选条件到分页参数的映射。
class ComicsTabLogic {
  /// 将漫画分类原始数据转换为筛选组件使用的 [PreferenceItem] 列表。
  ///
  /// [context] 用于按当前语种解析分类名称。
  /// [categories] 接口 `comics/categories` 返回的分类原始列表。
  static List<PreferenceItem> to_preference_items(
    BuildContext context,
    List<Map<String, dynamic>> categories,
  ) {
    return categories
        .map(
          (Map<String, dynamic> category) => PreferenceItem(
            id: comics_int(category['id']),
            type: 0,
            title: ComicsStyle.category_name(context, category),
          ),
        )
        .toList();
  }

  /// 将筛选组件回调的分类 id 映射为分页接口的 category_id。
  ///
  /// null 表示未选中（全部），映射为 0 表示不传分类过滤。
  /// [category_id] 筛选组件回调值。
  static int to_filter_category_id(int? category_id) => category_id ?? 0;
}
