import 'package:app/config/color_config.dart';
import 'package:app/config/font_config.dart';
import 'package:app/config/layout_config.dart';
import 'package:app/pages/short_story_read/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 贯穿屏幕底部的下一篇渐变遮罩与“查看下一篇”提示胶囊。
///
/// 放在正文 Stack 的最上层；遮罩按 [overlay_opacity] 淡入淡出，
/// 提示胶囊再按 [hint_opacity] 独立淡入，上拉就绪时箭头偏转。
class NextStoryBottomOverlay extends StatelessWidget {
  const NextStoryBottomOverlay({
    super.key,
    required this.is_dark,
    required this.bg_color,
    required this.bottom_padding,
    required this.overlay_opacity,
    required this.hint_opacity,
    required this.pull_ready,
    required this.view_next_label,
  });

  /// 当前是否为夜间模式。
  final bool is_dark;

  /// 页面背景色，渐变遮罩从该色过渡到透明。
  final Color bg_color;

  /// 底部安全区高度。
  final double bottom_padding;

  /// 遮罩整体透明度。
  final double overlay_opacity;

  /// 提示胶囊透明度。
  final double hint_opacity;

  /// 上拉距离是否已达到切换阈值。
  final bool pull_ready;

  /// “查看下一篇”文案（由页面按语种提供）。
  final String view_next_label;

  /// 遮罩高度：安全区之上再容纳提示胶囊。
  static const double _overlay_extra_height = 132;

  @override
  Widget build(BuildContext context) {
    final Color text_color = is_dark
        ? ShortStoryReadStyle.secondary_dark_color
        : ShortStoryReadStyle.secondary_light_color;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: bottom_padding + _overlay_extra_height,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: overlay_opacity,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: <Color>[
                  bg_color,
                  bg_color.withValues(alpha: 0.94),
                  bg_color.withValues(alpha: 0.62),
                  bg_color.withValues(alpha: 0.0),
                ],
                stops: const <double>[0.0, 0.42, 0.72, 1.0],
              ),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: bottom_padding + LayoutConfig.space_14,
                ),
                child: AnimatedOpacity(
                  opacity: hint_opacity,
                  duration: const Duration(milliseconds: 90),
                  curve: Curves.easeOut,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: LayoutConfig.space_14,
                      vertical: LayoutConfig.space_8,
                    ),
                    decoration: BoxDecoration(
                      color: is_dark
                          ? ColorConstants.pages_short_story_read_index_tone
                          : ColorConstants
                                .pages_short_story_read_index_tone_6bffffff,
                      borderRadius: BorderRadius.circular(
                        LayoutConfig.radius_pill,
                      ),
                      border: Border.all(
                        color: is_dark
                            ? ColorConstants
                                  .util_dialog_show_upgrade_dialog_tone_14ffffff
                            : ColorConstants
                                  .components_home_top_search_entry_index_tone,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          view_next_label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontConfig.adjustedWeight(
                              FontWeight.w500,
                            ),
                            color: text_color,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(width: LayoutConfig.space_6),
                        AnimatedRotation(
                          turns: pull_ready ? 0.25 : -0.25,
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOutCubic,
                          child: SvgPicture.asset(
                            'assets/svg/right.svg',
                            width: 13,
                            height: 13,
                            colorFilter: ColorFilter.mode(
                              text_color,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
