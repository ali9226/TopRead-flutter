// ignore_for_file: non_constant_identifier_names

import 'package:app/api/comics.dart';
import 'package:app/api/post_request.dart';
import 'package:easy_localization/easy_localization.dart';

/// TODO 固定评论请求发起时的凭证，账号切换不会把旧操作发送为新用户。
Future<Map<String, dynamic>> comics_comments_request(
  String action,
  Map<String, dynamic> parameter, {
  String? authorization_token,
}) async {
  final result = await postRequest<Map<String, dynamic>>(
    path: 'comics_comment/$action',
    parameter: parameter,
    authorization_token: authorization_token,
    showTips: false,
    fromJson: (json) => json,
  );
  if (!result.status || result.content == null) {
    throw ComicsRequestException(
      result.message.isNotEmpty
          ? result.message
          : tr('comics.operation_failed'),
    );
  }
  return result.content!;
}
