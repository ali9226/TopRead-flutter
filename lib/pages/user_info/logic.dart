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
    final results = await postRequest<Login>(
      path: 'subscriber/get_info',
      showTips: false,
      fromJson: (json) => Login.fromJson(json),
    );

    if (!results.status || results.content == null) return false;

    userInformation.saveUserInfo(results.content!.userInfo);

    if (showSuccessTip) {
      showBottomTip(easy.tr('UserInfo.success_01'));
    }
    return true;
  }
}
