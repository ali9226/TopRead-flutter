import 'package:get/get.dart';
import 'package:app/models/preference.dart';

/* TODO
 * 偏好数据全局状态仓库。
 *
 * 统一缓存 `redis/get` 接口返回的 `preference_list`，
 * 供偏好设置页、推荐筛选等页面复用。
 */
class PreferenceStore extends GetxController {
  /// TODO 原始偏好类别列表。
  final RxList<Preference> preference_list = <Preference>[].obs;

  /// TODO 是否已完成至少一次数据加载。
  final RxBool loaded = false.obs;

  /// TODO 是否正在加载/刷新数据（用于展示骨架屏）。
  final RxBool is_loading = false.obs;

  /// TODO 保存偏好类别列表。
  ///
  /// 参数 [data]：
  /// 接口返回的偏好类别列表，由 `RedisRequestStore` 分发调用。
  void save_preference_list(List<Preference> data) {
    preference_list.assignAll(data);
    loaded.value = true;
    is_loading.value = false;
  }

  /// TODO 根据类别 id 查找对应的偏好类别。
  ///
  /// 参数 [id]：
  /// 偏好类别 id。
  ///
  /// 返回匹配的 [Preference]，未找到时返回 null。
  Preference? find_preference_by_id(int id) {
    for (final Preference item in preference_list) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// TODO 获取所有单选偏好类别。
  List<Preference> get single_select_list {
    return preference_list
        .where((Preference item) => item.is_single_select)
        .toList();
  }

  /// TODO 获取所有多选偏好类别。
  List<Preference> get multi_select_list {
    return preference_list
        .where((Preference item) => !item.is_single_select)
        .toList();
  }
}
