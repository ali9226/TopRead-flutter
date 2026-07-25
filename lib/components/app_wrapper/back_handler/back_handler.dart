import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/components/app_wrapper/utils/app_router.dart';
import 'package:app/stores/bottom_navigation_info.dart';
import 'package:app/util/dialog/show_bottom_tip.dart';
import 'package:app/util/log_util.dart';
import 'package:app/util/router/web_history.dart';

/// 核心后退判断逻辑。
///
/// 整个应用唯一的核心后退判断函数：
/// - 返回 false：允许继续默认后退。
/// - 返回 true：拦截默认后退，或者本次后退已由这里自己处理完成。
///
/// 所有后退入口都依赖这份返回值约定：
/// - 安卓系统底部返回按钮
/// - 系统返回按钮
/// - 自定义返回按钮
/// - 页面默认 pop
class BackHandler {
  /// 上一次在首页点击后退的时间，用于实现"双击退出应用"。
  static DateTime? _lastBackPressedTime;

  /// 处理后退事件。
  ///
  /// [bottomNavigationInfo] 底部导航状态控制器。
  /// 返回 true 表示已处理，false 表示允许继续后退。
  static bool handleBack(BottomNavigationInfo bottomNavigationInfo) {
    logUtil(msg: "核心返回逻辑", type: "d");

    // 如果当前有全局确认弹层正在展示，优先关闭弹层。
    if (bottomNavigationInfo.showMessageState.value) {
      bottomNavigationInfo.changeShowMessageState(false);
      return true;
    }

    // 定义"双击退出"的时间窗口。
    const int seconds = 3;

    // 如果底部导航面板当前处于展开状态，优先收起面板。
    if (bottomNavigationInfo.expandedState.value) {
      logUtil(msg: "如果底部导航展开，先收起", type: "d");
      _lastBackPressedTime = null;
      bottomNavigationInfo.changeExpandedState(false);
      return true;
    }

    // 读取 GoRouter 当前 URI 的 path。
    final uri = AppRouter.currentPath();
    final now = DateTime.now();
    logUtil(msg: "地址:$uri");

    // 如果路由栈里还有历史页面，允许默认后退。
    if (AppRouter.canPop()) {
      _lastBackPressedTime = null;
      logUtil(msg: "有历史路由记录，允许默认后退", type: "d");
      return false;
    }

    // Web 浏览器 history 判断。
    if (kIsWeb && uri != '/' && hasBrowserHistory()) {
      _lastBackPressedTime = null;
      logUtil(msg: "Web 浏览器历史可后退，允许继续执行浏览器回退", type: "d");
      return false;
    }

    // 没有历史记录且不在首页，先手动回首页。
    if (uri != '/') {
      AppRouter.replace('/');
      _lastBackPressedTime = null;
      logUtil(msg: "没有历史记录且当前不在首页，返回首页");
      return true;
    }

    // 当前在首页，处理"双击返回退出应用"。
    if (_lastBackPressedTime == null ||
        now.difference(_lastBackPressedTime!) > Duration(seconds: seconds)) {
      _lastBackPressedTime = now;
      showBottomTip(easy.tr('back.exit_prompt'));
      logUtil(msg: "当前在首页，首次后退，提示用户再次后退退出");
      return true;
    }

    // 3 秒内再次点击后退，退出应用。
    SystemNavigator.pop();
    logUtil(msg: "当前在首页，3秒内再次后退，直接退出");
    return true;
  }
}
