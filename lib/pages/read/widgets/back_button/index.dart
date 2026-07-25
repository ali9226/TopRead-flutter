import 'package:flutter/material.dart';
import 'package:app/components/app_wrapper/utils/app_router.dart';
import 'package:app/components/svg_icon/index.dart';
import 'style.dart';

/// 顶部返回按钮组件。
///
/// 功能：
/// 1. 点击后执行 `AppRouter.back()` 返回上一页。
/// 2. 随页面内容一起滚动（需放置在滚动容器内）。
/// 3. 移除圆圈包裹，仅显示图标。
class ReadBackButton extends StatelessWidget {
  /// 是否为夜间模式。
  final bool is_dark;

  const ReadBackButton({super.key, required this.is_dark});

  @override
  Widget build(BuildContext context) {
    // 根据当前主题模式决定图标和背景颜色。
    final Color icon_color = is_dark
        ? BackButtonStyle.night_icon_color
        : BackButtonStyle.light_icon_color;
    final Color background_color = is_dark
        ? Colors.white.withValues(
            alpha: BackButtonStyle.night_background_opacity,
          )
        : Colors.black.withValues(
            alpha: BackButtonStyle.light_background_opacity,
          );

    return GestureDetector(
      onTap: () => AppRouter.back(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: BackButtonStyle.button_size,
        height: BackButtonStyle.button_size,
        alignment: Alignment.centerLeft,
        child: Container(
          width: BackButtonStyle.circle_size,
          height: BackButtonStyle.circle_size,
          decoration: BoxDecoration(
            color: background_color,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: RotatedBox(
            quarterTurns: 2,
            child: SvgIcon(
              name: 'right',
              width: BackButtonStyle.icon_size,
              height: BackButtonStyle.icon_size,
              color: icon_color,
            ),
          ),
        ),
      ),
    );
  }
}
