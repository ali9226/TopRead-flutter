import 'package:flutter/material.dart';
import 'package:app/components/app_wrapper/utils/app_router.dart';
import 'package:app/util/device/web_browser_info.dart';

/* TODO
 * BackAwarePage 是页面级的后退拦截包装器。
 *
 * 它存在的目的，是把"页面自己触发的 pop 行为"也统一接入全局后退策略。
 * 这类后退包括：
 *
 * 1. AppBar 默认返回箭头触发的 pop。
 * 2. Router 自己准备执行的页面 pop。
 * 3. 某些页面栈内部的返回动作。
 *
 * 它和 AppWrapper 里的系统级 backButtonDispatcher 不是重复关系，而是分层协作关系：
 * - Dispatcher 负责平台级返回事件，比如安卓底部返回按钮。
 * - BackAwarePage 负责页面级 pop 行为。
 *
 * 两边最后都汇总到 AppRouter.handleBack()，
 * 这样业务规则始终只有一份。
 */
class BackAwarePage extends StatelessWidget {
  // TODO 被包装的真实页面内容。
  final Widget child;

  const BackAwarePage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    /* TODO
     * 移动端浏览器上的 Chrome / Safari 需要统一禁用浏览器侧滑后退。
     *
     * 这里要保留 PopScope 的原因是：
     * 1. 侧滑后退本质上还是一次 pop 入口。
     * 2. 只有让页面显式声明 canPop=false，Flutter 才会拦住浏览器的侧滑返回。
     * 3. 业务允许返回时，仍然通过 AppRouter.handleBack() 统一控制是否回首页或直接退出。
     */
    final bool shouldDisableSwipeBack = isMobileWebChromeOrSafari();

    /* TODO
     * 当路由栈里已经存在历史页面时，默认不再额外挂 PopScope。
     *
     * 原因：
     * 1. iOS 的 Cupertino 交互式左缘侧滑返回，对"页面是否注册了额外的 pop 拦截器"非常敏感。
     * 2. 只要这里继续挂着 PopScope，即使 canPop 为 true，真机上也可能直接失去侧滑返回手势。
     * 3. 对于已经有历史栈的页面，我们本来就希望系统执行默认 pop，不需要再统一拦截。
     *
     * 但如果当前是移动端浏览器 Chrome / Safari，则必须继续包一层 PopScope，
     * 否则会放开浏览器侧滑后退。
     *
     * 重要：这里必须始终返回相同结构的 PopScope 组件树，
     * 只改变 canPop 属性，否则组件树结构变化会导致子组件重建，丢失状态。
     */
    final bool hasRouteHistory = AppRouter.canPop();
    final bool canPop = hasRouteHistory && !shouldDisableSwipeBack;

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) {
        // TODO didPop 为 true 说明这次后退已经完成，不需要再补任何逻辑。
        if (didPop) return;

        // TODO 如果允许默认 pop，直接返回，不拦截。
        if (canPop) return;

        /* TODO
         * 如果这是我们上一轮已经判定"允许后退"后发起的那次程序化 pop，
         * 就直接执行真实 pop，不再重新进入统一后退判断。
         *
         * 这一步是为了解决"同一轮后退判断被重复触发"的问题。
         */
        if (AppRouter.consumeBypassNextBackHandler()) {
          AppRouter.pop();
          return;
        }

        // TODO 返回 true 代表这次后退已经被处理或者明确拦截，到这里直接结束。
        if (AppRouter.handleBack()) {
          return;
        }

        /* TODO
         * 返回 false 代表业务允许这次后退继续发生。
         * 这里不立刻直接 pop，而是交给 AppRouter.popAfterAllow() 统一调度，
         * 这样程序化 pop 的时机和放行标记都由同一处管理。
         */
        AppRouter.popAfterAllow();
      },
      child: child,
    );
  }
}
