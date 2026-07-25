import 'package:get/get.dart';
import 'package:app/stores/message_store.dart';
import 'package:app/stores/user_information.dart';
import 'package:app/util/log_util.dart';

/// 消息服务。
///
/// 负责登录成功后获取未读消息，供 autoLogin 和登录流程调用。
class MessageService {
  /// 获取已登录用户的未读消息。
  ///
  /// 登录成功后调用，请求 message/unread_count 接口。
  /// 先清空访客数据，再获取用户未读数据。
  /// 未读数据保存在 MessageStore 中全局共享。
  static Future<void> fetchUnreadAfterLogin() async {
    final user_info = Get.find<UserInformation>();
    if (!user_info.isLoggedIn.value) {
      logUtil(msg: 'MessageService: 用户未登录，跳过获取未读消息');
      return;
    }

    logUtil(msg: 'MessageService: 登录成功，清空访客数据并获取用户未读消息');
    final message_store = Get.find<MessageStore>();
    // 清空访客数据（包括访客的客服未读数）。
    message_store.clear();
    // 获取已登录用户的未读消息。
    await message_store.fetch_statistics();
  }

  /// 获取访客的客服聊天未读消息。
  ///
  /// 未登录时调用，请求 customer_service_chat/visitor_unread_count 接口。
  /// 未读数据保存在 MessageStore 中全局共享。
  static Future<void> fetchVisitorUnread() async {
    logUtil(msg: 'MessageService: 获取访客客服未读消息');
    final message_store = Get.find<MessageStore>();
    await message_store.fetch_visitor_chat_unread();
  }
}
