import 'package:flutter/material.dart';
import 'package:app/components/page_background_decor/style.dart';
import 'package:app/config/color_config.dart';

/// 页面公共背景装饰组件。
class PageBackgroundDecor extends StatelessWidget {
  /// 当前是否为夜间主题。
  final bool is_dark;

  const PageBackgroundDecor({super.key, required this.is_dark});

  @override
  Widget build(BuildContext context) {
    /// 装饰圆一垂直居中，向右推避免干扰渐变遮罩区域。
    final double screen_height = MediaQuery.of(context).size.height;
    final double circle_one_top =
        (screen_height - PageBackgroundDecorStyle.decor_circle_one_size) / 2;

    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: <Widget>[
            Positioned(
              top: circle_one_top,
              right: -70,
              child: Container(
                width: PageBackgroundDecorStyle.decor_circle_one_size,
                height: PageBackgroundDecorStyle.decor_circle_one_size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: is_dark
                      ? const Color(0xFFFFD45A).withValues(alpha: 0.13)
                      : ColorConstants.themeColor.withValues(alpha: 0.10),
                ),
              ),
            ),
            Positioned(
              top: PageBackgroundDecorStyle.decor_circle_two_top,
              left: PageBackgroundDecorStyle.decor_circle_two_left,
              child: Container(
                width: PageBackgroundDecorStyle.decor_circle_two_size,
                height: PageBackgroundDecorStyle.decor_circle_two_size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: is_dark
                      ? const Color(0xFF8DB7FF).withValues(alpha: 0.12)
                      : ColorConstants.themeColor.withValues(alpha: 0.06),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
