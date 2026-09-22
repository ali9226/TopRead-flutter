// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:app/api/post_request.dart';

/// 服务端数字字段兼容数据库驱动返回的数字字符串。
int parse_paragraph_int(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

/// 兼容 JSON 布尔值和数据库 0/1 表示法。
bool parse_paragraph_bool(dynamic value) =>
    value == true || value == 1 || value == '1' || value == 'true';

/// 长短篇共用的段评模型，更新点赞或回复时保留图片和引用信息。
class ParagraphComment {
  final int id;
  final int user_id;
  final int parent_id;
  final String user_name;
  final String user_avatar;
  final String content;
  final String create_time;
  final List<String> images;
  final String quote;
  final String reply_to_name;
  final List<ParagraphComment> replies;
  final int reply_count;
  final int like_count;
  final bool is_liked;
  final bool is_deleted;

  const ParagraphComment({
    required this.id,
    required this.user_id,
    required this.user_name,
    required this.user_avatar,
    required this.content,
    required this.create_time,
    this.parent_id = 0,
    this.images = const [],
    this.quote = '',
    this.reply_to_name = '',
    this.replies = const [],
    this.reply_count = 0,
    this.like_count = 0,
    this.is_liked = false,
    this.is_deleted = false,
  });

  factory ParagraphComment.from_json(Map<String, dynamic> json) {
    dynamic image_list = json['images'];
    if (image_list is String) {
      try {
        image_list = jsonDecode(image_list);
      } catch (_) {
        image_list = const [];
      }
    }
    return ParagraphComment(
      id: parse_paragraph_int(json['id']),
      user_id: parse_paragraph_int(json['user_id']),
      parent_id: parse_paragraph_int(json['parent_id']),
      user_name: json['user_name']?.toString() ?? '',
      user_avatar: json['user_avatar']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      create_time: json['create_time']?.toString() ?? '',
      images: image_list is List
          ? image_list.whereType<String>().where((url) => url.isNotEmpty).toList()
          : const [],
      quote: json['quote']?.toString() ?? '',
      reply_to_name: json['reply_to_name']?.toString() ?? '',
      replies: _parse_comments(json['replies']),
      reply_count: parse_paragraph_int(json['reply_count']),
      like_count: parse_paragraph_int(json['like_count']),
      is_liked: parse_paragraph_bool(json['is_liked']),
      is_deleted: parse_paragraph_bool(json['is_deleted']),
    );
  }

  ParagraphComment copy_with({
    List<ParagraphComment>? replies,
    int? reply_count,
    int? like_count,
    bool? is_liked,
    bool? is_deleted,
  }) => ParagraphComment(
    id: id,
    user_id: user_id,
    parent_id: parent_id,
    user_name: user_name,
    user_avatar: user_avatar,
    content: content,
    create_time: create_time,
    images: images,
    quote: quote,
    reply_to_name: reply_to_name,
    replies: replies ?? this.replies,
    reply_count: reply_count ?? this.reply_count,
    like_count: like_count ?? this.like_count,
    is_liked: is_liked ?? this.is_liked,
    is_deleted: is_deleted ?? this.is_deleted,
  );
}

List<ParagraphComment> _parse_comments(dynamic value) => value is List
    ? value.whereType<Map>().map((item) => ParagraphComment.from_json(
        Map<String, dynamic>.from(item),
      )).toList()
    : [];

/// total 是当前层的分页总数；comment_count 才是段落全部评论及回复数。
class ParagraphCommentListResponse {
  final List<ParagraphComment> list;
  final int total;
  final int? comment_count;
  final int page;
  final int page_size;
  final bool has_more;

  const ParagraphCommentListResponse({
    required this.list,
    required this.total,
    required this.page,
    required this.page_size,
    required this.has_more,
    this.comment_count,
  });

  factory ParagraphCommentListResponse.from_json(Map<String, dynamic> json) =>
      ParagraphCommentListResponse(
        list: _parse_comments(json['list']),
        total: parse_paragraph_int(json['total']),
        comment_count: json['comment_count'] == null
            ? null
            : parse_paragraph_int(json['comment_count']),
        page: parse_paragraph_int(json['page']),
        page_size: parse_paragraph_int(json['page_size']),
        has_more: parse_paragraph_bool(json['has_more']),
      );
}

/// 创建、回复及删除均采用事务返回的段落总数，避免本地增减遗漏子回复。
class ParagraphCommentMutationResult {
  final int comment_id;
  final int? comment_count;

  const ParagraphCommentMutationResult({
    this.comment_id = 0,
    this.comment_count,
  });

  factory ParagraphCommentMutationResult.from_json(Map<String, dynamic> json) =>
      ParagraphCommentMutationResult(
        comment_id: parse_paragraph_int(json['comment_id']),
        comment_count: json['comment_count'] == null
            ? null
            : parse_paragraph_int(json['comment_count']),
      );
}

/// API 兼容原入口，并向共用弹窗提供完整的计数和分页响应。
class ParagraphCommentApi {
  static Future<Map<String, dynamic>> _request(
    String action,
    Map<String, dynamic> parameter,
  ) async {
    final result = await postRequest<Map<String, dynamic>>(
      path: 'paragraph_comment/$action',
      parameter: parameter,
      showTips: false,
      fromJson: (json) => json,
    );
    if (!result.status || result.content == null) {
      throw Exception(result.message.isEmpty ? '请求失败' : result.message);
    }
    return result.content!;
  }

  static Future<ParagraphCommentListResponse> inquire({
    required int novel_id,
    required int paragraph_id,
    int? parent_id,
    int page = 1,
    int page_size = 20,
  }) async => ParagraphCommentListResponse.from_json(await _request('inquire', {
    'novel_id': novel_id,
    'paragraph_id': paragraph_id,
    'parent_id': ?parent_id,
    'page': page,
    'page_size': page_size,
  }));

  static Future<ParagraphCommentMutationResult> create_result({
    required int novel_id,
    required int paragraph_id,
    required String content,
    List<String> images = const [],
  }) async => ParagraphCommentMutationResult.from_json(await _request('create', {
    'novel_id': novel_id,
    'paragraph_id': paragraph_id,
    'content': content,
    'images': images,
  }));

  static Future<int> create({
    required int novel_id,
    required int paragraph_id,
    required String content,
    List<String> images = const [],
  }) async => (await create_result(
    novel_id: novel_id, paragraph_id: paragraph_id, content: content, images: images,
  )).comment_id;

  static Future<ParagraphCommentMutationResult> reply_result({
    required int novel_id,
    required int paragraph_id,
    required int parent_id,
    required String content,
    List<String> images = const [],
  }) async => ParagraphCommentMutationResult.from_json(await _request('reply', {
    'novel_id': novel_id,
    'paragraph_id': paragraph_id,
    'parent_id': parent_id,
    'content': content,
    'images': images,
  }));

  static Future<int> reply({
    required int novel_id,
    required int paragraph_id,
    required int parent_id,
    required String content,
    List<String> images = const [],
  }) async => (await reply_result(
    novel_id: novel_id, paragraph_id: paragraph_id, parent_id: parent_id,
    content: content, images: images,
  )).comment_id;

  static Future<ParagraphCommentMutationResult> delete_result({
    required int novel_id,
    required int comment_id,
  }) async => ParagraphCommentMutationResult.from_json(
    await _request('delete', {'novel_id': novel_id, 'comment_id': comment_id}),
  );

  static Future<void> delete({required int novel_id, required int comment_id}) async {
    await delete_result(novel_id: novel_id, comment_id: comment_id);
  }

  static Future<Map<String, dynamic>> like({
    required int novel_id,
    required int comment_id,
    bool? liked,
  }) => _request('like', {
    'novel_id': novel_id,
    'comment_id': comment_id,
    'liked': ?liked,
  });
}

/// 可注入网关使异步时序、分页和销毁后的回调可独立验证。
class ParagraphCommentRepository {
  const ParagraphCommentRepository();

  Future<ParagraphCommentListResponse> inquire({
    required int novel_id, required int paragraph_id, int? parent_id, int page = 1,
  }) => ParagraphCommentApi.inquire(
    novel_id: novel_id, paragraph_id: paragraph_id, parent_id: parent_id, page: page,
  );

  Future<ParagraphCommentMutationResult> submit({
    required int novel_id,
    required int paragraph_id,
    required String content,
    int? parent_id,
    List<String> images = const [],
  }) => parent_id == null
      ? ParagraphCommentApi.create_result(
          novel_id: novel_id, paragraph_id: paragraph_id, content: content, images: images,
        )
      : ParagraphCommentApi.reply_result(
          novel_id: novel_id, paragraph_id: paragraph_id, parent_id: parent_id,
          content: content, images: images,
        );

  Future<ParagraphCommentMutationResult> delete(int novel_id, int comment_id) =>
      ParagraphCommentApi.delete_result(novel_id: novel_id, comment_id: comment_id);

  Future<Map<String, dynamic>> like(int novel_id, int comment_id, bool liked) =>
      ParagraphCommentApi.like(novel_id: novel_id, comment_id: comment_id, liked: liked);
}
