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

  /// 当前认证身份版本。
  ///
  /// 仅在访客登录、用户退出或切换账号时递增，
  /// 同一用户的资料刷新不会改变该版本。
  final RxInt _auth_identity_revision = 0.obs;

  /// 对外提供当前认证身份版本。
  ///
  /// getter 内部读取 Rx 值，调用方位于 Obx 中时会自动参与现有响应式重建，
  /// 不需要额外注册登录状态监听。
  int get auth_identity_revision => _auth_identity_revision.value;

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
    _set_user_info(info);
  }

  // TODO 清空用户信息（登出）
  void clearUserInfo() {
    _set_user_info(null);
  }

  /// 开始退出并立即使当前认证会话失效。
  ///
  /// 返回本次退出后的会话版本，供后台清理任务判断用户是否已经重新登录。
  int begin_logout() {
    _auth_revision++;
    _set_user_info(null);
    isLoggedIn.value = false;
    return _auth_revision;
  }

  /// 统一更新当前用户资料，并在认证身份变化时递增身份版本。
  ///
  /// [next_user_info] 为即将生效的用户资料；传入 null 表示切换到访客状态。
  void _set_user_info(UserInfo? next_user_info) {
    final int current_user_id = _authenticated_user_id(userInfo.value);
    final int next_user_id = _authenticated_user_id(next_user_info);

    /// 访客、当前账号和其他账号分别属于不同的认证身份。
    if (current_user_id != next_user_id) {
      _auth_identity_revision.value++;
    }

    /// 写入用户资料后，由现有 ever 统一同步 isLoggedIn。
    userInfo.value = next_user_info;
  }

  /// 返回能够代表认证身份的用户 ID。
  ///
  /// [info] 为空或 ID 为 0 时表示访客，统一返回 0。
  int _authenticated_user_id(UserInfo? info) {
    if (info == null || info.id == 0) {
      return 0;
    }
    return info.id;
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
