import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';

/// 返回顶部悬浮按钮。
///
/// 用途：
/// 1. 作为页面右下角的快捷操作入口。
/// 2. 当页面内容很多、用户已经向下滚动较远时，提供一个明确的“返回顶部”操作。
/// 3. 视觉上保持为一个独立的悬浮按钮，方便在多个路由页面中复用。
class BackToTopButton extends StatelessWidget {
  /// 当前是否为夜间模式。
  ///
  /// 作用：
  /// 1. 控制边框透明度与阴影强度。
  /// 2. 让按钮在深色与浅色背景下都保持足够的层次感和可见性。
  final bool isDark;

  /// 点击按钮时触发的回调。
  ///
  /// 作用：
  /// 1. 由父组件决定具体行为，例如平滑滚动到顶部。
  /// 2. 组件本身只负责展示与点击，不耦合业务逻辑。
  final VoidCallback? onTap;

  const BackToTopButton({super.key, required this.isDark, this.onTap});

  @override
  Widget build(BuildContext context) {
    const double size = 50;
    const BorderRadius radius = BorderRadius.all(Radius.circular(25));

    final Color fillColor = isDark
        ? ColorConstants.themeColor.withValues(alpha: 0.88)
        : ColorConstants.themeColor;

    final Color iconColor = Colors.black.withValues(alpha: isDark ? 0.92 : 0.88);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashColor: Colors.white.withValues(alpha: 0.24),
        highlightColor: Colors.white.withValues(alpha: 0.14),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: radius,
            color: fillColor,
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.26 : 0.42),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: ColorConstants.themeColor.withValues(
                  alpha: isDark ? 0.24 : 0.18,
                ),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.92),
                        radius: 1.08,
                        colors: [
                          Colors.white.withValues(alpha: isDark ? 0.28 : 0.34),
                          Colors.white.withValues(alpha: isDark ? 0.08 : 0.06),
                          Colors.white.withValues(alpha: 0),
                        ],
                        stops: const [0.0, 0.46, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: Icon(
                  Icons.keyboard_double_arrow_up_rounded,
                  size: 22,
                  color: iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
