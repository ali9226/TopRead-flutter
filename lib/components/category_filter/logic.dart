import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app/stores/device_info.dart';
import 'package:app/stores/preference_store.dart';
import 'package:app/models/preference.dart';

/// 分类筛选逻辑控制器。
///
/// 管理分类筛选状态，包括：
/// 1. 当前选中的分类 id（单选模式）。
/// 2. 弹窗中的临时选中 id。
/// 3. 弹窗开关状态。
/// 4. 分类数据获取（从 PreferenceStore 获取 id=2 的分类列表）。
class CategoryFilterLogic {
  /// 当前选中的分类项 id（单选，null 表示未选中任何分类）。
  final Rxn<int> selected_category_id = Rxn<int>();

  /// 弹窗中临时选中的分类项 id（弹窗打开时复制自 selected_category_id）。
  final Rxn<int> temp_selected_id = Rxn<int>();

  /// 筛选弹窗是否打开。
  final RxBool is_filter_popup_open = false.obs;

  /// 弹窗当前的拖拽偏移量（用于下拉关闭手势）。
  final RxDouble popup_drag_offset = 0.0.obs;

  /// 当前页面上下文。
  final BuildContext context;

  CategoryFilterLogic(this.context, {int? initial_category_id}) {
    // 如果传入了初始分类 id，则设置为默认选中
    if (initial_category_id != null && initial_category_id > 0) {
      selected_category_id.value = initial_category_id;
    }
  }

  /// 获取全局主题状态。
  bool get is_dark {
    final DeviceInfo device_info = Get.find<DeviceInfo>();
    return device_info.theme.value == ThemeMode.dark;
  }

  /// 从 PreferenceStore 中获取 id=2 的分类列表。
  ///
  /// 返回 preference_list 中 id=2 的 Preference 对象的 data_list，
  /// 如果未找到则返回空列表。
  List<PreferenceItem> get category_list {
    final Preference? preference =
        Get.find<PreferenceStore>().find_preference_by_id(2);
    return preference?.data_list ?? <PreferenceItem>[];
  }

  /// 切换横栏分类标签的选中状态（单选）。
  ///
  /// [item_id] - 要切换的分类项 id。
  /// 如果点击已选中的分类则取消选中，否则选中该分类。
  void toggle_category(int item_id) {
    if (selected_category_id.value == item_id) {
      selected_category_id.value = null;
    } else {
      selected_category_id.value = item_id;
    }
  }

  /// 打开筛选弹窗。
  ///
  /// 将当前选中的分类 id 复制到临时变量中，
  /// 弹窗中的操作不会直接影响已选中的分类，
  /// 直到用户点击"确定"按钮才会提交更改。
  void open_filter_popup() {
    temp_selected_id.value = selected_category_id.value;
    is_filter_popup_open.value = true;
  }

  /// 关闭筛选弹窗。
  void close_filter_popup() {
    is_filter_popup_open.value = false;
    popup_drag_offset.value = 0.0;
  }

  /// 切换弹窗中分类的选中状态（单选）。
  ///
  /// [item_id] - 要切换的分类项 id。
  /// 如果点击已选中的分类则取消选中，否则选中该分类。
  void toggle_popup_category(int item_id) {
    if (temp_selected_id.value == item_id) {
      temp_selected_id.value = null;
    } else {
      temp_selected_id.value = item_id;
    }
  }

  /// 清空弹窗中所有已选分类。
  void clear_popup_selection() {
    temp_selected_id.value = null;
  }

  /// 确认弹窗中的选择，将临时选中 id 提交到正式选中 id。
  void confirm_popup_selection() {
    selected_category_id.value = temp_selected_id.value;
    close_filter_popup();
  }

  /// 当前是否有选中的分类。
  bool get has_selected => selected_category_id.value != null;
}
