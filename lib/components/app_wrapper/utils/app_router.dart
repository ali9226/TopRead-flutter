import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/* TODO
 * AppRouter 是整个应用的路由访问门面。
 *
 * 这里故意把 GoRouter 实例和“统一后退处理器”都收口到一个静态类里，
 * 目的不是为了偷懒，而是为了让下面几种完全不同来源的后退动作，
 * 最终都能走到同一套判断逻辑：
 *
 * 1. 安卓系统底部后退按钮。
 * 2. 页面自定义的返回/关闭按钮。
 * 3. Flutter Router 默认触发的页面 pop。
 *
 * 这样做之后，业务只需要维护一份“后退时该怎么判断”的逻辑，
 * 而不用在每个页面里再各写一套 if/else。
 */
class AppRouter {
  // TODO 保存全局唯一的 GoRouter 实例，供任意位置统一调用。
  static late GoRouter _router;

  // TODO 显式路由变化通知器。
  // TODO 不依赖 GoRouter 内部某个监听点是否稳定，而是由 AppRouter 在每次统一路由操作后主动广播。
  static final ValueNotifier<int> _routeChangeNotifier = ValueNotifier<int>(0);

  // TODO 保存全局后退处理函数。
  // 返回 true 代表“这次后退已经处理完了，或者已经被拦截了”。
  // 返回 false 代表“允许继续执行默认后退”。
  static bool Function()? _backHandler;

  // TODO 这是一次性放行标记。
  // 某些场景里我们会先判断“允许后退”，然后再由代码手动执行一次 pop。
  // 如果不加这个标记，程序化 pop 又会重新回流到统一后退逻辑，形成重复判断。
  static bool _bypassNextBackHandler = false;

  // TODO 记录最近一次已广播的路由签名。
  // TODO 这样无论路由变化来自：
  // TODO 1. AppRouter.go / push / replace / pop
  // TODO 2. iOS 左缘侧滑返回
  // TODO 3. 其他系统级默认 pop
  // TODO 都能在真正发生变化时只广播一次。
  static String _lastRouteSignature = '';

  // TODO 记录最近一次正在处理的导航目标，避免快速连点把同一路由重复压栈。
  static String _pendingNavigationLocation = '';

  // TODO 当前导航锁是否生效。
  // TODO 锁的生命周期只覆盖“发起导航到下一帧稳定”这一小段时间，
  // TODO 目的是挡住同一轮手势连点，而不是长期阻止后续正常跳转。
  static bool _navigationLocked = false;

  /* TODO
   * 在 AppWrapper 初始化完成路由表之后，把真正的 GoRouter 注入进来。
   * 之后所有静态跳转方法，都会操作这一份 router。
   */
  static void setRouter(GoRouter router) {
    _router = router;
    _lastRouteSignature = _buildRouteSignature();
  }

  // TODO 暴露根 NavigatorState，供全局弹窗等不方便拿页面 context 的地方使用。
  static NavigatorState? navigatorState() {
    return _router.routerDelegate.navigatorKey.currentState;
  }

  // TODO 判断当前路由栈是否还存在可回退的历史页面。
  // TODO 这个能力会被页面级包装器用来决定：
  // TODO 1. 当前页是否允许系统直接执行默认 pop。
  // TODO 2. iOS 左缘侧滑返回手势是否应该保持可用。
  static bool canPop() {
    return _router.canPop();
  }

  /* TODO
   * 注册统一后退处理器。
   *
   * 这里约定了整个应用统一的后退语义：
   * - 返回 true：本次后退已经处理完成，或者明确要拦截，不要再继续默认后退。
   * - 返回 false：本次后退允许继续执行默认后退。
   *
   * 这个约定非常重要，因为系统后退、自定义返回按钮、页面 PopScope
   * 都是围绕这一个语义来协作的。
   */
  static void setBackHandler(bool Function() handler) {
    _backHandler = handler;
  }

  /* TODO
   * 页面树销毁时清理处理器引用，避免旧 State 的闭包继续被错误调用。
   */
  static void clearBackHandler() {
    _backHandler = null;
  }

  /* TODO
   * 执行统一后退判断。
   *
   * 这里不直接做任何 UI 或路由判断，只负责把调用转发给注册进来的处理函数。
   * 这样 AppRouter 自己只负责“组织流程”，具体业务规则仍由 AppWrapper 维护。
   */
  static bool handleBack() {
    return _backHandler?.call() ?? false;
  }

  /* TODO
   * 消费一次“程序化 pop 放行”标记。
   *
   * 返回 true 时，说明当前这次 pop 是我们自己刚刚安排的那一次真实后退，
   * 不应该再次进入统一后退判断，否则会出现：
   * - 明明已经允许后退
   * - 结果真正 pop 时又被拦截器重新拦了一次
   *
   * 这个方法只会放行一次，调用后立即把标记复位。
   */
  static bool consumeBypassNextBackHandler() {
    if (_bypassNextBackHandler) {
      _bypassNextBackHandler = false;
      return true;
    }
    return false;
  }

  /* TODO
   * 获取当前真实 path。
   *
   * 这里统一从 routeInformationProvider 读取，而不是从
   * currentConfiguration.last.route.path 之类的嵌套路由结构里猜。
   * 原因是 ShellRoute/嵌套路由场景下，后者有机会和用户眼前真正所在的页面不一致。
   */
  static String currentPath() {
    try {
      return _router.routeInformationProvider.value.uri.path;
    } catch (_) {
      return '';
    }
  }

