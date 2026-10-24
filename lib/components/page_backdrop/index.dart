import 'package:flutter/material.dart';

import 'style.dart';

/// 整页渐变底板层，必须放在 Stack 的 children 中。
///
/// 铺满父级并绘制自上而下的线性渐变，统一各页面背景渐变的方向与绘制方式。
class PageBackdropGradient extends StatelessWidget {
  const PageBackdropGradient({super.key, required this.colors});

  /// 渐变色组，按从上到下的顺序排列。
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: PageBackdropStyle.gradient_begin,
            end: PageBackdropStyle.gradient_end,
            colors: colors,
          ),
        ),
      ),
    );
  }
}
