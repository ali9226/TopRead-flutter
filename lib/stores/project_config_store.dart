import 'package:get/get.dart';
import 'package:app/models/project_config.dart';

/// 项目配置仓库。
///
/// 统一缓存 `redis/get` 接口返回的 `project_config`，
/// 供各业务模块读取开关状态和名言内容。
class ProjectConfigStore extends GetxController {
  /// 当前项目配置。
  final Rx<ProjectConfig> config = ProjectConfig.empty().obs;

  /// 保存项目配置。
  ///
  /// [new_config] 为接口返回的最新配置数据。
  void save_config(ProjectConfig new_config) {
    config.value = new_config;
  }

  /// 获取当前配置。
  ProjectConfig get current => config.value;
}
