import 'package:app/config/layout_config.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:app/config/font_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app/config/color_config.dart';

/// 自动阅读设置浮动按钮组件。
///
/// 在自动阅读模式下显示在页面底部中央，点击后弹出自动阅读设置弹窗。
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
    final Color bg_color = is_dark ? ColorConstants.components_reader_top_bar_style_tone : ColorConstants.whiteColor;

    final Color text_color = is_dark ? ColorConstants.whiteColor : ColorConstants.components_reader_top_bar_style_tone_ff1f1a12;

    final Color icon_color = is_dark
        ? ColorConstants.components_reader_bottom_action_style_tone_b2ffffff
        : ColorConstants.components_reader_top_bar_style_tone_ff7a6a56;

    final Color shadow_color = is_dark
        ? ColorConstants.pages_short_story_read_widgets_scroll_to_bottom_button_tone
        : ColorConstants.util_dialog_show_bottom_tip_tone_1f222222;

    return GestureDetector(
      onTap: on_tap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LayoutConfig.space_14,
          vertical: LayoutConfig.space_10,
        ),
        decoration: BoxDecoration(
          color: bg_color,
          borderRadius: BorderRadius.circular(LayoutConfig.radius_20),
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
            Text(
              easy.tr('short_story_read.auto_read_settings'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                color: text_color,
              ),
            ),
            const SizedBox(width: LayoutConfig.space_4),
            Transform.rotate(
              angle: -1.5708,
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
