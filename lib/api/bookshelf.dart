// ignore_for_file: non_constant_identifier_names

import 'package:flutter/foundation.dart';
import 'package:app/api/post_request.dart';
import 'package:app/api/results_type.dart';
import 'package:app/config/constant.dart';
import 'package:app/util/storage_util/index.dart';

/// 阅读历史项数据模型。
class ReadRecordItem {
  /// 阅读记录ID。
  final String id;

  /// 小说ID。
  final String novel_id;

  /// 语种版本ID。
  final String novel_language_id;

  /// 章节ID。
  final String? chapter_id;

  /// 阅读时长（秒）。
  final int read_duration;

  /// 阅读进度百分比。
  final double read_progress;

  /// 阅读时间。
  final String create_time;

  /// 小说标题。
  final String novel_title;

  /// 发布状态。
  final int publish_status;

  /// 作者ID。
  final String author_id;

  /// 作者名称。
  final String author_name;

  /// 作者头像。
  final String author_avatar;

  /// 语种标题。
  final String language_title;

  /// 小说简介。
  final String introduction;

  /// 封面URL。
  final String cover_url;

  /// 封面原始宽度。
  final int cover_width;

  /// 封面原始高度。
  final int cover_height;

  /// 章节数。
  final int chapter_count;

  /// 分类名称（逗号分隔）。
  final String category_names;

  ReadRecordItem({
    required this.id,
    required this.novel_id,
    required this.novel_language_id,
    this.chapter_id,
    required this.read_duration,
    required this.read_progress,
    required this.create_time,
    required this.novel_title,
    required this.publish_status,
    required this.author_id,
    required this.author_name,
    required this.author_avatar,
    required this.language_title,
    required this.introduction,
    required this.cover_url,
    this.cover_width = 0,
    this.cover_height = 0,
    required this.chapter_count,
    required this.category_names,
  });

  factory ReadRecordItem.from_json(Map<String, dynamic> json) {
    return ReadRecordItem(
      id: json['id']?.toString() ?? '',
      novel_id: json['novel_id']?.toString() ?? '',
      novel_language_id: json['novel_language_id']?.toString() ?? '',
      chapter_id: json['chapter_id']?.toString(),
      read_duration: _parse_int(json['read_duration']),
      read_progress: _parse_double(json['read_progress']),
      create_time: json['create_time']?.toString() ?? '',
      novel_title: json['novel_title']?.toString() ?? '',
      publish_status: _parse_int(json['publish_status']),
      author_id: json['author_id']?.toString() ?? '',
      author_name: json['author_name']?.toString() ?? '',
      author_avatar: json['author_avatar']?.toString() ?? '',
      language_title: json['language_title']?.toString() ?? '',
      introduction: json['introduction']?.toString() ?? '',
      cover_url: json['cover_url']?.toString() ?? '',
      cover_width: _parse_int(json['cover_width']),
      cover_height: _parse_int(json['cover_height']),
      chapter_count: _parse_int(json['chapter_count']),
      category_names: json['category_names']?.toString() ?? '',
    );
  }

