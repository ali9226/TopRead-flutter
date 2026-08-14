// ignore_for_file: non_constant_identifier_names

import 'package:app/models/language_info.dart';
import 'package:app/models/rotation.dart';
import 'package:app/models/preference.dart';
import 'package:app/models/home_classification.dart';
import 'package:app/models/popular_search_item.dart';
import 'package:app/models/project_config.dart';

/* TODO
 * redis/get 接口返回的 content 数据模型。
 *
 * 统一封装语种列表、旋转列表、偏好列表、首页分类四大板块，
 * 由 RedisRequestStore 调用 from_json 一次性解析完成。
 */
class RedisGetData {
  /// 语种列表。
  final List<LanguageInfo> language_list;

  /// 旋转列表（含轮播图、客服、第三方授权等类型）。
  final List<Rotation> rotation_list;

  /// 偏好列表（含性别、内容、完结、篇幅等分类）。
  final List<Preference> preference_list;

  /// 首页分类列表。
  final List<HomeClassification> home_classification_list;

  /// 榜单分类列表。
  final List<HomeClassification> rankings;

  /// 搜索栏轮播关键词列表。
  final List<HomeClassification> search_list;

  /// 不喜欢理由列表。
  final List<HomeClassification> dislike_list;

  /// 热门搜索标签列表。
  final List<PopularSearchItem> popular_searches;

  /// 项目配置。
  final ProjectConfig project_config;

  const RedisGetData({
    required this.language_list,
    required this.rotation_list,
    required this.preference_list,
    required this.home_classification_list,
    required this.rankings,
    required this.search_list,
    required this.dislike_list,
    required this.popular_searches,
    required this.project_config,
  });

  /// TODO 空数据兜底。
  const RedisGetData.empty()
    : language_list = const [],
      rotation_list = const [],
      preference_list = const [],
      home_classification_list = const [],
      rankings = const [],
      search_list = const [],
      dislike_list = const [],
      popular_searches = const [],
      project_config = const ProjectConfig.empty();

  /// TODO 从接口返回的原始 json 中解析业务对象。
  ///
  /// 参数 [json]：
  /// `redis/get` 的 `content` 数据体。
  factory RedisGetData.from_json(Map<String, dynamic> json) {
    return RedisGetData(
      language_list: _parse_language_list(json['language_list']),
      rotation_list: _parse_rotation_list(json['rotation_list']),
      preference_list: _parse_preference_list(json['preference_list']),
      home_classification_list: _parse_home_classification_list(
        json['home_classification'],
      ),
      rankings: _parse_rankings(json['rankings']),
      search_list: _parse_search_list(json['search_list']),
      dislike_list: _parse_dislike_list(json['dislike_list']),
      popular_searches: _parse_popular_searches(json['popular_searches']),
      project_config: _parse_project_config(json['project_config']),
    );
  }

  /// TODO 解析语种列表。
  static List<LanguageInfo> _parse_language_list(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (dynamic item) =>
              LanguageInfo.from_json(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  /// TODO 解析旋转列表。
  static List<Rotation> _parse_rotation_list(dynamic raw) {
    if (raw is! List) return const [];
    return Rotation.from_json_list(raw);
  }

  /// TODO 解析偏好列表。
  static List<Preference> _parse_preference_list(dynamic raw) {
    if (raw is! List) return const [];
    return Preference.from_json_list(raw);
  }

  /// TODO 解析首页分类列表。
  static List<HomeClassification> _parse_home_classification_list(
    dynamic raw,
  ) {
    if (raw is! List) return const [];
    return HomeClassification.from_json_list(raw);
  }

  /// TODO 解析榜单分类列表。
  static List<HomeClassification> _parse_rankings(dynamic raw) {
    if (raw is! List) return const [];
    return HomeClassification.from_json_list(raw);
  }

  /// TODO 解析搜索栏轮播关键词列表。
  static List<HomeClassification> _parse_search_list(dynamic raw) {
    if (raw is! List) return const [];
    return HomeClassification.from_json_list(raw);
  }

  /// TODO 解析不喜欢理由列表。
  static List<HomeClassification> _parse_dislike_list(dynamic raw) {
    if (raw is! List) return const [];
    return HomeClassification.from_json_list(raw);
  }

  /// TODO 解析热门搜索标签列表。
  static List<PopularSearchItem> _parse_popular_searches(dynamic raw) {
    if (raw is! List) return const [];
    return PopularSearchItem.from_json_list(raw);
  }

  /// TODO 解析项目配置。
  static ProjectConfig _parse_project_config(dynamic raw) {
    if (raw is! Map) return const ProjectConfig.empty();
    return ProjectConfig.from_json(Map<String, dynamic>.from(raw));
  }
}
