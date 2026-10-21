// ignore_for_file: non_constant_identifier_names

import 'package:app/api/post_request.dart';
import 'package:app/models/comics.dart';

/// 保留服务端错误信息，由页面呈现可重试状态，避免把失败当成空列表。
class ComicsRequestException implements Exception {
  final String message;
  const ComicsRequestException(this.message);
  @override
  String toString() => message;
}

/// 所有漫画请求走现有加密、鉴权及 UTC 请求时间中间件。
Future<Map<String, dynamic>> comics_request(
  String action, [
  Map<String, dynamic> parameter = const <String, dynamic>{},
  String? authorization_token,
]) async {
  final result = await postRequest<Map<String, dynamic>>(
    path: action.contains('/') ? action : 'comics/$action',
    parameter: parameter,
    showTips: false,
    authorization_token: authorization_token,
    fromJson: (json) => json,
  );
  if (!result.status) throw ComicsRequestException(result.message);
  return result.content ?? <String, dynamic>{};
}

/// TODO 需要登录的写入绑定发起请求时的凭证，保留原有一/二参数公共调用。
Future<Map<String, dynamic>> comics_session_request(
  String action,
  Map<String, dynamic> parameter, {
  required String authorization_token,
}) => comics_request(action, parameter, authorization_token);

Future<ComicDetail> comics_detail(int comic_id, {String? language}) async =>
    ComicDetail.from_json(
      await comics_request('get_info', <String, dynamic>{
        'comic_id': comic_id,
        if (language != null && language.isNotEmpty) 'language': language,
      }),
    );

/// 查询相似漫画推荐（按共享分类匹配）。
Future<List<ComicItem>> comics_similar(int comic_id, {int limit = 10}) async {
  final data = await comics_request('similar', <String, dynamic>{
    'comic_id': comic_id,
    'limit': limit,
  });
  return comics_list(data['list']).map(ComicItem.from_json).toList();
}

Future<ComicReading> comics_read(
  int chapter_id, {
  String? authorization_token,
}) async => ComicReading.from_json(
  await comics_request('read', <String, dynamic>{
    'chapter_id': chapter_id,
  }, authorization_token),
);
