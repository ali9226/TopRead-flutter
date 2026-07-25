// ignore_for_file: non_constant_identifier_names

import 'dart:async';

/// 入口点击锁：
///
/// 用于“同一个导航/入口动作在极短时间内只执行一次”。
/// 适合这些场景：
/// 1. 用户快速连点同一个入口按钮；
/// 2. 入口里除了跳路由，还会先做异步校验、弹窗或请求；
/// 3. 需要在页面间复用同一套去重策略。
final Set<String> _navigation_action_lock_keys = <String>{};

/// 按 [actionKey] 对入口动作做一次性串行保护。
///
/// 同一个 [actionKey] 在上一次动作完成前再次触发，会被直接忽略。
Future<void> run_navigation_action_once({
  required String actionKey,
  required FutureOr<void> Function() action,
}) async {
  if (actionKey.isEmpty) {
    await action();
    return;
  }
  if (_navigation_action_lock_keys.contains(actionKey)) {
    return;
  }

  _navigation_action_lock_keys.add(actionKey);
  try {
    await action();
  } finally {
    _navigation_action_lock_keys.remove(actionKey);
  }
}
