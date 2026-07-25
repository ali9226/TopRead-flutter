import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/api/post_request.dart';
import 'package:app/config/constant.dart';
import 'package:app/message/message_service.dart';
import 'package:app/models/login.dart' as login_model;
import 'package:app/stores/user_information.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/log_util.dart';
import 'package:app/util/storage_util/index.dart';
import 'package:app/websocket/websocket_service.dart';

/// 自动登录。
///
/// 尝试读取本地 token，存在则静默刷新用户信息，实现应用启动后的自动登录。
/// 如果 token 不存在（用户未登录），则创建本地访客 UUID 并连接 WebSocket。
Future<void> autoLogin() async {
  // 尝试读取本地 token。
  final String? oldToken = await StorageUtil.getData(Constant.tokenKey);
  if (oldToken == null || oldToken.isEmpty) {
    logUtil(msg: "oldToken 不存在，以访客身份连接 WebSocket");
    // 先生成/获取访客 UUID，确保后续请求可用。
    await WebSocketService().get_or_create_visitor_uuid();
    // 异步连接 WebSocket（不等待连接完成）。
    WebSocketService().connect();
    // 异步获取访客的客服聊天未读消息（角标会响应式更新）。
    MessageService.fetchVisitorUnread();
    return;
  }

  final results = await postRequest<login_model.Login>(
    path: 'subscriber/get_info',
    showTips: false,
    fromJson: (json) => login_model.Login.fromJson(json),
  );
  if (!results.status || results.content == null) {
    // 自动登录失败，清掉可能失效的 token，以访客身份连接 WebSocket。
    await StorageUtil.removeData(Constant.tokenKey);
    // 先生成/获取访客 UUID，确保后续请求可用。
    await WebSocketService().get_or_create_visitor_uuid();
    // 异步连接 WebSocket（不等待连接完成）。
    WebSocketService().connect();
    // 异步获取访客的客服聊天未读消息（角标会响应式更新）。
    MessageService.fetchVisitorUnread();
    return;
  }

  final login_model.Login loginData = results.content!;
  final String token = loginData.token.toString();
  if (token.isEmpty) {
    await StorageUtil.removeData(Constant.tokenKey);
    // 先生成/获取访客 UUID，确保后续请求可用。
    await WebSocketService().get_or_create_visitor_uuid();
    // 异步连接 WebSocket（不等待连接完成）。
    WebSocketService().connect();
    // 异步获取访客的客服聊天未读消息（角标会响应式更新）。
    MessageService.fetchVisitorUnread();
    return;
  }

  await StorageUtil.saveData(Constant.tokenKey, token);

  // 自动登录成功，把最新用户信息写入全局 store。
  final userController = Get.put(UserInformation());
  userController.saveUserInfo(loginData.userInfo);

  // 异步连接 WebSocket（不等待连接完成）。
  WebSocketService().connect();

  // 异步获取已登录用户的未读消息（角标会响应式更新）。
  MessageService.fetchUnreadAfterLogin();

  showBottomTip(easy.tr('login.success_01'));
}
