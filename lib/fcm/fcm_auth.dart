import 'package:get/get.dart';
import 'package:app/fcm/bind_user.dart';
import 'package:app/fcm/unbind_user.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/log_util.dart';

/// FCM 认证切换处理。
///
/// 负责处理用户登录/登出时的 FCM Token 绑定/解绑：
/// 1. 登录成功：绑定用户 ID 到当前设备的 FCM Token。
/// 2. 登出：解绑当前设备的 FCM Token 与用户关联。
class FcmAuth {
  /// FCM 身份变更任务队列。
  ///
  /// 保证“退出解绑”和紧随其后的“重新登录绑定”严格按触发顺序执行，
  /// 避免较慢的解绑响应覆盖新登录的绑定结果。
  static Future<void> _identity_operation_queue = Future<void>.value();

  /// 登录成功后绑定用户。
  ///
  /// 将当前设备的 FCM Token 与用户 ID 关联。
  /// 这样推送给指定用户时，可以通过 user_id 查找 Token。
  static Future<void> onLoginSuccess() async {
    final user_info = Get.find<UserInformation>();
    if (!user_info.isLoggedIn.value || user_info.userInfo.value == null) {
      logUtil(msg: 'FcmAuth: 用户未登录，跳过绑定');
      return;
    }

    final int user_id = user_info.userInfo.value!.id;
    logUtil(msg: 'FcmAuth: 登录成功，绑定用户 ID: $user_id');
    await _enqueue_identity_operation(() => FcmBindUser.execute(user_id));
  }

  /// 登出后解绑用户。
  ///
  /// 解除当前设备的 FCM Token 与用户的关联。
  /// 用户退出后不会再收到推送给该用户的消息。
  static Future<void> onLogout() async {
    logUtil(msg: 'FcmAuth: 登出，解绑用户');
    await _enqueue_identity_operation(FcmUnbindUser.execute);
  }

  /// 将一次 FCM 身份变更追加到串行队列。
  static Future<void> _enqueue_identity_operation(
    Future<void> Function() operation,
  ) {
    final Future<void> next_operation = _identity_operation_queue.then(
      (_) => operation(),
    );

    /// 队列自身吞掉异常以保证后续任务仍可执行，调用方仍收到本次任务的异常。
    _identity_operation_queue = next_operation.catchError((Object error) {
      logUtil(msg: 'FcmAuth: 身份变更队列异常: $error', type: 'e');
    });
    return next_operation;
  }
}
