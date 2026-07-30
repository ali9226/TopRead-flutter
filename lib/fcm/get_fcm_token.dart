// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';

import 'package:app/util/log_util.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// 获取 FCM Token 的最大等待时间。
const Duration fcm_token_timeout = Duration(seconds: 10);

/// 获取当前设备的 FCM Token。
///
/// [load_token] 允许测试注入可控的 Token 加载任务。
/// [timeout] 防止 Firebase 原生调用异常时永久占用身份切换队列。
Future<String?> get_fcm_token({
  Future<String?> Function()? load_token,
  Duration timeout = fcm_token_timeout,
}) async {
  try {
    final Future<String?> token_future =
        load_token?.call() ?? FirebaseMessaging.instance.getToken();
    return await token_future.timeout(timeout);
  } on TimeoutException {
    logUtil(msg: 'FCM: 获取 Token 超时', type: 'w');
    return null;
  }
}
