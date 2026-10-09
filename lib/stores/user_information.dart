import 'package:app/config/constant.dart';
import 'package:get/get.dart';
import 'package:app/models/user_info.dart';
import 'package:app/util/storage_util/index.dart';
import 'package:flutter/foundation.dart';

/// 用户信息全局状态。
///
/// 管理当前登录用户资料、登录状态和认证会话版本。
class UserInformation extends GetxController {
  UserInformation({
    @visibleForTesting Future<bool> Function(String, String)? token_writer,
  }) : _token_writer = token_writer ?? StorageUtil.saveData;

  /// 凭证持久化入口。写入在内存中同步完成，Future 仅等待磁盘刷新。
  final Future<bool> Function(String, String) _token_writer;

  /// 当前用户信息，默认 null 表示未登录。
  var userInfo = Rxn<UserInfo>();

  /// 当前登录状态。
  var isLoggedIn = false.obs;

  /// 当前认证会话版本。
  ///
  /// 认证身份变化或开始退出时递增，使旧身份已经发出的异步响应失效。
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

    // 监听 userInfo 的变化，自动更新 isLoggedIn。
    ever(userInfo, (_) {
      final info = userInfo.value;
      isLoggedIn.value = info != null && info.id != 0;
    });
  }

  /// 保存用户信息。
  ///
  /// [info] 要保存的用户信息。
  void saveUserInfo(UserInfo info) {
    _set_user_info(info);
  }

  /// 仅向请求所属会话提交新凭证，避免等待磁盘期间将旧账号重新登录。
  ///
  /// [token] 和 [info] 在同一同步调用中更新；持久化完成后只校验结果，
  /// 不再写入身份。[request_revision] 是认证请求开始时的会话版本，
  /// [is_active] 可用于阻止已关闭页面的认证结果提交或继续跳转。
  Future<bool> save_auth_credentials_if_current({
    required String token,
    required UserInfo info,
    required int request_revision,
    bool Function()? is_active,
  }) async {
    if (token.trim().isEmpty ||
        info.id <= 0 ||
        !is_auth_revision_current(request_revision) ||
        (is_active != null && !is_active())) {
      return false;
    }

    // GetStorage.write 同步更新内存，再异步刷新磁盘。此处不能先 await，
    // 否则其他登录/退出可在凭证与用户资料之间插入并被旧资料覆盖。
    final Future<bool> persistence = _token_writer(Constant.tokenKey, token);
    _set_user_info(info, invalidate_auth_session: true);
    final int committed_revision = _auth_revision;

    final bool saved = await persistence;
    return saved &&
        is_auth_revision_current(committed_revision) &&
        (is_active == null || is_active());
  }

  /// 清空用户信息（登出）。
  void clearUserInfo() {
    _set_user_info(null);
  }

  /// 开始退出并立即使当前认证会话失效。
  ///
  /// 返回本次退出后的会话版本，供后台清理任务判断用户是否已经重新登录。
  int begin_logout() {
    _set_user_info(null, invalidate_auth_session: true);
    isLoggedIn.value = false;
    return _auth_revision;
  }

  /// 统一更新当前用户资料，并在认证身份变化时递增身份版本。
  ///
  /// [next_user_info] 为即将生效的用户资料；传入 null 表示切换到访客状态。
  /// [invalidate_auth_session] 在开始退出时强制失效，即使当前已经是访客。
  void _set_user_info(
    UserInfo? next_user_info, {
    bool invalidate_auth_session = false,
  }) {
    final int current_user_id = _authenticated_user_id(userInfo.value);
    final int next_user_id = _authenticated_user_id(next_user_info);
    final bool identity_changed = current_user_id != next_user_id;

    // 身份切换统一废弃旧会话响应，避免直接清空或切换账号时遗漏失效处理。
    if (identity_changed || invalidate_auth_session) {
      _auth_revision++;
    }

    // 访客、当前账号和其他账号分别属于不同的认证身份。
    if (identity_changed) {
      _auth_identity_revision.value++;
    }

    // 写入用户资料后，由现有 ever 统一同步 isLoggedIn。
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
  ///
  /// [request_revision] 请求发起时的会话版本。
  bool is_auth_revision_current(int request_revision) {
    return request_revision == _auth_revision;
  }

  /// 判断登录态请求响应是否仍可写入。
  ///
  /// [request_revision] 请求发起时的会话版本。
  bool can_apply_authenticated_response(int request_revision) {
    return is_auth_revision_current(request_revision) && isLoggedIn.value;
  }

  /// 判断访客态请求响应是否仍可写入。
  ///
  /// [request_revision] 请求发起时的会话版本。
  bool can_apply_visitor_response(int request_revision) {
    return is_auth_revision_current(request_revision) && !isLoggedIn.value;
  }

  /// 仅在认证会话未失效时保存异步请求返回的用户信息。
  ///
  /// [info] 用户信息。
  /// [request_revision] 请求发起时的会话版本。
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
