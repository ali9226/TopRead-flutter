// ignore_for_file: non_constant_identifier_names

import 'package:app/models/comics.dart';
import 'package:app/models/recommend_ranking_item.dart';

/// 搜索结果保留原始作品类型，避免小说与漫画相同的数字编号互相覆盖。
class SearchResultItem {
  const SearchResultItem.novel(RecommendRankingItem item)
    : novel = item,
      comic = null;

  const SearchResultItem.comic(ComicItem item) : novel = null, comic = item;

  final RecommendRankingItem? novel;
  final ComicItem? comic;

  bool get is_comic => comic != null;
  int get work_id => comic?.id ?? novel!.id;
  String get id => '${is_comic ? 'comic' : 'novel'}_$work_id';
  String get title => comic?.title ?? novel!.title;
}

/// 漫画接口使用页码与总数，独立于小说通过排除编号实现的分页。
class ComicSearchPage {
  const ComicSearchPage({required this.items, required this.total});

  final List<ComicItem> items;
  final int total;

  factory ComicSearchPage.from_json(Map<String, dynamic> json) =>
      ComicSearchPage(
        items: comics_list(json['list']).map(ComicItem.from_json).toList(),
        total: comics_int(json['total']),
      );
}
