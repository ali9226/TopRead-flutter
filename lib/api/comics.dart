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
]) async {
  final result = await postRequest<Map<String, dynamic>>(
    path: action.contains('/') ? action : 'comics/$action',
    parameter: parameter,
    showTips: false,
    fromJson: (json) => json,
  );
  if (!result.status) throw ComicsRequestException(result.message);
  return result.content ?? <String, dynamic>{};
}

Future<ComicDetail> comics_detail(int comic_id, {String? language}) async =>
    ComicDetail.from_json(
      await comics_request('get_info', <String, dynamic>{
        'comic_id': comic_id,
        if (language != null && language.isNotEmpty) 'language': language,
      }),
    );

Future<ComicReading> comics_read(int chapter_id) async =>
    ComicReading.from_json(
      await comics_request('read', <String, dynamic>{'chapter_id': chapter_id}),
    );
