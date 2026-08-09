// ignore_for_file: non_constant_identifier_names

import 'package:get/get.dart';
import 'package:app/models/rotation.dart';

/// 认证流程全局状态。
///
/// 登录页、注册页和所有第三方授权入口共用同一把互斥锁，确保任意认证流程
/// 进行期间不会再次提交账号密码或重复拉起其他授权平台。
class AuthorizedLoginStore extends GetxController {
  /// 接口返回的授权登录列表。
  final RxList<Rotation> rotation_list = <Rotation>[].obs;

  /// 当前是否正在执行认证流程。
  final RxBool loading = false.obs;

  /// 当前是否正在从远程获取授权登录方式列表。
  final RxBool is_fetching_list = false.obs;

  /// 当前正在执行的认证类型，例如 google、apple、login、register。
  final RxString loading_platform = ''.obs;

  /// 是否已经至少完成过一次请求。
  final RxBool loaded = false.obs;

  /// 尝试开始一项认证流程。
  ///
  /// 返回 true 表示成功占用认证锁；已有流程进行中或认证类型为空时返回 false。
  bool try_start_authentication(String authentication_type) {
    final String normalized_type = authentication_type.trim().toLowerCase();
    if (normalized_type.isEmpty || loading.value) {
      return false;
    }

    loading_platform.value = normalized_type;
    loading.value = true;
    return true;
  }

  /// 结束指定认证流程。
  ///
  /// 仅允许当前持有者释放认证锁，避免旧异步任务结束时误清除新流程的状态。
  void finish_authentication(String authentication_type) {
    final String normalized_type = authentication_type.trim().toLowerCase();
    if (!loading.value || loading_platform.value != normalized_type) {
      return;
    }

    loading.value = false;
    loading_platform.value = '';
  }

  /// 保存授权登录列表，并按排序值从大到小处理。
  void save_authorized_login_list(List<Rotation> data) {
    loaded.value = true;
    final List<Rotation> sorted_list = List<Rotation>.from(data)
      ..sort((Rotation left, Rotation right) => right.sorting - left.sorting);
    rotation_list.assignAll(sorted_list);
  }
}
