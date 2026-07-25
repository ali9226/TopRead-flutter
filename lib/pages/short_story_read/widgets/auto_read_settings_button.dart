import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app/pages/short_story_read/style.dart';

/// 自动阅读设置浮动按钮组件。
///
/// 在自动阅读模式下显示在页面底部中央，点击后弹出自动阅读设置弹窗。
/// 包含设置文字和向下箭头图标。
///
/// 参数：
/// - [is_dark] 是否为夜间模式
/// - [on_tap] 点击按钮的回调
class AutoReadSettingsButton extends StatelessWidget {
  /// 是否为夜间模式。
  final bool is_dark;

  /// 点击按钮的回调。
  final VoidCallback on_tap;

  const AutoReadSettingsButton({
    super.key,
    required this.is_dark,
    required this.on_tap,
  });

  @override
  Widget build(BuildContext context) {
    // 根据主题模式选择背景色。
    final Color bg_color = is_dark
        ? ShortStoryReadStyle.card_dark_bg
        : ShortStoryReadStyle.card_light_bg;

    // 根据主题模式选择文字颜色。
    final Color text_color = is_dark
        ? ShortStoryReadStyle.title_dark_color
        : ShortStoryReadStyle.title_light_color;

    // 根据主题模式选择图标颜色。
    final Color icon_color = is_dark
        ? ShortStoryReadStyle.secondary_dark_color
        : ShortStoryReadStyle.secondary_light_color;

    // 根据主题模式选择投影颜色。
    final Color shadow_color = is_dark
        ? Colors.black.withValues(alpha: 0.35)
        : Colors.black.withValues(alpha: 0.12);

    return GestureDetector(
      onTap: on_tap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg_color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: shadow_color,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // 设置文字。
            Text(
              easy.tr('short_story_read.auto_read_settings'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                color: text_color,
              ),
            ),
            const SizedBox(width: 4),
            // 向下箭头图标（旋转 -90 度）。
            Transform.rotate(
              angle: -1.5708, // -90 度（向下）
              child: SvgPicture.asset(
                'assets/svg/right.svg',
                width: 14,
                height: 14,
                colorFilter: ColorFilter.mode(icon_color, BlendMode.srcIn),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
