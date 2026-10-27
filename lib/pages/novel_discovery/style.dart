// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/comics/style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 分组发现与漫画使用同一主题令牌，分类翻译兼容小说既有的数组结构。
class NovelDiscoveryStyle {
  static const double content_width = ComicsStyle.content_width;
  static const double empty_cover_tint = 0.08;
  static bool is_dark(BuildContext context) => ComicsStyle.is_dark(context);
  static bool is_cjk(BuildContext context) => ComicsStyle.is_cjk(context);
  static Color ink(BuildContext context) => ComicsStyle.ink(context);
  static Color muted(BuildContext context) => ComicsStyle.muted(context);

  static String category_name(
    BuildContext context,
    Map<String, dynamic> category,
  ) {
    final translations = category['translations'];
    if (translations is List) {
      final language = context.locale.languageCode.toLowerCase();
      final full_language = context.locale.toLanguageTag().toLowerCase();
      final records = translations.whereType<Map>();
      for (final requested in [full_language, language, 'en']) {
        for (final record in records) {
          final code = (record['language'] ?? record['language_code'] ?? '')
              .toString()
              .replaceAll('_', '-')
              .toLowerCase();
          final name = (record['name'] ?? record['title'] ?? '').toString();
          if ((code == requested || code.split('-').first == requested) &&
              name.trim().isNotEmpty) {
            return name;
          }
        }
      }
    }
    return ComicsStyle.category_name(context, category);
  }
}
