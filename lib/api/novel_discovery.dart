// ignore_for_file: non_constant_identifier_names

import 'package:app/api/post_request.dart';
import 'package:app/models/novel_discovery.dart';

/// 复用小说现有加密、身份、语种请求管线；失败由页面原位重试处理。
Future<Map<String, dynamic>> _request(
  String action, [
  Map<String, dynamic> parameters = const {},
]) async {
  final result = await postRequest<Map<String, dynamic>>(
    path: 'novel/$action',
    parameter: parameters,
    showTips: false,
    fromJson: (json) => json,
  );
  if (!result.status) throw Exception(result.message);
  return result.content ?? {};
}

Future<NovelDiscoveryFeed> load_novel_home_sections({
  String? language,
  String? seed,
}) async => NovelDiscoveryFeed.from_json(
  await _request('home_sections', {
    if (language?.isNotEmpty == true) 'language': language,
    if (seed?.isNotEmpty == true) 'seed': seed,
  }),
);

Future<NovelDiscoverySection> shuffle_novel_category({
  required int category_id,
  required List<int> exclude_ids,
  List<int>? reserved_ids,
  String? seed,
  String? language,
}) async => NovelDiscoverySection.from_json(
  await _request('category_recommendations', {
    'category_id': category_id,
    'exclude_ids': exclude_ids.where((id) => id > 0).toSet().toList(),
    if (reserved_ids != null)
      'reserved_ids': reserved_ids.where((id) => id > 0).toSet().toList(),
    if (seed?.isNotEmpty == true) 'seed': seed,
    if (language?.isNotEmpty == true) 'language': language,
  }),
);

Future<List<Map<String, dynamic>>> load_novel_discovery_categories() async =>
    novel_discovery_maps((await _request('discovery_categories'))['list']);

Future<NovelDiscoveryPage> load_novel_discovery_page({
  required int category_id,
  int page = 1,
  int page_size = 24,
  String? seed,
  String? language,
}) async => NovelDiscoveryPage.from_json(
  await _request('discover', {
    'category_id': category_id,
    'page': page,
    'page_size': page_size,
    if (seed?.isNotEmpty == true) 'seed': seed,
    if (language?.isNotEmpty == true) 'language': language,
  }),
);
