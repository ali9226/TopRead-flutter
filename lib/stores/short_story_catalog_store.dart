import 'package:get/get.dart';
import 'package:app/models/short_story_item.dart';

/// 短篇小说目录列表全局 Store。
///
/// 用于在短篇阅读页面中持久化目录列表数据，
/// 避免弹窗关闭后数据丢失。
///
/// 生命周期：
/// - 进入短篇阅读页面时初始化
/// - 在页面内切换小说时保留已加载的目录数据
/// - 退出短篇阅读页面时清空
class ShortStoryCatalogStore extends GetxController {
  /// 目录列表数据。
  final RxList<ShortStoryItem> catalog_list = <ShortStoryItem>[].obs;

  /// 目录列表是否正在加载中。
  final RxBool is_loading = true.obs;

  /// 目录列表是否加载失败。
  final RxBool is_error = false.obs;

  /// 是否还有更多数据可加载。
  bool _has_more = true;

  /// 获取是否还有更多数据。
  bool get has_more => _has_more;

  /// 设置是否还有更多数据。
  set has_more(bool value) {
    _has_more = value;
  }

  /// 设置目录列表数据（替换现有数据）。
  void set_catalog_list(List<ShortStoryItem> list) {
    catalog_list.assignAll(list);
  }

  /// 追加目录列表数据（加载更多时使用）。
  void append_catalog_list(List<ShortStoryItem> list) {
    catalog_list.addAll(list);
  }

  /// 检查指定 ID 的小说是否已在列表中。
  bool contains_story(int story_id) {
    return catalog_list.any((ShortStoryItem item) => item.id == story_id);
  }

  /// 获取指定 ID 的小说在列表中的索引，不存在返回 -1。
  int index_of_story(int story_id) {
    return catalog_list.indexWhere((ShortStoryItem item) => item.id == story_id);
  }

  /// 确保指定小说在列表首位（如果不存在则插入）。
  void ensure_story_at_first(ShortStoryItem story) {
    final int index = index_of_story(story.id);
    if (index == 0) return;

    if (index > 0) {
      catalog_list.removeAt(index);
    }
    catalog_list.insert(0, story);
  }

  /// 清空目录列表数据。
  void clear() {
    catalog_list.clear();
    _has_more = true;
    is_loading.value = true;
    is_error.value = false;
  }
}
