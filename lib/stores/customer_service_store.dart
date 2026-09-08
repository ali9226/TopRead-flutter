// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:get/get.dart';
import 'package:app/models/rotation.dart';

/// 客服全局状态。
///
/// 统一在应用启动后拉取一次客服入口数据，
/// 供任意页面的客服公共组件直接读取。
class CustomerServiceStore extends GetxController {
  /// 接口返回的客服列表。
  final RxList<Rotation> rotation_list = <Rotation>[].obs;

  /// 当前是否正在请求。
  final RxBool loading = false.obs;

  /// 是否已经至少完成过一次请求。
  final RxBool loaded = false.obs;

  /// 客服接口固定业务类型。
  static const int customer_service_type = 21;

  /// 保存客服列表，并按排序值从大到小处理。
  void save_customer_service_list(List<Rotation> data) {
    loaded.value = true;
    final List<Rotation> sorted_list = List<Rotation>.from(data)
      ..sort((Rotation left, Rotation right) => right.sorting - left.sorting);
    rotation_list.assignAll(sorted_list);
  }
}
