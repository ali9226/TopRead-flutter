// ignore_for_file: non_constant_identifier_names

import 'package:app/api/comics.dart';
import 'package:app/config/constant.dart';
import 'package:app/services/comics_progress/service.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/storage_util/index.dart';
import 'package:get/get.dart';

typedef ComicHistoryPreparation =
    Future<void> Function(int comic_id, {int? user_id});
typedef ComicHistoryDeletion =
    Future<Map<String, dynamic>> Function(
      String action,
      Map<String, dynamic> parameter, {
      required String authorization_token,
    });

/// TODO 先作废旧保存并等待排空，再删除服务器历史；确认成功后才清本地续读。
/// TODO 删除失败保留原章节页码，测试可注入阶段回调以验证请求顺序。
Future<bool> remove_comic_history({
  required int comic_id,
  ComicHistoryPreparation? prepare,
  ComicHistoryPreparation? clear,
  ComicHistoryDeletion? request,
  Future<String?> Function()? token_reader,
}) async {
  if (comic_id <= 0 || !Get.isRegistered<UserInformation>()) return false;
  final user = Get.find<UserInformation>();
  final revision = user.auth_revision;
  final user_id = user.userInfo.value?.id ?? 0;
  final token =
      await (token_reader ??
          (() => StorageUtil.getData(Constant.tokenKey)))() ??
      '';
  bool current() =>
      user.can_apply_authenticated_response(revision) &&
      user.userInfo.value?.id == user_id;
  if (!current() || token.isEmpty) return false;
  await (prepare ?? ComicsProgressService.instance.prepare_history_removal)(
    comic_id,
    user_id: user_id,
  );
  if (!current()) return false;
  final result = await (request ?? comics_session_request)(
    'remove_history',
    <String, dynamic>{'comic_id': comic_id},
    authorization_token: token,
  );
  if (!current() ||
      result['status'] == false ||
      int.tryParse('${result['comic_id'] ?? ''}') != comic_id) {
    return false;
  }
  await (clear ?? ComicsProgressService.instance.clear_record)(
    comic_id,
    user_id: user_id,
  );
  return current();
}
