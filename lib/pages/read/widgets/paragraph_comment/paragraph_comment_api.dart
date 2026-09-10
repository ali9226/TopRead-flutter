// ignore_for_file: non_constant_identifier_names

import 'package:app/api/post_request.dart';
import 'package:app/api/results_type.dart';

/// 段落评论数据模型。
class ParagraphComment {
  final int id;
  final int user_id;
  final String user_name;
  final String user_avatar;
  final String content;
  final String create_time;
  final List<ParagraphComment> replies;
  final int reply_count;

  const ParagraphComment({
    required this.id,
    required this.user_id,
    required this.user_name,
    required this.user_avatar,
    required this.content,
    required this.create_time,
    this.replies = const [],
    this.reply_count = 0,
  });

  factory ParagraphComment.from_json(Map<String, dynamic> json) {
    return ParagraphComment(
      id: _parse_int(json['id']),
      user_id: _parse_int(json['user_id']),
      user_name: json['user_name']?.toString() ?? '匿名用户',
      user_avatar: json['user_avatar']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      create_time: json['create_time']?.toString() ?? '',
      replies: (json['replies'] as List<dynamic>?)
              ?.map((e) => ParagraphComment.from_json(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      reply_count: _parse_int(json['reply_count']),
    );
  }

  static int _parse_int(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}

/// 段落评论列表响应。
class ParagraphCommentListResponse {
  final List<ParagraphComment> list;
  final int total;
  final int page;
  final int page_size;
  final bool has_more;

  const ParagraphCommentListResponse({
    required this.list,
    required this.total,
    required this.page,
    required this.page_size,
    required this.has_more,
  });

  factory ParagraphCommentListResponse.from_json(Map<String, dynamic> json) {
    return ParagraphCommentListResponse(
      list: (json['list'] as List<dynamic>?)
              ?.map((e) => ParagraphComment.from_json(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      total: _parse_int(json['total']),
      page: _parse_int(json['page']),
      page_size: _parse_int(json['page_size']),
      has_more: json['has_more'] == true,
    );
  }

  static int _parse_int(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}

/// 段落评论 API 服务。
class ParagraphCommentApi {
  /// 发表评论。
  static Future<int> create({
    required int paragraph_id,
    required String content,
  }) async {
    final ResultsType<Map<String, dynamic>> results =
        await postRequest<Map<String, dynamic>>(
      path: 'paragraph_comment/create',
      parameter: <String, dynamic>{
        'paragraph_id': paragraph_id,
        'content': content,
      },
    );

    if (!results.status || results.content == null) {
      throw Exception(results.message ?? '发表评论失败');
    }
    return _parse_int(results.content!['comment_id']);
  }

  /// 查询评论列表。
  static Future<ParagraphCommentListResponse> inquire({
    required int paragraph_id,
    int page = 1,
    int page_size = 20,
  }) async {
    final ResultsType<Map<String, dynamic>> results =
        await postRequest<Map<String, dynamic>>(
      path: 'paragraph_comment/inquire',
      parameter: <String, dynamic>{
        'paragraph_id': paragraph_id,
        'page': page,
        'page_size': page_size,
      },
    );

    if (!results.status || results.content == null) {
      throw Exception(results.message ?? '查询评论失败');
    }
    return ParagraphCommentListResponse.from_json(results.content!);
  }

  /// 删除评论。
  static Future<void> delete({
    required int comment_id,
  }) async {
    final ResultsType<Map<String, dynamic>> results =
        await postRequest<Map<String, dynamic>>(
      path: 'paragraph_comment/delete',
      parameter: <String, dynamic>{
        'comment_id': comment_id,
      },
    );

    if (!results.status) {
      throw Exception(results.message ?? '删除评论失败');
    }
  }

  /// 回复评论。
  static Future<int> reply({
    required int paragraph_id,
    required int parent_id,
    required String content,
  }) async {
    final ResultsType<Map<String, dynamic>> results =
        await postRequest<Map<String, dynamic>>(
      path: 'paragraph_comment/reply',
      parameter: <String, dynamic>{
        'paragraph_id': paragraph_id,
        'parent_id': parent_id,
        'content': content,
      },
    );

    if (!results.status || results.content == null) {
      throw Exception(results.message ?? '回复评论失败');
    }
    return _parse_int(results.content!['comment_id']);
  }

  static int _parse_int(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}
