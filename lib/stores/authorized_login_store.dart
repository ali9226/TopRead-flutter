// ignore_for_file: non_constant_identifier_names

import 'package:get/get.dart';
import 'package:app/models/rotation.dart';

/// 第三方授权登录全局状态。
class AuthorizedLoginStore extends GetxController {
  /// 接口返回的授权登录列表。
  final RxList<Rotation> rotation_list = <Rotation>[].obs;

  /// 当前是否正在执行授权登录请求（如 Google/Telegram 登录过程）。
  final RxBool loading = false.obs;

  /// 当前是否正在从远程获取授权登录方式列表。
  final RxBool is_fetching_list = false.obs;

  /// 当前正在执行授权登录的平台。
  final RxString loading_platform = ''.obs;

  /// 是否已经至少完成过一次请求。
  final RxBool loaded = false.obs;

  /// 保存授权登录列表，并按排序值从大到小处理。
  void save_authorized_login_list(List<Rotation> data) {
    loaded.value = true;
    final List<Rotation> sorted_list = List<Rotation>.from(data)
      ..sort((Rotation left, Rotation right) => right.sorting - left.sorting);
    rotation_list.assignAll(sorted_list);
  }
}
