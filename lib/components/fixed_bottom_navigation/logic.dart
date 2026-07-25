// ignore_for_file: non_constant_identifier_names

import 'package:get/get.dart';
import 'package:app/components/app_wrapper/utils/app_router.dart';
import 'package:app/stores/shell_tab_info.dart';

/// `FixedBottomNavigation` 的交互逻辑对象。
///
/// 当前只负责路由切换相关行为：
/// 1. 同步更新 `ShellTabInfo`；
/// 2. 避免重复跳转当前页面；
/// 3. 让 `index.dart` 保持纯 UI 组织。
class Logic {
  /// Shell 层级的 tab 状态仓库。
  final ShellTabInfo shell_tab_info = Get.find<ShellTabInfo>();

  /// 切换到底部导航目标页面。
  ///
  /// 参数：
  /// - `path`：目标路由路径。
  void go_to(String path) {
    if (AppRouter.currentPath() == path) {
      shell_tab_info.updateActivePath(path);
      return;
    }
    shell_tab_info.updateActivePath(path);
    AppRouter.go(path);
  }
}
