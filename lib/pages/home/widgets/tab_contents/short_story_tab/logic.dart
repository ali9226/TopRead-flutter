import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app/api/post_request.dart';
import 'package:app/api/results_type.dart';
import 'package:app/models/short_story_item.dart';
import 'package:app/stores/device_info.dart';
import 'package:app/stores/preference_store.dart';
import 'package:app/models/preference.dart';

/// 短篇 Tab 逻辑层。
///
/// 负责管理分类筛选状态、弹窗状态和短篇小说数据请求。
/// 分类数据来源于 preference_list 中 id=2 的 data_list 数组。
class ShortStoryTabLogic {
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

  ShortStoryTabLogic(this.context);

  /// 获取全局主题状态。
  bool get is_dark {
    final DeviceInfo device_info = Get.find<DeviceInfo>();
    return device_info.theme.value == ThemeMode.dark;
  }

  /// 从 PreferenceStore 中获取 id=2 的分类列表。
  List<PreferenceItem> get category_list {
    final Preference? preference =
        Get.find<PreferenceStore>().find_preference_by_id(2);
    return preference?.data_list ?? <PreferenceItem>[];
  }

  /// 切换横栏分类标签的选中状态（单选）。
  void toggle_category(int item_id) {
    if (selected_category_id.value == item_id) {
      selected_category_id.value = null;
    } else {
      selected_category_id.value = item_id;
    }
    _on_category_changed(item_id);
  }

  /// 分类切换时触发的事件。
  void _on_category_changed(int item_id) {
    final List<PreferenceItem> list = category_list;
    final PreferenceItem? item = list.cast<PreferenceItem?>().firstWhere(
          (PreferenceItem? e) => e?.id == item_id,
          orElse: () => null,
        );
    debugPrint('短篇分类切换: ${item?.title ?? "未知分类"} (id=$item_id)');
  }

  /// 打开筛选弹窗。
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

    if (selected_category_id.value != null) {
      _on_category_changed(selected_category_id.value!);
    } else {
      debugPrint('短篇分类切换: 未选择任何分类');
    }
  }

  /// 当前是否有选中的分类。
  bool get has_selected => selected_category_id.value != null;

  /// 请求短篇小说列表接口。
  ///
  /// [no_ids] - 已加载的 id 列表，用于排除已展示的数据（加载更多场景）。
  /// [category_id] - 筛选的分类 id，不传则返回全部分类。
  ///
  /// 返回解析后的短篇小说列表，请求失败时返回空列表。
  Future<List<ShortStoryItem>> fetch_short_story_list({
    List<int>? no_ids,
    int? category_id,
  }) async {
    final ResultsType<List<ShortStoryItem>> results = await postRequest<List<ShortStoryItem>>(
      path: 'novel/short_story',
      parameter: <String, dynamic>{
        if (no_ids != null && no_ids.isNotEmpty) 'no_ids': no_ids,
        if (category_id != null) 'category_id': category_id,
      },
      fromJsonList: (List<dynamic> json) => ShortStoryItem.from_json_list(json),
    );

    if (!results.status || results.content == null) {
      return <ShortStoryItem>[];
    }

    return results.content!;
  }

  /// 点击点赞/取消点赞接口。
  ///
  /// [novel_id] - 小说的唯一标识。
  ///
  /// 返回接口返回的 like 值：
  /// - `true` 表示原本未点赞，现已点赞。
  /// - `false` 表示原本已点赞，现已取消点赞。
  /// - `null` 表示请求失败。
  Future<bool?> click_novel_like({required int novel_id}) async {
    final ResultsType<Map<String, dynamic>> results = await postRequest<Map<String, dynamic>>(
      path: 'novel_like/click',
      parameter: <String, dynamic>{
        'novel_id': novel_id,
      },
      fromJson: (Map<String, dynamic> json) => json,
    );

    if (!results.status || results.content == null) {
      return null;
    }

    return results.content!['like'] == true;
  }
}
