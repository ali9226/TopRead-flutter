import 'package:flutter/material.dart';

import 'package:app/config/color_config.dart';
import 'package:app/components/top_decoration/style.dart';

/// 顶部装饰组件。
///
/// 使用多个浅色系圆圈交错点缀，兼容日间/夜间主题。
/// 可复用于首页、榜单页等需要顶部装饰的页面。
class TopDecoration extends StatelessWidget {
  /// 是否为夜间模式。
  final bool is_dark;

  /// 装饰区域高度，默认 190。
  final double height;

  const TopDecoration({
    super.key,
    required this.is_dark,
    this.height = 190,
  });

  @override
  Widget build(BuildContext context) {
    final double opacity = is_dark
        ? TopDecorationStyle.dark_opacity
        : TopDecorationStyle.light_opacity;

    /// 主题色。
    final Color primary = ColorConstants.themeColor;

    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          /// 大圆 - 左上角（浅主题色）。
          Positioned(
            top: -30,
            left: -25,
            child: _build_circle(
              size: 110,
              color: primary.withValues(alpha: opacity),
            ),
          ),

          /// 中圆 - 偏右上（更浅的主题色）。
          Positioned(
            top: 10,
            right: 40,
            child: _build_circle(
              size: 70,
              color: primary.withValues(alpha: opacity * 0.6),
            ),
          ),

          /// 小圆 - 右侧（浅色点缀）。
          Positioned(
            top: 50,
            right: -10,
            child: _build_circle(
              size: 45,
              color: primary.withValues(alpha: opacity * 0.8),
            ),
          ),

          /// 小圆 - 左侧偏下。
          Positioned(
            top: 70,
            left: 30,
            child: _build_circle(
              size: 35,
              color: primary.withValues(alpha: opacity * 0.5),
            ),
          ),

          /// 微圆 - 中间点缀。
          Positioned(
            top: 25,
            left: 100,
            child: _build_circle(
              size: 20,
              color: primary.withValues(alpha: opacity * 1.2),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建单个装饰圆圈。
  Widget _build_circle({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
