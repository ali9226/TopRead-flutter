// ignore_for_file: non_constant_identifier_names

import 'package:app/api/comics.dart';
import 'package:app/api/post_request.dart';
import 'package:app/models/recommend_ranking_item.dart';
import 'package:app/models/work_search.dart';

/// 小说继续使用原搜索接口和 no_ids 分页，保留短篇的发布状态。
Future<List<RecommendRankingItem>> search_novels({
  required String keyword,
  required int limit,
  required List<int> no_ids,
}) async {
  final result = await postRequest<List<RecommendRankingItem>>(
    path: 'novel_search/search',
    showTips: false,
    parameter: {'keyword': keyword, 'limit': limit, 'no_ids': no_ids},
    fromJsonList: RecommendRankingItem.from_json_list,
  );
  if (!result.status) throw Exception(result.message);
  return result.content ?? [];
}

/// 复用公开漫画查询；必须显式传语种代码，language_id 属于小说接口。
Future<ComicSearchPage> search_comics({
  required String keyword,
  required int page,
  required int page_size,
  required String language,
}) async => ComicSearchPage.from_json(
  await comics_request('inquire', {
    'keyword': keyword,
    'page': page,
    'page_size': page_size,
    'language': language,
  }),
);
