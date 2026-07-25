import 'package:flutter/material.dart';
import 'package:app/components/app_wrapper/utils/app_router.dart';
import 'package:app/pages/top_up/index.dart';

/// TODO 路由页面级预构建器。
/// 作用：
/// 1. 把首进最重的二级页先在后台构建一次，提前吃掉布局和首帧渲染成本。
/// 2. 只预热页面 UI 壳层，不触发接口请求、WebSocket 或业务副作用。
/// 3. 当前优先覆盖用户体感最明显的 `/top_up`。
class RoutePageWarmUp {
  static bool _hasStarted = false;

  static Future<void> warmUpAfterFirstFrame({BuildContext? context}) async {
    if (_hasStarted) return;

    final OverlayState? overlayState =
        AppRouter.navigatorState()?.overlay ??
        (context == null ? null : Overlay.maybeOf(context, rootOverlay: true));
    if (overlayState == null) return;

    _hasStarted = true;

    await _warmUpEntry(
      overlayState: overlayState,
      child: const TopUp.warm_up(),
    );
  }

  static Future<void> _warmUpEntry({
    required OverlayState overlayState,
    required Widget child,
  }) async {
    late final OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (BuildContext overlayContext) {
        return IgnorePointer(
          child: Offstage(
            child: MediaQuery(
              // TODO 复用当前环境的 MediaQuery，避免预构建和真实显示时布局差异过大。
              data: MediaQuery.of(overlayContext),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: child,
              ),
            ),
          ),
        );
      },
    );

    overlayState.insert(overlayEntry);
    await Future<void>.delayed(const Duration(milliseconds: 48));
    overlayEntry.remove();
    await Future<void>.delayed(const Duration(milliseconds: 32));
  }
}
