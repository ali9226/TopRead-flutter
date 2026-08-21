import 'package:get/get.dart';

import 'package:app/stores/project_config_store.dart';

/// 全应用统一广告展示策略。
///
/// 所有广告配置请求、SDK 初始化、广告加载和广告位渲染都必须通过
/// [can_show_ads] 判断。配置尚未从后端加载时按不可展示处理，避免在
/// `ads_switch` 尚未解析前提前请求广告。
class AdDisplayPolicy {
  const AdDisplayPolicy._();

  /// 启动阶段等待后端项目配置的最长时间。
  static const Duration config_wait_timeout = Duration(seconds: 10);

  /// 获取已注册的项目配置仓库。
  static ProjectConfigStore? get _store {
    if (!Get.isRegistered<ProjectConfigStore>()) return null;
    return Get.find<ProjectConfigStore>();
  }

  /// 后端广告开关是否已经完成首次解析。
  static bool is_config_resolved() {
    return _store?.is_config_loaded.value ?? false;
  }

  /// 当前平台是否允许展示广告。
  ///
  /// 配置未加载、仓库未注册或平台不匹配时均返回 false。
  static bool can_show_ads() {
    final ProjectConfigStore? store = _store;
    if (store == null || !store.is_config_loaded.value) return false;
    return store.current.is_ads_enabled;
  }

  /// 当前平台是否已经明确配置为不展示广告。
  ///
  /// 配置尚未加载时返回 false，避免把“未知”误当成“免广告”。
  static bool should_bypass_ads() {
    return is_config_resolved() && !can_show_ads();
  }

  /// 等待首次项目配置后返回当前平台的广告展示结果。
  ///
  /// 超时或仓库不存在时按不可展示处理。
  static Future<bool> wait_until_resolved({
    Duration timeout = config_wait_timeout,
  }) async {
    final ProjectConfigStore? store = _store;
    if (store == null) return false;
    final bool resolved = await store.wait_until_config_loaded(
      timeout: timeout,
    );
    return resolved && can_show_ads();
  }
}