  // TODO 获取当前完整 location（包含 query），用于同路由去重。
  // TODO 这里优先使用 GoRouter 当前栈顶匹配结果，而不是浏览器/平台 URL。
  // TODO 原因：push 到 /login 这类 imperative 路由时，URL 可能仍停留在 '/'，
  // TODO 如果直接用 URL 判断“当前已在 /”，会误判并跳过真正需要执行的导航。
  static String currentLocation() {
    try {
      final dynamic configuration = _router.routerDelegate.currentConfiguration;
      if (configuration != null && configuration.isNotEmpty == true) {
        final dynamic lastMatch = configuration.last;
        final dynamic matchedLocation = lastMatch?.matchedLocation;
        if (matchedLocation is String && matchedLocation.isNotEmpty) {
          final dynamic uri = lastMatch?.uri;
          if (uri != null) {
            final String location = uri.toString();
            if (location.isNotEmpty) {
              return location;
            }
          }
          return matchedLocation;
        }
      }
      return _router.routeInformationProvider.value.uri.toString();
    } catch (_) {
      return '';
    }
  }

  // TODO 获取当前真实路由名。
  // TODO 在当前项目里，嵌套路由 / ShellRoute 场景下，route.name 比 path 更稳定。
  static String currentRouteName() {
    try {
      final configuration = _router.routerDelegate.currentConfiguration;
      if (configuration.isEmpty) {
        return '';
      }
      return configuration.last.route.name ?? '';
    } catch (_) {
      return '';
    }
  }

  // TODO 暴露统一的路由变化通知器。
  static Listenable routeChangeListenable() {
    return _routeChangeNotifier;
  }

  // TODO 给外部路由监听器调用的同步入口。
  // TODO 当系统自己完成了一次 pop（例如 iOS 侧滑返回）时，
  // TODO 调用方可以执行这个方法，把“真实已经变化的当前路由”同步广播给监听者。
  static void syncRouteChange() {
    final String nextSignature = _buildRouteSignature();
    if (nextSignature == _lastRouteSignature) {
      return;
    }
    _lastRouteSignature = nextSignature;
    _notifyRouteChanged();
  }

  // TODO 生成一个足够稳定的路由签名，供同步逻辑判断当前页是否真的变了。
  static String _buildRouteSignature() {
    final String routeName = currentRouteName();
    final String routePath = currentPath();
    return '$routeName|$routePath';
  }

  // TODO 在路由动作真正执行后，异步广播一次“当前路由可能已变化”。
  // TODO 使用 microtask 是为了让监听方拿到已经更新完成的当前 path。
  static void _notifyRouteChanged() {
    scheduleMicrotask(() {
      _routeChangeNotifier.value++;
    });
  }

  // TODO 当前这次导航是否应该直接忽略。
  static bool _shouldSkipNavigation(String location) {
    if (location.isEmpty) {
      return true;
    }

    final String current = currentLocation();
    if (current == location) {
      return true;
    }

    if (_navigationLocked && _pendingNavigationLocation == location) {
      return true;
    }

    return false;
  }

  // TODO 进入一次很短的导航锁，阻止同一路由在一帧内被重复触发。
  static void _lockNavigation(String location) {
    _navigationLocked = true;
    _pendingNavigationLocation = location;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigationLocked = false;
      _pendingNavigationLocation = '';
    });
  }

  // TODO 全局替换到指定路由。
  static void go(String location) {
    if (_shouldSkipNavigation(location)) {
      return;
    }
    _lockNavigation(location);
    _router.go(location);
    _notifyRouteChanged();
  }

  // TODO 在当前栈顶继续压入一个新路由。
  static void push(String location) {
    if (_shouldSkipNavigation(location)) {
      return;
    }
    _lockNavigation(location);
    _router.push(location);
    _notifyRouteChanged();
  }

  // TODO 用新路由替换当前路由。
  static void replace(String location) {
    if (_shouldSkipNavigation(location)) {
      return;
    }
    _lockNavigation(location);
    _router.replace(location);
    _notifyRouteChanged();
  }

  // TODO 直接执行一次原始 pop，调用前通常应当已经完成过统一后退判断。
  static void pop() {
    if (_router.canPop()) {
      _router.pop();
      _notifyRouteChanged();
    }
  }

  /* TODO
   * 在已经判定“允许后退”之后，异步安排一次真正的 pop。
   *
   * 这里选择 microtask，而不是立刻在当前回调里 pop，原因有两个：
   * 1. 避免和 PopScope 当前这一轮生命周期冲突。
   * 2. 让“先判断，再执行真实后退”这个过程更稳定，不容易出现重复回调。
   *
   * 同时我们会先打上 _bypassNextBackHandler 标记，
   * 确保紧接着发生的那次程序化 pop 不会再次进入统一后退判断。
   */
  static void popAfterAllow() {
    if (!_router.canPop()) return;
    _bypassNextBackHandler = true;
    scheduleMicrotask(() {
      if (_router.canPop()) {
        _router.pop();
        _notifyRouteChanged();
      } else {
        _bypassNextBackHandler = false;
      }
    });
  }

  /* TODO
   * 提供给自定义返回按钮使用的统一后退入口。
   *
   * 流程非常明确：
   * 1. 先问全局处理器，这次后退要不要拦截。
   * 2. 如果处理器返回 true，说明业务已经自己处理了，这里直接结束。
   * 3. 如果处理器返回 false，说明允许后退，这里再去安排一次真实 pop。
   *
   * 这样页面里的按钮只需要调用 AppRouter.back()，
   * 而不需要关心当前是在首页、是否有弹窗、是否需要双击退出这些细节。
   */
  static void back() {
    if (handleBack()) return;
    popAfterAllow();
  }
}
