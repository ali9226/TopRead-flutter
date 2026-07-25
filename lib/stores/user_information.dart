import 'package:get/get.dart';
import 'package:app/models/user_info.dart';

class UserInformation extends GetxController {
  var userInfo = Rxn<UserInfo>(); // TODO 用户信息，默认 null
  var isLoggedIn = false.obs; // TODO 登录状态 RxBool

  /// 当前认证会话版本。
  ///
  /// 每次退出时递增，用于让退出前已经发出的异步请求响应失效。
  int _auth_revision = 0;

  /// 当前认证会话版本。
  int get auth_revision => _auth_revision;

  @override
  void onInit() {
    super.onInit();

    // TODO 监听 userInfo 的变化，自动更新 isLoggedIn
    ever(userInfo, (_) {
      final info = userInfo.value;
      isLoggedIn.value = info != null && info.id != 0;
    });
  }

  // TODO 保存用户信息
  void saveUserInfo(UserInfo info) {
    userInfo.value = info; // 自动触发 ever 监听
  }

  // TODO 清空用户信息（登出）
  void clearUserInfo() {
    userInfo.value = null; // TODO 自动触发 ever 监听
  }

  /// 开始退出并立即使当前认证会话失效。
  ///
  /// 返回本次退出后的会话版本，供后台清理任务判断用户是否已经重新登录。
  int begin_logout() {
    _auth_revision++;
    userInfo.value = null;
    isLoggedIn.value = false;
    return _auth_revision;
  }

  /// 判断指定请求是否仍属于当前认证会话。
  bool is_auth_revision_current(int request_revision) {
    return request_revision == _auth_revision;
  }

  /// 判断登录态请求响应是否仍可写入。
  bool can_apply_authenticated_response(int request_revision) {
    return is_auth_revision_current(request_revision) && isLoggedIn.value;
  }

  /// 判断访客态请求响应是否仍可写入。
  bool can_apply_visitor_response(int request_revision) {
    return is_auth_revision_current(request_revision) && !isLoggedIn.value;
  }

  /// 仅在认证会话未失效时保存异步请求返回的用户信息。
  bool save_user_info_if_current(
    UserInfo info, {
    required int request_revision,
  }) {
    if (!can_apply_authenticated_response(request_revision)) {
      return false;
    }
    saveUserInfo(info);
    return true;
  }
}
