import 'package:flutter/widgets.dart';

/// 应用级系统返回分发器。
///
/// 负责平台级返回事件的统一入口：
/// - 安卓底部后退按钮
/// - 系统返回按钮
///
/// 和 BackAwarePage 的职责边界：
/// - AppBackButtonDispatcher：处理平台级 back 事件。
/// - BackAwarePage：处理页面级 pop 行为。
///
/// 两者都先调用同一个 onBackPressed，确保规则一致。
class AppBackButtonDispatcher extends RootBackButtonDispatcher {
  /// 业务方提供的统一后退处理器。
  /// 返回 true 表示已处理或拦截，false 表示允许继续后退。
  final bool Function() onBackPressed;

  /// 当业务层返回 false 时，执行真正的默认后退。
  final bool Function() onDefaultBack;

  AppBackButtonDispatcher({
    required this.onBackPressed,
    required this.onDefaultBack,
  });

  @override
  Future<bool> invokeCallback(Future<bool> defaultValue) {
    // 先把系统后退交给业务层判断。
    final handled = onBackPressed();
    if (handled) {
      return Future<bool>.value(true);
    }

    // 业务层未拦截时，再执行默认后退逻辑。
    final defaultHandled = onDefaultBack();
    if (defaultHandled) {
      return Future<bool>.value(true);
    }

    // 如果连默认后退也没有处理掉，则回退到 Flutter 默认实现。
    return defaultValue;
  }
}
