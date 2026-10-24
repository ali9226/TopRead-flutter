// ignore_for_file: non_constant_identifier_names

import 'package:app/models/short_story_item.dart';

/// 详情接口没有作者字段时，沿用同篇目录里的真实作者，不虚构占位作者。
String resolve_short_story_author_name(
  Iterable<ShortStoryItem> catalog_entries,
  int story_id,
) {
  for (final entry in catalog_entries) {
    if (entry.id == story_id) return entry.author_name.trim();
  }
  return '';
}
