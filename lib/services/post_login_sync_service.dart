// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:app/fcm/fcm_auth.dart';
import 'package:app/message/message_service.dart';
import 'package:app/util/log_util.dart';
import 'package:app/websocket/websocket_auth.dart';
import 'package:flutter/foundation.dart';

/// 登录完成后的后台同步服务。
///
/// 用户 Token 与资料保存成功后，页面即可完成登录并跳转。WebSocket 身份
/// 切换、未读统计和 FCM 绑定均为可恢复的后台同步，不应阻塞登录按钮。
class PostLoginSyncService {
  const PostLoginSyncService._();

  /// 启动全部登录后同步任务。
  ///
  /// 测试可通过三个可选回调注入永不完成、失败或立即成功的任务。
  static void start({
    @visibleForTesting Future<void> Function()? websocket_sync,
    @visibleForTesting Future<void> Function()? message_sync,
    @visibleForTesting Future<void> Function()? fcm_sync,
  }) {
    unawaited(
      _run_task(
        task_name: 'WebSocket 身份切换',
        task: websocket_sync ?? WebSocketAuth.onLoginSuccess,
      ),
    );
    unawaited(
      _run_task(
        task_name: '未读消息同步',
        task: message_sync ?? MessageService.fetchUnreadAfterLogin,
      ),
    );
    unawaited(
      _run_task(
        task_name: 'FCM 用户绑定',
        task: fcm_sync ?? FcmAuth.onLoginSuccess,
      ),
    );
  }

  /// 执行单个后台任务并隔离异常。
  static Future<void> _run_task({
    required String task_name,
    required Future<void> Function() task,
  }) async {
    try {
      await task();
    } catch (error) {
      logUtil(msg: '登录后$task_name失败: $error', type: 'e');
    }
  }
}
