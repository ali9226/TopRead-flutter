// ignore_for_file: non_constant_identifier_names

import 'package:get/get.dart';
import 'package:app/models/rotation.dart';

/// 分享渠道全局状态。
///
/// 统一存储 redis/get 接口中 type=24 的分享渠道数据，
/// 供分享弹窗组件直接读取，无需每次单独请求。
class ShareStore extends GetxController {
  /// 接口返回的分享渠道列表。
  final RxList<Rotation> rotation_list = <Rotation>[].obs;

  /// 当前是否正在从远程获取分享渠道列表。
  final RxBool loading = false.obs;

  /// 是否已经至少完成过一次请求。
  final RxBool loaded = false.obs;

  /// 分享渠道接口固定业务类型。
  static const int share_type = 24;

  /// 保存分享渠道列表，并按排序值从大到小排列。
  void save_share_list(List<Rotation> data) {
    loaded.value = true;
    final List<Rotation> sorted_list = List<Rotation>.from(data)
      ..sort((Rotation left, Rotation right) => right.sorting - left.sorting);
    rotation_list.assignAll(sorted_list);
  }
}
