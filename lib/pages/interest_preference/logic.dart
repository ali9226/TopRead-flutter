import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app/api/post_request.dart';
import 'package:app/api/results_type.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/preference_store.dart';
import 'package:app/models/preference.dart';
import 'package:app/models/user_preference_inquire.dart';

/// 兴趣偏好页面逻辑层。
///
/// 管理主题切换（响应式）和偏好选择状态（非响应式，由页面 setState 驱动）。
class InterestPreferenceLogic {
  /// 当前是否为夜间模式。
  bool get is_dark {
    final DeviceInfo device_info = Get.find<DeviceInfo>();
    return device_info.theme.value == ThemeMode.dark;
  }

  /// 获取偏好类别列表。
  List<Preference> get preference_list =>
      Get.find<PreferenceStore>().preference_list;

  /// 切换标签选中状态。
  ///
  /// 返回更新后的选中 id 集合，由调用方通过 setState 驱动 UI 重建。
  /// 根据 [preference] 的 single_select 决定单选或多选行为。
  Set<int> toggle({
    required Preference preference,
    required int item_id,
    required Set<int> current_selected,
  }) {
    final bool is_single = preference.is_single_select;

    if (is_single) {
      return _toggle_single(item_id: item_id, current_selected: current_selected);
    } else {
      return _toggle_multi(item_id: item_id, current_selected: current_selected);
    }
  }

  /// 切换单选（再次点击取消，否则替换）。
  Set<int> _toggle_single({
    required int item_id,
    required Set<int> current_selected,
  }) {
    if (current_selected.contains(item_id)) {
      return <int>{};
    }
    return <int>{item_id};
  }

  /// 切换多选（追加或移除）。
  Set<int> _toggle_multi({
    required int item_id,
    required Set<int> current_selected,
  }) {
    final Set<int> next = Set<int>.from(current_selected);
    if (next.contains(item_id)) {
      next.remove(item_id);
    } else {
      next.add(item_id);
    }
    return next;
  }

  /// 保存用户选择的偏好。
  ///
  /// 从选中映射 [selectedMap] 中收集所有已选中的选项 id，
  /// 调用 user_preference/choose 接口提交。
  /// 返回 true 表示保存成功，false 表示保存失败。
  Future<bool> save(Map<int, Set<int>> selectedMap) async {
    // 收集所有已选中的选项 id，合并为一个列表。
    final List<int> ids = <int>[];
    for (final Set<int> selectedSet in selectedMap.values) {
      ids.addAll(selectedSet);
    }

    // 调用接口提交偏好选择。
    final ResultsType<dynamic> results = await postRequest<dynamic>(
      path: 'user_preference/choose',
      parameter: <String, dynamic>{
        'ids': ids,
      },
    );

    return results.status;
  }

  /// 查询用户已选择的偏好。
  ///
  /// 调用 user_preference/user_inquire 接口获取用户已保存的偏好 id 列表。
  /// 返回 id 列表，查询失败时返回空列表。
  Future<List<int>> fetch_user_preferences() async {
    final ResultsType<UserPreferenceInquire> results =
        await postRequest<UserPreferenceInquire>(
      path: 'user_preference/user_inquire',
      fromJson: (json) => UserPreferenceInquire.from_json(json),
    );

    if (!results.status || results.content == null) {
      return <int>[];
    }

    return results.content!.ids;
  }
}
