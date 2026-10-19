// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'index.dart' show WindowLayoutData;

/// 系统 AppBar 自己绘制满宽背景，只让内部导航内容避让顶角系统区域。
///
/// 仅增加 actionsPadding 会遗漏没有 actions 的标题和左侧系统遮挡。
/// 在顶栏局部恢复 SafeArea，让 Flutter 同时正确安排 leading、title、
/// actions 和 bottom；正文的 MediaQuery 仍保持完整可用宽度。
class WindowAppBar extends StatelessWidget implements PreferredSizeWidget {
  const WindowAppBar({super.key, required this.child});

  final AppBar child;

  @override
  Size get preferredSize => child.preferredSize;

  @override
  Widget build(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<WindowLayoutData>();
    if (scope?.has_local_edge != true) return child;
    final media = MediaQuery.of(context);
    final insets = scope!.edge_insets;
    return MediaQuery(
      data: media.copyWith(
        padding: media.padding.copyWith(
          left: math.max(media.padding.left, insets.left),
          right: math.max(media.padding.right, insets.right),
        ),
        viewPadding: media.viewPadding.copyWith(
          left: math.max(media.viewPadding.left, insets.left),
          right: math.max(media.viewPadding.right, insets.right),
        ),
      ),
      child: child,
    );
  }
}
