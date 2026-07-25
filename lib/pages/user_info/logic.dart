import 'package:get/get.dart';
import 'package:app/api/post_request.dart';
import 'package:app/models/login.dart';
import 'package:app/stores/user_information.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/util/dialog/show_bottom_tip.dart';

// TODO 类似js的逻辑处理
class Logic {
  final UserInformation userInformation = Get.find<UserInformation>();

  Logic();

  // TODO 下拉刷新时重新获取一次最新用户信息
  Future<bool> refreshUserInfo({bool showSuccessTip = true}) async {
    /// 记录请求发起时的认证会话版本。
    final int request_revision = userInformation.auth_revision;
    final results = await postRequest<Login>(
      path: 'subscriber/get_info',
      showTips: false,
      fromJson: (json) => Login.fromJson(json),
    );

    if (!results.status || results.content == null) return false;

    /// 退出前发出的旧响应不能重新写回登录态。
    final bool saved = userInformation.save_user_info_if_current(
      results.content!.userInfo,
      request_revision: request_revision,
    );
    if (!saved) return false;

    if (showSuccessTip) {
      showBottomTip(easy.tr('UserInfo.success_01'));
    }
    return true;
  }
}
