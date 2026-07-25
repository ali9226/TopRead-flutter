import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/config/color_config.dart';
import './style.dart';
import 'package:app/config/font_config.dart';

/// 阅读页底部“上滑开始阅读”胶囊组件。
///
/// 用于在未进入正文阅读状态时，提示用户上滑或点击开始阅读。
/// 包含一个向上的图标和引导文案。
class ReadStartReadingPill extends StatelessWidget {
  /// 当前是否为夜间主题，用于控制文字颜色。
  final bool is_dark;

  /// 是否显示开始阅读胶囊，用于控制胶囊显示与点击状态。
  final bool show_start_reading_pill;

  /// 胶囊背景色，由父组件统一计算后传入。
  final Color bottom_pill_background_color;

  /// 底部安全区高度，用于计算胶囊距离屏幕底部位置。
  final double bottom_safe_area;

  /// 点击胶囊后的回调，用于滚动到正文锚点。
  final VoidCallback on_tap;

  const ReadStartReadingPill({
    super.key,
    required this.is_dark,
    required this.show_start_reading_pill,
    required this.bottom_pill_background_color,
    required this.bottom_safe_area,
    required this.on_tap,
  });

  @override
  Widget build(BuildContext context) {
    // 胶囊底部距离 = 安全区 + 设计稿定义的底部偏移。
    final double bottom_offset =
        bottom_safe_area + StartReadingPillStyle.bottom_pill_bottom_spacing;
    // 文案颜色根据主题切换。
    final Color text_color = is_dark
        ? StartReadingPillStyle.text_color_dark
        : StartReadingPillStyle.text_color_light;

    return Positioned(
      left: 0,
      right: 0,
      bottom: bottom_offset,
      // 通过透明度动画控制胶囊显隐，不触发布局抖动。
      child: AnimatedOpacity(
        duration: const Duration(
          milliseconds:
              StartReadingPillStyle.start_reading_pill_animation_duration_ms,
        ),
        opacity: show_start_reading_pill ? 1 : 0,
        child: IgnorePointer(
          // 胶囊不可见时屏蔽点击，防止透明层拦截正文手势。
          ignoring: !show_start_reading_pill,
          child: Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: on_tap,
              // 胶囊容器负责背景、圆角、阴影和内部图文排版。
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal:
                      StartReadingPillStyle.bottom_pill_horizontal_padding,
                  vertical: StartReadingPillStyle.bottom_pill_vertical_padding,
                ),
                decoration: BoxDecoration(
                  color: bottom_pill_background_color,
                  borderRadius: BorderRadius.circular(
                    StartReadingPillStyle.bottom_pill_radius,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: StartReadingPillStyle.bottom_pill_shadow_alpha,
                      ),
                      blurRadius:
                          StartReadingPillStyle.bottom_pill_shadow_blur_radius,
                      offset: StartReadingPillStyle.bottom_pill_shadow_offset,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SvgIcon(
                      name: 'up',
                      width: StartReadingPillStyle.bottom_pill_icon_size,
                      height: StartReadingPillStyle.bottom_pill_icon_size,
                      color: ColorConstants.themeColor,
                    ),
                    const SizedBox(
                      width: StartReadingPillStyle.bottom_pill_icon_gap,
                    ),
                    Text(
                      easy.tr('read.swipe_to_read'),
                      style: TextStyle(
                        color: text_color,
                        fontSize: StartReadingPillStyle.bottom_pill_font_size,
                        fontWeight: FontConfig.adjustedWeight(FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
