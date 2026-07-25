// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/util/language_util/index.dart';

/// 推荐榜小说项模型。
///
/// 对应后端 `novel/recommend_ranking` 接口返回的单条小说记录。
/// 包含小说基本信息、多语种信息、分类列表、作者信息和当前用户是否喜欢。
class RecommendRankingItem {
  /// 小说ID。
  final int id;

  /// 发布状态：1=连载中, 2=已完结, 3=下架, 4=短篇。
  final int publish_status;

  /// 推荐状态：1=否, 2=是。
  final int recommend_status;

  /// 排序值（越大越靠前）。
  final int sorting;

  /// 阅读数。
  final int read_count;

  /// 评论数。
  final int comment_count;

  /// 点赞数。
  final int like_count;

  /// 收藏数。
  final int favorite_count;

  /// 评分。
  final double score;

  /// 该语种的标题。
  final String title;

  /// 内容URL。
  final String content_url;

  /// 封面URL。
  final String cover_url;

  /// 该语种的简介。
  final String introduction;

  /// 该语种总字数。
  final int word_count;

  /// 该语种章节数。
  final int chapter_count;

  /// 分类名称列表（当前语种下）。
  final List<String> category_list;

  /// 作者名称。
  final String author_name;

  /// 作者头像URL。
  final String author_avatar;

  /// 当前用户是否喜欢该小说。
  final bool like;

  const RecommendRankingItem({
    required this.id,
    required this.publish_status,
    required this.recommend_status,
    required this.sorting,
    required this.read_count,
    required this.comment_count,
    required this.like_count,
    required this.favorite_count,
    required this.score,
    required this.title,
    required this.content_url,
    required this.cover_url,
    required this.introduction,
    required this.word_count,
    required this.chapter_count,
    required this.category_list,
    required this.author_name,
    required this.author_avatar,
    required this.like,
  });

  /// 从接口返回的原始 json 解析单条推荐榜小说对象。
  ///
  /// 参数 [json]：
  /// 后端 `novel/recommend_ranking` 接口返回数组中的单条记录。
  factory RecommendRankingItem.from_json(Map<String, dynamic> json) {
    return RecommendRankingItem(
      id: _parse_int(json['id']),
      publish_status: _parse_int(json['publish_status']),
      recommend_status: _parse_int(json['recommend_status']),
      sorting: _parse_int(json['sorting']),
      read_count: _parse_int(json['read_count']),
      comment_count: _parse_int(json['comment_count']),
      like_count: _parse_int(json['like_count']),
      favorite_count: _parse_int(json['favorite_count']),
      score: _parse_double(json['score']),
      title: json['title'] as String? ?? '',
      content_url: json['content_url'] as String? ?? '',
      cover_url: json['cover_url'] as String? ?? '',
      introduction: json['introduction'] as String? ?? '',
      word_count: _parse_int(json['word_count']),
      chapter_count: _parse_int(json['chapter_count']),
      category_list: _parse_category_list(json['category_list']),
      author_name: json['author_name'] as String? ?? '',
      author_avatar: json['author_avatar'] as String? ?? '',
      like: json['like'] as bool? ?? false,
    );
  }

