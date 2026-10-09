import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/api/post_request.dart';
import 'package:app/config/constant.dart';
import 'package:app/api/results_type.dart';
import 'package:app/services/post_login_sync_service.dart';
import 'package:app/message/message_service.dart';
import 'package:app/models/login.dart' as login_model;
import 'package:app/stores/user_information.dart';
import 'package:app/stores/authorized_login_store.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/log_util.dart';
import 'package:app/util/storage_util/index.dart';
import 'package:app/websocket/websocket_service.dart';

/// 自动登录。
///
/// 尝试读取本地 token，存在则静默刷新用户信息，实现应用启动后的自动登录。
/// 如果 token 不存在（用户未登录），则创建本地访客 UUID 并连接 WebSocket。
Future<void> autoLogin({
  @visibleForTesting
  Future<ResultsType<login_model.Login>> Function()? load_user,
  @visibleForTesting Future<void> Function()? synchronize_guest,
  @visibleForTesting VoidCallback? on_login_completed,
}) async {
  final UserInformation user_controller = Get.find<UserInformation>();
  final int request_revision = user_controller.auth_revision;

  // 用户主动认证优先于启动恢复，不能用较早的自动登录抢占手动请求。
  bool has_manual_authentication() =>
      Get.isRegistered<AuthorizedLoginStore>() &&
      Get.find<AuthorizedLoginStore>().loading.value;

  Future<void> connect_guest() async {
    if (!user_controller.can_apply_visitor_response(request_revision)) return;
    if (synchronize_guest != null) {
      await synchronize_guest();
      return;
    }
    await WebSocketService().get_or_create_visitor_uuid();
    if (!user_controller.can_apply_visitor_response(request_revision)) return;
    unawaited(WebSocketService().connect());
    unawaited(MessageService.fetchVisitorUnread());
  }

  // 尝试读取本地 token。
  final String? oldToken = await StorageUtil.getData(Constant.tokenKey);
  if (!user_controller.is_auth_revision_current(request_revision) ||
      has_manual_authentication())
    return;
  if (oldToken == null || oldToken.isEmpty) {
    logUtil(msg: "oldToken 不存在，以访客身份连接 WebSocket");
    await connect_guest();
    return;
  }

  final results =
      await (load_user?.call() ??
          postRequest<login_model.Login>(
            path: 'subscriber/get_info',
            showTips: false,
            fromJson: (json) => login_model.Login.fromJson(json),
          ));
  final String? current_token = await StorageUtil.getData(Constant.tokenKey);
  if (!user_controller.is_auth_revision_current(request_revision) ||
      has_manual_authentication() ||
      current_token != oldToken)
    return;

  if (!results.status || results.content == null) {
    // 网络失败或响应解析失败并不意味着凭证失效，保留 Token 供后续重试。
    if (!results.serverRejected) return;
    await StorageUtil.removeData(Constant.tokenKey);
    await connect_guest();
    return;
  }

  final login_model.Login loginData = results.content!;
  final String token = loginData.token.toString();
  if (token.isEmpty) {
    return;
  }

  if (!await user_controller.save_auth_credentials_if_current(
    token: token,
    info: loginData.userInfo,
    request_revision: request_revision,
    is_active: () => !has_manual_authentication(),
  ))
    return;

  if (on_login_completed != null) {
    on_login_completed();
    return;
  }
  PostLoginSyncService.start();

  showBottomTip(easy.tr('login.success_01'));
}