  static int _parse_int(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _parse_double(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}

/// 收藏小说项数据模型。
class FavoriteItem {
  /// 收藏记录ID。
  final String id;

  /// 小说ID。
  final String novel_id;

  /// 收藏时间。
  final String favorite_time;

  /// 小说标题。
  final String novel_title;

  /// 副标题。
  final String subtitle;

  /// 发布状态。
  final int publish_status;

  /// 作者ID。
  final String author_id;

  /// 作者名称。
  final String author_name;

  /// 作者头像。
  final String author_avatar;

  /// 评分。
  final double score;

  /// 阅读数。
  final int read_count;

  /// 点赞数。
  final int like_count;

  /// 收藏数。
  final int favorite_count;

  /// 最新章节号。
  final int latest_chapter_no;

  /// 最新更新时间。
  final String latest_update_time;

  /// 封面URL。
  final String cover_url;

  /// 封面原始宽度。
  final int cover_width;

  /// 封面原始高度。
  final int cover_height;

  /// 章节数。
  final int chapter_count;

  /// 简介。
  final String introduction;

  /// 阅读进度百分比。
  final double read_progress;

  /// 分类名称（逗号分隔）。
  final String category_names;

  FavoriteItem({
    required this.id,
    required this.novel_id,
    required this.favorite_time,
    required this.novel_title,
    required this.subtitle,
    required this.publish_status,
    required this.author_id,
    required this.author_name,
    required this.author_avatar,
    required this.score,
    required this.read_count,
    required this.like_count,
    required this.favorite_count,
    required this.latest_chapter_no,
    required this.latest_update_time,
    required this.cover_url,
    this.cover_width = 0,
    this.cover_height = 0,
    required this.chapter_count,
    required this.introduction,
    required this.read_progress,
    required this.category_names,
  });

  factory FavoriteItem.from_json(Map<String, dynamic> json) {
    return FavoriteItem(
      id: json['id']?.toString() ?? '',
      novel_id: json['novel_id']?.toString() ?? '',
      favorite_time: json['favorite_time']?.toString() ?? '',
      novel_title: json['novel_title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      publish_status: _parse_int(json['publish_status']),
      author_id: json['author_id']?.toString() ?? '',
      author_name: json['author_name']?.toString() ?? '',
      author_avatar: json['author_avatar']?.toString() ?? '',
      score: _parse_double(json['score']),
      read_count: _parse_int(json['read_count']),
      like_count: _parse_int(json['like_count']),
      favorite_count: _parse_int(json['favorite_count']),
      latest_chapter_no: _parse_int(json['latest_chapter_no']),
      latest_update_time: json['latest_update_time']?.toString() ?? '',
      cover_url: json['cover_url']?.toString() ?? '',
      cover_width: _parse_int(json['cover_width']),
      cover_height: _parse_int(json['cover_height']),
      chapter_count: _parse_int(json['chapter_count']),
      introduction: json['introduction']?.toString() ?? '',
      read_progress: _parse_double(json['read_progress']),
      category_names: json['category_names']?.toString() ?? '',
    );
  }

  static int _parse_int(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _parse_double(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}

/// 关注作者项数据模型。
class FocusAuthorItem {
  /// 关注记录ID。
  final String id;

  /// 作者ID。
  final String author_id;

  /// 作者名称。
  final String author_name;

  /// 作者头像。
  final String author_avatar;

  /// 作者作品数量。
  final int novel_count;

  /// 关注时间。
  final String creation_time;

  FocusAuthorItem({
    required this.id,
    required this.author_id,
    required this.author_name,
    required this.author_avatar,
    required this.novel_count,
    required this.creation_time,
  });

  factory FocusAuthorItem.from_json(Map<String, dynamic> json) {
    return FocusAuthorItem(
      id: json['id']?.toString() ?? '',
      author_id: json['author_id']?.toString() ?? '',
      author_name: json['author_name']?.toString() ?? '',
      author_avatar: json['author_avatar']?.toString() ?? '',
      novel_count: _parse_int(json['novel_count']),
      creation_time: json['creation_time']?.toString() ?? '',
    );
  }

  static int _parse_int(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}

/// 通用分页列表结果。
class BookshelfListResult<T> {
  /// 数据列表。
  final List<T> list;

  /// 总数。
  final int total;

  /// 当前页码。
  final int page;

  /// 每页数量。
  final int page_size;

  const BookshelfListResult({
    required this.list,
    required this.total,
    required this.page,
    required this.page_size,
  });
}

/// 查询用户阅读历史列表。
///
/// [page] 页码，默认1。
/// [page_size] 每页数量，默认20。
Future<BookshelfListResult<ReadRecordItem>?> inquire_read_record_list({
  int page = 1,
  int page_size = 20,
}) async {
  final ResultsType<Map<String, dynamic>> results =
      await postRequest<Map<String, dynamic>>(
        path: 'novel_read_record/inquire',
        parameter: {'page': page, 'page_size': page_size},
        showTips: false,
        fromJson: (json) => json,
      );

  if (!results.status || results.content == null) {
    debugPrint(
      'TODO inquire_read_record_list 失败: status=${results.status}, message=${results.message}',
    );
    return null;
  }

  final Map<String, dynamic> data = results.content!;
  final List<dynamic> raw_list = data['list'] ?? [];
  return BookshelfListResult<ReadRecordItem>(
    list: raw_list
        .map((e) => ReadRecordItem.from_json(Map<String, dynamic>.from(e)))
        .toList(),
    total: _parse_int(data['total']),
    page: _parse_int(data['page']),
    page_size: _parse_int(data['page_size']),
  );
}

/// 查询用户收藏小说列表。
///
/// [page] 页码，默认1。
/// [page_size] 每页数量，默认20。
Future<BookshelfListResult<FavoriteItem>?> inquire_favorite_list({
  int page = 1,
  int page_size = 20,
}) async {
  final ResultsType<Map<String, dynamic>> results =
      await postRequest<Map<String, dynamic>>(
        path: 'novel_favorite/inquire',
        parameter: {'page': page, 'page_size': page_size},
        showTips: false,
        fromJson: (json) => json,
      );

  if (!results.status || results.content == null) {
    debugPrint(
      'TODO inquire_favorite_list 失败: status=${results.status}, message=${results.message}',
    );
    return null;
  }

  final Map<String, dynamic> data = results.content!;
  final List<dynamic> raw_list = data['list'] ?? [];
  return BookshelfListResult<FavoriteItem>(
    list: raw_list
        .map((e) => FavoriteItem.from_json(Map<String, dynamic>.from(e)))
        .toList(),
    total: _parse_int(data['total']),
    page: _parse_int(data['page']),
    page_size: _parse_int(data['page_size']),
  );
}

/// 查询用户关注的作者列表。
///
/// [page] 页码，默认1。
/// [page_size] 每页数量，默认20。
Future<BookshelfListResult<FocusAuthorItem>?> inquire_focus_author_list({
  int page = 1,
  int page_size = 20,
}) async {
  final ResultsType<Map<String, dynamic>> results =
      await postRequest<Map<String, dynamic>>(
        path: 'novel_focus_on/inquire',
        parameter: {'page': page, 'page_size': page_size},
        showTips: false,
        fromJson: (json) => json,
      );

  if (!results.status || results.content == null) {
    debugPrint(
      'TODO inquire_focus_author_list 失败: status=${results.status}, message=${results.message}',
    );
    return null;
  }

  final Map<String, dynamic> data = results.content!;
  final List<dynamic> raw_list = data['list'] ?? [];
  return BookshelfListResult<FocusAuthorItem>(
    list: raw_list
        .map((e) => FocusAuthorItem.from_json(Map<String, dynamic>.from(e)))
        .toList(),
    total: _parse_int(data['total']),
    page: _parse_int(data['page']),
    page_size: _parse_int(data['page_size']),
  );
}

/// 关注/取消关注作者结果模型。
class FocusToggleResult {
  /// 当前关注状态。
  final bool focus;

  const FocusToggleResult({required this.focus});

  factory FocusToggleResult.from_json(Map<String, dynamic> json) {
    return FocusToggleResult(
      focus: json['focus'] == true || json['focus'] == 1,
    );
  }
}

/// 关注/取消关注作者接口。
///
/// [author_id] 作者ID（必传）。
/// 返回关注结果（包含最新关注状态），失败时返回 null。
Future<FocusToggleResult?> toggle_focus_author({required int author_id}) async {
  final ResultsType<Map<String, dynamic>> results =
      await postRequest<Map<String, dynamic>>(
        path: 'novel_focus_on/click',
        parameter: {'author_id': author_id},
        showTips: true,
        fromJson: (json) => json,
      );

  if (!results.status || results.content == null) {
    debugPrint(
      'TODO toggle_focus_author 失败: status=${results.status}, message=${results.message}',
    );
    return null;
  }
  return FocusToggleResult.from_json(results.content!);
}

/// 幂等取消关注作者接口。
///
/// [author_id] 作者ID（必传）。
/// 返回服务端是否确认当前为未关注状态。
Future<bool> remove_focus_author({required int author_id}) async {
  if (author_id <= 0) return false;

  final ResultsType<Map<String, dynamic>> results =
      await postRequest<Map<String, dynamic>>(
        path: 'novel_focus_on/remove',
        parameter: <String, dynamic>{'author_id': author_id},
        showTips: true,
        fromJson: (Map<String, dynamic> json) => json,
      );
  if (!results.status || results.content == null) return false;
  final dynamic focus = results.content!['focus'];
  return focus == false || focus == 0;
}

/// 最后阅读记录数据模型。
class LastReadRecord {
  /// 章节ID。
  final int chapter_id;

  /// 章节内滚动偏移量。
  final int chapter_offset;

  /// 阅读进度百分比。
  final double read_progress;

  /// 语种版本ID。
  final int novel_language_id;

  const LastReadRecord({
    required this.chapter_id,
    required this.chapter_offset,
    required this.read_progress,
    required this.novel_language_id,
  });

  factory LastReadRecord.from_json(Map<String, dynamic> json) {
    return LastReadRecord(
      chapter_id: _parse_int(json['chapter_id']),
      chapter_offset: _parse_int(json['chapter_offset']),
      read_progress: _parse_double(json['read_progress']),
      novel_language_id: _parse_int(json['novel_language_id']),
    );
  }
}

/// 保存阅读进度接口。
///
/// [novel_id] 小说ID（必传）。
/// [novel_language_id] 语种版本ID（可选）。
/// [chapter_id] 章节ID（可选）。
/// [chapter_offset] 章节内滚动偏移量（可选）。
/// [read_progress] 阅读进度百分比（可选）。
/// 返回是否保存成功。
Future<bool> save_read_progress({
  required int novel_id,
  int? novel_language_id,
  int? chapter_id,
  int chapter_offset = 0,
  double read_progress = 0,
}) async {
  final ResultsType<Map<String, dynamic>> results =
      await postRequest<Map<String, dynamic>>(
        path: 'novel_read_record/save_progress',
        parameter: {
          'novel_id': novel_id,
          if (novel_language_id != null) 'novel_language_id': novel_language_id,
          if (chapter_id != null) 'chapter_id': chapter_id,
          'chapter_offset': chapter_offset,
          'read_progress': read_progress,
        },
        showTips: false,
        fromJson: (json) => json,
      );

  return results.status;
}

/// 删除当前用户指定小说的阅读记录。
Future<bool> remove_read_record({required int novel_id}) async {
  if (novel_id <= 0) return false;

  final ResultsType<Map<String, dynamic>> results =
      await postRequest<Map<String, dynamic>>(
        path: 'novel_read_record/remove',
        parameter: <String, dynamic>{'novel_id': novel_id},
        showTips: true,
        fromJson: (Map<String, dynamic> json) => json,
      );
  return results.status && results.content?['removed'] == true;
}

/// 查询用户对指定小说的最后阅读记录。
///
/// [novel_id] 小说ID（必传）。
/// 返回最后阅读记录，未登录或失败时返回 null。
Future<LastReadRecord?> get_last_read_record({required int novel_id}) async {
  // 未登录不请求接口
  final token = await StorageUtil.getData(Constant.tokenKey);
  if (token == null || token.isEmpty) return null;

  final ResultsType<Map<String, dynamic>> results =
      await postRequest<Map<String, dynamic>>(
        path: 'novel_read_record/get_last_record',
        parameter: {'novel_id': novel_id},
        showTips: false,
        fromJson: (json) => json,
      );

  if (!results.status || results.content == null) {
    return null;
  }

  final record = results.content!['record'];
  if (record == null) return null;

  return LastReadRecord.from_json(Map<String, dynamic>.from(record));
}

/// 收藏/取消收藏结果模型。
class FavoriteToggleResult {
  /// 当前收藏状态。
  final bool favorite;

  const FavoriteToggleResult({required this.favorite});

  factory FavoriteToggleResult.from_json(Map<String, dynamic> json) {
    return FavoriteToggleResult(
      favorite: json['favorite'] == true || json['favorite'] == 1,
    );
  }
}

/// 收藏/取消收藏小说接口。
///
/// [novel_id] 小说ID（必传）。
/// 返回收藏结果（包含最新收藏状态），失败时返回 null。
Future<FavoriteToggleResult?> toggle_favorite({required int novel_id}) async {
  final ResultsType<Map<String, dynamic>> results =
      await postRequest<Map<String, dynamic>>(
        path: 'novel_favorite/click',
        parameter: {'novel_id': novel_id},
        showTips: true,
        fromJson: (json) => json,
      );

  if (!results.status || results.content == null) {
    debugPrint(
      'TODO toggle_favorite 失败: status=${results.status}, message=${results.message}',
    );
    return null;
  }
  return FavoriteToggleResult.from_json(results.content!);
}

/// 幂等取消收藏小说接口。
Future<bool> remove_favorite({required int novel_id}) async {
  if (novel_id <= 0) return false;

  final ResultsType<Map<String, dynamic>> results =
      await postRequest<Map<String, dynamic>>(
        path: 'novel_favorite/remove',
        parameter: <String, dynamic>{'novel_id': novel_id},
        showTips: true,
        fromJson: (Map<String, dynamic> json) => json,
      );
  if (!results.status || results.content == null) return false;
  final dynamic favorite = results.content!['favorite'];
  return favorite == false || favorite == 0;
}

/// 解析整数，兼容字符串和数字类型。
int _parse_int(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  return int.tryParse(value.toString()) ?? 0;
}

/// 解析浮点数，兼容字符串和数字类型。
double _parse_double(dynamic value) {
  if (value == null) return 0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}
