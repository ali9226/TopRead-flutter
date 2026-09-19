// ignore_for_file: non_constant_identifier_names

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

  const CommentLikeResult({required this.like, required this.like_count});

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
/// [paragraph_id] 段落ID（可选，传则只返回该段落的评论）。
/// [page] 页码，默认1。
/// [page_size] 每页数量，默认20。
/// [highlight_id] 高亮评论ID（可选，后端将其顶层父评论排到第一位）。
/// 返回评论列表结果，失败时返回 null。
Future<CommentListResult?> inquire_comment_list({
  required int novel_id,
  int paragraph_id = 0,
  int page = 1,
  int page_size = 20,
  int highlight_id = 0,
}) async {
  final Map<String, dynamic> parameter = {
    'novel_id': novel_id,
    'page': page,
    'page_size': page_size,
  };
  if (paragraph_id > 0) parameter['paragraph_id'] = paragraph_id;
  if (highlight_id > 0) parameter['highlight_id'] = highlight_id;

  final ResultsType<Map<String, dynamic>> results =
      await postRequest<Map<String, dynamic>>(
        path: 'novel_comment/inquire',
        parameter: parameter,
        showTips: false,
        fromJson: (json) => json,
      );

  if (!results.status || results.content == null) {
    return null;
  }
  return CommentListResult.from_json(results.content!);
}

/// 发送评论接口（包括回复评论，支持段落评论）。
///
/// [novel_id] 小说ID（段评时可从段落推导，普通评论必传）。
/// [comment_content] 评论内容（必传）。
/// [parent_id] 父评论ID（可选，0=顶层评论，>0=回复某条评论）。
/// [paragraph_id] 段落ID（可选，段评时必传）。
/// [selection_start] 选区起始偏移（可选，段评使用）。
/// [selection_end] 选区结束偏移（可选，段评使用）。
/// 返回评论ID和段评总数（段评时），失败返回 null。
Future<Map<String, dynamic>?> add_comment({
  required int novel_id,
  required String comment_content,
  int parent_id = 0,
  int paragraph_id = 0,
  int? selection_start,
  int? selection_end,
}) async {
  final Map<String, dynamic> parameter = {
    'novel_id': novel_id,
    'comment_content': comment_content,
    'parent_id': parent_id,
  };
  if (paragraph_id > 0) parameter['paragraph_id'] = paragraph_id;
  if (selection_start != null) parameter['selection_start'] = selection_start;
  if (selection_end != null) parameter['selection_end'] = selection_end;

  final ResultsType<Map<String, dynamic>> results =
      await postRequest<Map<String, dynamic>>(
        path: 'novel_comment/add',
        parameter: parameter,
        showTips: false,
        fromJson: (json) => json,
      );

  if (!results.status || results.content == null) return null;
  return results.content;
}

/// 评论点赞/取消点赞接口。
///
/// [comment_id] 评论ID（必传）。
/// 返回点赞结果（包含最新点赞状态和点赞数），失败时返回 null。
Future<CommentLikeResult?> like_comment({required int comment_id}) async {
  final ResultsType<Map<String, dynamic>> results =
      await postRequest<Map<String, dynamic>>(
        path: 'novel_comment/like',
        parameter: {'comment_id': comment_id},
        showTips: true,
        fromJson: (json) => json,
      );

  if (!results.status || results.content == null) return null;
  return CommentLikeResult.from_json(results.content!);
}

/// 删除评论接口。
///
/// [comment_id] 评论ID（必传）。
/// 返回是否成功删除。
Future<bool> delete_comment({required int comment_id}) async {
  final ResultsType<Map<String, dynamic>> results =
      await postRequest<Map<String, dynamic>>(
        path: 'novel_comment/delete',
        parameter: {'comment_id': comment_id},
        showTips: false,
        fromJson: (json) => json,
      );

  return results.status;
}

/// 不喜欢评论接口。
///
/// [comment_id] 评论ID（必传）。
/// 返回是否成功标记不喜欢。
Future<bool> dislike_comment({required int comment_id}) async {
  final ResultsType<Map<String, dynamic>> results =
      await postRequest<Map<String, dynamic>>(
        path: 'novel_comment/dislike',
        parameter: {'comment_id': comment_id},
        showTips: false,
        fromJson: (json) => json,
      );

  return results.status;
}

/// 举报评论接口（支持登录和未登录用户）。
///
/// [comment_id] 评论ID（必传）。
/// [reasons] 举报理由数组（必传）。
/// 返回是否成功举报。
Future<bool> report_comment({
  required int comment_id,
  required List<String> reasons,
}) async {
  final ResultsType<Map<String, dynamic>> results =
      await postRequest<Map<String, dynamic>>(
        path: 'novel_comment_report/report',
        parameter: {
          'comment_id': comment_id,
          'reasons': reasons,
        },
        showTips: false,
        fromJson: (json) => json,
      );

  return results.status;
}