  /// 从 json 列表解析推荐榜小说对象列表。
  ///
  /// 参数 [raw]：
  /// 后端返回的 content 数组。
  static List<RecommendRankingItem> from_json_list(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (dynamic item) => RecommendRankingItem.from_json(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  /// 转换为 json 对象，用于本地缓存。
  Map<String, dynamic> to_json() {
    return <String, dynamic>{
      'id': id,
      'publish_status': publish_status,
      'recommend_status': recommend_status,
      'sorting': sorting,
      'read_count': read_count,
      'comment_count': comment_count,
      'like_count': like_count,
      'favorite_count': favorite_count,
      'score': score,
      'title': title,
      'content_url': content_url,
      'cover_url': cover_url,
      'introduction': introduction,
      'word_count': word_count,
      'chapter_count': chapter_count,
      'category_list': category_list,
      'author_name': author_name,
      'author_avatar': author_avatar,
      'like': like,
    };
  }

  /// 从缓存 json 列表解析推荐榜小说对象列表。
  ///
  /// 参数 [raw]：
  /// 本地缓存读取出的数组。
  static List<RecommendRankingItem> from_cache_list(List<dynamic> raw) {
    return raw
        .whereType<Map>()
        .map(
          (dynamic item) => RecommendRankingItem.from_json(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  /// 格式化阅读数展示文本（多语种）。
  ///
  /// 根据语种自动选择合适的单位和翻译模板：
  /// - CJK 语系：千/万/亿，如 `"8千阅读"`、`"1.2万阅读"`。
  /// - 非 CJK 语系：K/M，如 `"8K Reads"`、`"1.2M Reads"`。
  ///
  /// 参数 [language_code] 当前语种代码。
  /// 返回多语种格式化的阅读数文本。
  String formatted_read_count_for(String language_code) {
    return format_count_text(read_count, language_code);
  }

  /// 格式化数值展示文本（多语种）。
  ///
  /// 根据语种自动选择合适的单位和翻译模板：
  /// - >= 1亿：使用"亿"/"M"单位。
  /// - >= 1万：使用"万"/"K"单位。
  /// - >= 1千：使用"千"/"K"单位。
  /// - < 1千：显示原始数字。
  ///
  /// 参数 [count] 原始数值。
  /// 参数 [language_code] 当前语种代码。
  /// 返回多语种格式化的文本。
  static String format_count_text(int count, String language_code) {
    if (count <= 0) {
      return _tr_count('home.ranking_heat_text', 0);
    }

    final bool is_cjk = LanguageUtil.is_cjk_language(language_code);

    if (is_cjk) {
      // >= 1亿
      if (count >= 100000000) {
        final double yi = count / 100000000;
        return _tr_count(
          'home.ranking_count_yi_text',
          yi == yi.truncateToDouble() ? yi.toInt() : yi,
        );
      }
      // >= 1万
      if (count >= 10000) {
        final double wan = count / 10000;
        return _tr_count(
          'home.ranking_heat_text',
          wan == wan.truncateToDouble() ? wan.toInt() : wan,
        );
      }
      // >= 1千
      if (count >= 1000) {
        final double qian = count / 1000;
        return _tr_count(
          'home.ranking_count_thousand_text',
          qian == qian.truncateToDouble() ? qian.toInt() : qian,
        );
      }
      return _tr_count('home.ranking_heat_text', count);
    }

    // 非 CJK
    // >= 1M
    if (count >= 1000000) {
      final double m = count / 1000000;
      return _tr_count(
        'home.ranking_count_yi_text',
        m == m.truncateToDouble() ? m.toInt() : m,
      );
    }
    // >= 1K
    if (count >= 1000) {
      final double k = count / 1000;
      return _tr_count(
        'home.ranking_heat_text',
        k == k.truncateToDouble() ? k.toInt() : k,
      );
    }
    return _tr_count('home.ranking_heat_text', count);
  }

  /// 调用 i18n 翻译，自动格式化数值。
  ///
  /// 参数 [key] i18n 键名。
  /// 参数 [count] 数值（int 或 double）。
  static String _tr_count(String key, num count) {
    final String count_str = count is double
        ? count.toStringAsFixed(count == count.truncateToDouble() ? 0 : 1)
        : '$count';
    return easy.tr(key, namedArgs: <String, String>{'count': count_str});
  }

  /// 格式化分类展示文本。
  ///
  /// 将分类列表拼接为用 "·" 分隔的字符串。
  /// 返回示例：`"都市·悬疑"` 或空字符串。
  String get formatted_categories {
    if (category_list.isEmpty) return '';
    return category_list.join('·');
  }

  /// 安全解析 int 类型字段。
  ///
  /// 兼容后端返回数字或字符串的情况。
  static int _parse_int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  /// 安全解析 double 类型字段。
  ///
  /// 兼容后端返回数字或字符串的情况。
  static double _parse_double(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  /// 安全解析分类列表字段。
  ///
  /// 后端 category_list 是字符串数组，
  /// 但解密后可能变成 List<dynamic>，需要逐项转换。
  static List<String> _parse_category_list(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((dynamic item) => item?.toString() ?? '')
        .where((String s) => s.isNotEmpty)
        .toList();
  }
}
