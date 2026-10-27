// ignore_for_file: non_constant_identifier_names

import 'package:app/models/comics.dart';
import 'package:app/models/comics_discovery.dart';

import 'comics.dart';

Future<ComicDiscoveryFeed> load_comics_home_sections({
  String? language,
  String? seed,
}) async => ComicDiscoveryFeed.from_json(
  await comics_request('home_sections', {
    if (language?.isNotEmpty == true) 'language': language,
    if (seed?.isNotEmpty == true) 'seed': seed,
  }),
);

Future<ComicDiscoverySection> shuffle_comics_category({
  required int category_id,
  required List<int> exclude_ids,
  List<int>? reserved_ids,
  String? seed,
  String? language,
}) async => ComicDiscoverySection.from_json(
  await comics_request('category_recommendations', {
    'category_id': category_id,
    'exclude_ids': exclude_ids.where((id) => id > 0).toSet().toList(),
    if (reserved_ids != null)
      'reserved_ids': reserved_ids.where((id) => id > 0).toSet().toList(),
    if (language?.isNotEmpty == true) 'language': language,
    if (seed?.isNotEmpty == true) 'seed': seed,
  }),
);

Future<List<Map<String, dynamic>>> load_comics_discovery_categories() async =>
    comics_list(
      (await comics_request('categories', {'available_only': 1}))['list'],
    );

Future<ComicDiscoveryPage> load_comics_discovery_page({
  required int category_id,
  int page = 1,
  int page_size = 24,
  String? seed,
  String? language,
}) async => ComicDiscoveryPage.from_json(
  await comics_request('discover', {
    'category_id': category_id,
    'page': page,
    'page_size': page_size,
    if (seed?.isNotEmpty == true) 'seed': seed,
    if (language?.isNotEmpty == true) 'language': language,
  }),
);
