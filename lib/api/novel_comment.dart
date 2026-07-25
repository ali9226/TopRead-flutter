// ignore_for_file: non_constant_identifier_names

import 'package:flutter/foundation.dart';
import 'package:app/api/post_request.dart';
import 'package:app/api/results_type.dart';
import 'package:app/components/comment_list/models/comment_data.dart';

/// 评论接口数据模型。
///
/// 包含评论列表和分页信息。
class CommentListResult {
  /// 评论列表。
  final List<CommentData> list;

  /// 总评论数。
  final int total;

  /// 当前页码。
  final int page;

  /// 每页数量。
  final int page_size;

  const CommentListResult({
    required this.list,
    required this.total,
    required this.page,
    required this.page_size,
  });

  /// 从后端接口返回的 JSON 数据解析。
  factory CommentListResult.from_json(Map<String, dynamic> json) {
    final List<dynamic> raw_list = json['list'] ?? [];
    return CommentListResult(
      list: raw_list
          .map((e) => CommentData.from_json(Map<String, dynamic>.from(e)))
          .toList(),
      total: _parse_int(json['total']),
      page: _parse_int(json['page']),
      page_size: _parse_int(json['page_size']),
    );
  }

  /// 解析整数，兼容字符串和数字类型。
  static int _parse_int(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}

/// 评论点赞结果模型。
class CommentLikeResult {
  /// 当前点赞状态。
  final bool like;

  /// 更新后的点赞数。
  final int like_count;

  const CommentLikeResult({
    required this.like,
    required this.like_count,
  });

  /// 从后端接口返回的 JSON 数据解析。
  factory CommentLikeResult.from_json(Map<String, dynamic> json) {
    return CommentLikeResult(
      like: json['like'] == true || json['like'] == 1,
      like_count: _parse_int(json['like_count']),
    );
  }

  /// 解析整数，兼容字符串和数字类型。
  static int _parse_int(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}

/// 查询评论列表接口。
///
/// [novel_id] 小说ID（必传）。
/// [page] 页码，默认1。
/// [page_size] 每页数量，默认20。
/// [highlight_id] 高亮评论ID（可选，后端将其顶层父评论排到第一位）。
/// 返回评论列表结果，失败时返回 null。
Future<CommentListResult?> inquire_comment_list({
  required int novel_id,
  int page = 1,
  int page_size = 20,
  int highlight_id = 0,
}) async {
  final Map<String, dynamic> parameter = {
    'novel_id': novel_id,
    'page': page,
    'page_size': page_size,
  };
  if (highlight_id > 0) parameter['highlight_id'] = highlight_id;

  final ResultsType<Map<String, dynamic>> results = await postRequest<Map<String, dynamic>>(
    path: 'novel_comment/inquire',
    parameter: parameter,
    showTips: false,
    fromJson: (json) => json,
  );

  if (!results.status || results.content == null) {
    debugPrint('TODO inquire_comment_list 失败: status=${results.status}, message=${results.message}, content=${results.content}');
    return null;
  }
  debugPrint('TODO inquire_comment_list content: ${results.content}');
  return CommentListResult.from_json(results.content!);
}

/// 发送评论接口（包括回复评论）。
///
/// [novel_id] 小说ID（必传）。
/// [comment_content] 评论内容（必传）。
/// [parent_id] 父评论ID（可选，0=顶层评论，>0=回复某条评论）。
/// 返回是否成功（Flutter 端乐观更新，不需要返回评论数据）。
Future<bool> add_comment({
  required int novel_id,
  required String comment_content,
  int parent_id = 0,
}) async {
  final ResultsType<Map<String, dynamic>> results = await postRequest<Map<String, dynamic>>(
    path: 'novel_comment/add',
    parameter: {
      'novel_id': novel_id,
      'comment_content': comment_content,
      'parent_id': parent_id,
    },
    showTips: false,
    fromJson: (json) => json,
  );

  return results.status;
}

/// 评论点赞/取消点赞接口。
///
/// [comment_id] 评论ID（必传）。
/// 返回点赞结果（包含最新点赞状态和点赞数），失败时返回 null。
Future<CommentLikeResult?> like_comment({
  required int comment_id,
}) async {
  final ResultsType<Map<String, dynamic>> results = await postRequest<Map<String, dynamic>>(
    path: 'novel_comment/like',
    parameter: {
      'comment_id': comment_id,
    },
    showTips: true,
    fromJson: (json) => json,
  );

  if (!results.status || results.content == null) return null;
  return CommentLikeResult.from_json(results.content!);
}
