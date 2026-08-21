import 'dart:async';

import 'package:get/get.dart';
import 'package:app/models/project_config.dart';

/// 项目配置仓库。
///
/// 统一缓存 `redis/get` 接口返回的 `project_config`，
/// 供各业务模块读取开关状态和名言内容。
class ProjectConfigStore extends GetxController {
  /// 当前项目配置。
  final Rx<ProjectConfig> config = ProjectConfig.empty().obs;

  /// 是否已经收到至少一次后端项目配置。
  final RxBool is_config_loaded = false.obs;

  /// 项目配置版本；每次完整保存后递增，供跨页面策略监听。
  final RxInt config_revision = 0.obs;

  /// 首次项目配置加载完成信号。
  final Completer<void> _first_config_completer = Completer<void>();

  /// 保存项目配置。
  ///
  /// [new_config] 为接口返回的最新配置数据。
  void save_config(ProjectConfig new_config) {
    config.value = new_config;
    is_config_loaded.value = true;
    config_revision.value++;
    if (!_first_config_completer.isCompleted) {
      _first_config_completer.complete();
    }
  }

  /// 获取当前配置。
  ProjectConfig get current => config.value;

  /// 等待首次项目配置完成加载。
  ///
  /// [timeout] 为最大等待时间；超时返回 false，调用方应按广告关闭处理。
  Future<bool> wait_until_config_loaded({required Duration timeout}) async {
    if (is_config_loaded.value) return true;
    try {
      await _first_config_completer.future.timeout(timeout);
      return is_config_loaded.value;
    } on TimeoutException {
      return false;
    }
  }
}
