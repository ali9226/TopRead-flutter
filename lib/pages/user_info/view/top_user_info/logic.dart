import 'package:app/api/post_request.dart';
import 'package:app/config/constant.dart';
import 'package:app/models/login.dart';
import 'package:app/models/user_info.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/log_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/util/router/router_util.dart';
import 'package:app/util/router/run_navigation_action_once.dart';
import 'package:app/util/storage_util/index.dart';

// TODO 类似js的逻辑处理
class Logic {
  final BuildContext context;

  Logic(this.context);

  /// 打开“修改昵称”页面。
  Future<void> updateUserInfo() async {
    await run_navigation_action_once(
      actionKey: 'top_user_info_change_nickname',
      action: () async {
        routerUtil(path: '/change_nickname');
      },
    );
  }

  /// 提交新昵称。
  Future<bool> updateUserName(String inputText) async {
    if (inputText.trim().isEmpty) {
      showBottomTip(easy.tr('UserInfo.error_03'));
      return false;
    }

    final parameter = {"name": inputText.trim()};
    final results = await postRequest<UserInfo>(
      path: 'user/update_name',
      parameter: parameter,
      fromJson: (json) => UserInfo.fromJson(json),
    );
    if (!results.status) return false;
    if (results.content == null) return false;

    final userController = Get.put(UserInformation());
    userController.saveUserInfo(results.content!);
    showBottomTip(easy.tr('UserInfo.success_04'));
    return true;
  }

  Future<void> updateUserInformation() async {
    final UserInformation user_controller = Get.find<UserInformation>();
    final int request_revision = user_controller.auth_revision;
    final String? oldToken = await StorageUtil.getData(Constant.tokenKey);
    if (!user_controller.is_auth_revision_current(request_revision)) {
      return;
    }
    if (oldToken == null || oldToken.isEmpty) {
      logUtil(msg: 'TODO oldToken 不存在');
      showBottomTip(easy.tr('UserInfo.error_01'));
      routerUtil(path: '/login');
      return;
    }
    final results = await postRequest<Login>(
      path: 'subscriber/get_info',
      showTips: false,
      fromJson: (json) => Login.fromJson(json),
    );

    /// 用户已退出时丢弃旧请求结果，不能再保存 Token 或用户信息。
    if (!user_controller.can_apply_authenticated_response(request_revision)) {
      return;
    }

    if (!results.status || results.content == null) {
      // TODO 自动登录失败，删除本地的token
      showBottomTip(easy.tr('UserInfo.error_01'));
      await StorageUtil.removeData(Constant.tokenKey);
      routerUtil(path: '/login');

      return;
    }

    final String token = results.content?.token.toString() ?? '';

    if (token.isEmpty) {
      await StorageUtil.removeData(Constant.tokenKey);
      showBottomTip(easy.tr('UserInfo.error_01'));
      routerUtil(path: '/login');
      return;
    }

    // TODO 保存 userInfo
    if (results.content?.userInfo != null) {
      user_controller.save_user_info_if_current(
        results.content!.userInfo,
        request_revision: request_revision,
      );
    }

    showBottomTip(easy.tr('UserInfo.success_01'));
  }
}
