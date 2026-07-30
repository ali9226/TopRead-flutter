import 'dart:async';

import 'package:app/api/post_request.dart';
import 'package:app/config/constant.dart';
import 'package:app/fcm/fcm_auth.dart';
import 'package:app/message/message_service.dart';
import 'package:app/models/login.dart';
import 'package:app/stores/message_store.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/encryption/index.dart';
import 'package:app/util/log_util.dart';
import 'package:app/websocket/websocket_auth.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/util/router/router_util.dart';
import 'package:app/util/storage_util/index.dart';
import 'package:app/util/string/to_string.dart';
import 'package:get/get.dart';

// TODO 类似js的逻辑处理
class Logic {
  final BuildContext context;

  Logic(this.context);

  /// 打开“修改密码”页面。
  Future<void> updatePassword() async {
    routerUtil(path: '/change_password');
  }

  /// 退出当前账号。
  ///
  /// 本地认证状态与 Token 是退出成功的关键路径，完成后立即反馈用户。
  /// WebSocket、访客未读和 FCM 解绑属于后台同步，不阻塞页面和成功提示。
  Future<void> logout() async {
    final UserInformation user_information = Get.find<UserInformation>();
    final MessageStore message_store = Get.find<MessageStore>();

    /// 先递增会话版本，确保所有退出前发出的异步响应立即失效。
    final int logout_revision = user_information.begin_logout();
    message_store.clear();

    /// Token 必须确认从本地移除，避免应用重启后恢复旧会话。
    await StorageUtil.removeData(Constant.tokenKey);

    /// 后台任务不影响本地退出结果和成功提示。
    unawaited(_complete_logout_cleanup(logout_revision));
    await showBottomTip(easy.tr('UserInfo.success_02'));
  }

  /// 完成退出后的后台服务切换。
  Future<void> _complete_logout_cleanup(int logout_revision) async {
    try {
      await Future.wait<void>(<Future<void>>[
        _switch_to_visitor_session(logout_revision),
        FcmAuth.onLogout(),
      ]);
    } catch (error) {
      logUtil(msg: '退出后台清理失败: $error', type: 'e');
    }
  }

  /// 切换为访客 WebSocket，并在会话仍为访客态时刷新访客未读数。
  Future<void> _switch_to_visitor_session(int logout_revision) async {
    final UserInformation user_information = Get.find<UserInformation>();
    if (!user_information.can_apply_visitor_response(logout_revision)) {
      return;
    }

    await WebSocketAuth.onLogout();
    if (!user_information.can_apply_visitor_response(logout_revision)) {
      return;
    }

    await MessageService.fetchVisitorUnread();
  }

  /// 提交新密码。
  // ignore: non_constant_identifier_names
  Future<bool> submit_password_update(String inputText) async {
    if (inputText.trim().isEmpty) {
      showBottomTip(easy.tr('UserInfo.error_02'));
      return false;
    }
    final Map<String, dynamic> parameter = <String, dynamic>{
      'password': passwordEncryption(removeSpaces(inputText)),
    };
    final results = await postRequest<Login>(
      path: 'user/update_password',
      parameter: parameter,
      fromJson: (json) => Login.fromJson(json),
    );
    if (!results.status) return false;
    if (results.content == null) return false;
    final String token = results.content?.token.toString() ?? '';
    if (token.isEmpty) return false;
    await StorageUtil.saveData(Constant.tokenKey, token);

    // TODO 保存 userInfo
    final userController = Get.put(UserInformation());
    if (results.content?.userInfo != null) {
      userController.saveUserInfo(results.content!.userInfo);
    }

    // TODO 密码更改成功
    showBottomTip(easy.tr('UserInfo.success_03'));
    return true;
  }

  /// 删除当前账户。
  ///
  /// 调用 user/delete 接口，成功后清除本地登录状态并切换为访客模式。
  Future<bool> deleteAccount() async {
    final results = await postRequest<dynamic>(
      path: 'user/delete',
      showTips: false,
    );
    if (!results.status) return false;

    /// 删除成功，执行退出登录清理。
    final UserInformation user_information = Get.find<UserInformation>();
    final MessageStore message_store = Get.find<MessageStore>();

    /// 递增会话版本，确保所有退出前发出的异步响应立即失效。
    final int logout_revision = user_information.begin_logout();
    message_store.clear();

    /// 移除本地 token。
    await StorageUtil.removeData(Constant.tokenKey);

    /// 后台任务：切换为访客 WebSocket 和解绑 FCM。
    unawaited(_complete_logout_cleanup(logout_revision));

    return true;
  }
}
