import 'package:easy_localization/easy_localization.dart';
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';

import 'package:app/components/svg_icon/index.dart';
import 'package:app/pages/short_story_read/style.dart';

/// 收起/展开胶囊按钮组件。
///
/// 显示在正文容器右下角，点击后切换内容的展开/收起状态。
/// 按钮文字根据当前状态显示"收起"或"展开"，箭头图标带旋转动画。
///
/// 视觉特征：
/// - 胶囊形状（圆角 20px）
/// - 带阴影提升层次感
/// - 箭头方向随状态旋转 90°
class CollapseButton extends StatelessWidget {
  /// 是否为夜间模式。
  final bool is_dark;

  /// 是否为展开状态（展开时显示"收起"，收起时显示"展开"）。
  final bool is_expanded;

  /// 点击回调。
  final VoidCallback on_tap;

  const CollapseButton({
    super.key,
    required this.is_dark,
    required this.is_expanded,
    required this.on_tap,
  });

  @override
  Widget build(BuildContext context) {
    /// 按钮背景色。
    final Color bg_color = is_dark
        ? ShortStoryReadStyle.card_dark_bg
        : ShortStoryReadStyle.card_light_bg;

    /// 文字和图标颜色。
    final Color text_color = is_dark
        ? ShortStoryReadStyle.secondary_dark_color
        : ShortStoryReadStyle.secondary_light_color;

    /// 阴影颜色（夜间模式阴影更深）。
    final Color shadow_color = is_dark
        ? Colors.black.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.1);

    /// 按钮文字（展开时显示"收起"，收起时显示"展开"）。
    final String button_text = is_expanded
        ? tr('short_story_read.collapse')
        : tr('short_story_read.expand');

    return GestureDetector(
      onTap: on_tap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: bg_color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: shadow_color,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            /// 按钮文字（带颜色过渡动画）。
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                color: text_color,
              ),
              child: Text(button_text),
            ),
            const SizedBox(width: 4),

            /// 箭头图标（展开时朝上，收起时朝下，带旋转动画）。
            AnimatedRotation(
              turns: is_expanded ? -0.25 : 0.25,
              duration: const Duration(milliseconds: 300),
              child: SvgIcon(
                name: 'right',
                width: 10,
                height: 14,
                color: text_color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
