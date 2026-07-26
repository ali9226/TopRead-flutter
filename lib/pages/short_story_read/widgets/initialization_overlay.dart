import 'package:flutter/material.dart';

/// 在不替换正文组件树的前提下显示初始化遮罩。
///
/// 正文会始终保留在 Stack 的第一个槽位，撤下遮罩时不会重新挂载内部
/// ScrollPosition，因此可安全保留初始化阶段恢复的阅读位置。
class ShortStoryInitializationOverlay extends StatelessWidget {
  /// 已经完成布局和阅读位置恢复的正文。
  final Widget content;

  /// 初始化期间覆盖正文的骨架层。
  final Widget overlay;

  /// 是否显示初始化遮罩。
  final bool show_overlay;

  const ShortStoryInitializationOverlay({
    super.key,
    required this.content,
    required this.overlay,
    required this.show_overlay,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        content,
        if (show_overlay) Positioned.fill(child: overlay),
      ],
    );
  }
}
