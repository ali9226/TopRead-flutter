import 'package:flutter/material.dart';

/// Shell 内部单个常驻 tab 容器。
///
/// - inactive 时不销毁页面，只关闭交互和 ticker。
/// - 直接切换，无动画，避免闪烁。
class ShellTabPane extends StatelessWidget {
  /// 是否为当前激活的 tab。
  final bool active;

  /// 动画方向，true 表示从左侧滑入。
  final bool slideFromLeft;

  /// 子组件。
  final Widget child;

  const ShellTabPane({
    super.key,
    required this.active,
    required this.slideFromLeft,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !active,
      child: Offstage(
        offstage: !active,
        child: TickerMode(enabled: active, child: child),
      ),
    );
  }
}
