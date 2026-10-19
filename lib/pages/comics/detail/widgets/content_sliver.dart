// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;

import 'package:app/components/window_content_layout/index.dart';
import 'package:flutter/material.dart';

/// 目录保持 Sliver 懒构建，仅避让安全区并限制正文宽度，封面不参与限宽。
class ComicDetailContentSliver extends StatelessWidget {
  const ComicDetailContentSliver({super.key, required this.child});

  /// 原始目录 Sliver，内部的章节间距和样式保持不变。
  final Widget child;

  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
    builder: (context, constraints) {
      final safe_padding = MediaQuery.paddingOf(context);
      final available_width = math.max(
        0.0,
        constraints.crossAxisExtent - safe_padding.horizontal,
      );
      final content_width = math.min(
        available_width,
        WindowLayoutScope.max_width_of(context),
      );
      final center_inset = (available_width - content_width) / 2;
      return SliverPadding(
        padding: EdgeInsets.only(
          left: safe_padding.left + center_inset,
          right: safe_padding.right + center_inset,
        ),
        sliver: child,
      );
    },
  );
}
