import 'package:app/config/color_config.dart';
import 'package:app/pages/read/style.dart';
import 'package:flutter/material.dart';
import './style.dart';

/// 阅读页底部进度文字组件。
///
/// 负责在页面底部左侧显示当前的阅读进度百分比。
/// 包含背景渐变过渡效果，确保在滚动时文字清晰可见。
class ReadingProgressText extends StatelessWidget {
  /// 当前是否为夜间主题，用于决定文字颜色和背景色。
  final bool is_dark;

  /// 当前阅读进度百分比，用于展示为百分数字符串。
  final double reading_progress_percent;

  /// 是否已经开始阅读，用于控制进度区域是否淡入淡出显示。
  final bool has_started_reading;

  const ReadingProgressText({
    super.key,
    required this.is_dark,
    required this.reading_progress_percent,
    required this.has_started_reading,
  });

  /// 格式化阅读进度，去掉多余小数位，让展示更简洁。
  String _format_reading_progress(double progress) {
    final String formatted_progress = progress.toStringAsFixed(2);
    final String trimmed_progress = formatted_progress.replaceFirst(
      RegExp(r'\.0+$'),
      '',
    );

    return trimmed_progress.replaceFirstMapped(
      RegExp(r'(\.\d*[1-9])0+$'),
      (Match match) => match.group(1) ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    // 进度文案颜色按主题区分透明度，确保在底部渐变层上可读。
    final Color text_color = is_dark
        ? ColorConstants.whiteColor.withValues(
            alpha: ProgressTextStyle.text_night_alpha,
          )
        : ColorConstants.lightTextColor.withValues(
            alpha: ProgressTextStyle.text_light_alpha,
          );
    // 进度条背景与页面背景保持一致，避免出现断层。
    final Color background_color = is_dark
        ? Style.dark_background_color
        : Style.light_background_color;

    return Positioned(
      left: 0,
      right: 0,
      bottom: ProgressTextStyle.container_bottom_inset,
      child: AnimatedOpacity(
        duration: const Duration(
          milliseconds: ProgressTextStyle.opacity_animation_duration_ms,
        ),
        opacity: has_started_reading ? 1 : 0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              height: ProgressTextStyle.gradient_height,
              width: double.infinity,
              decoration: BoxDecoration(
                // 先铺一层向上透明的过渡底色，避免进度文字区域与正文硬切换。
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: <Color>[
                    background_color,
                    background_color.withValues(
                      alpha: ProgressTextStyle.gradient_transparent_alpha,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              height: ProgressTextStyle.container_height,
              width: double.infinity,
              color: background_color,
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.only(
                left: ProgressTextStyle.text_left_spacing,
                bottom: ProgressTextStyle.text_bottom_spacing,
              ),
              child: Text(
                // 进度数值统一拼接百分号，保持展示格式稳定。
                '${_format_reading_progress(reading_progress_percent)}%',
                style: TextStyle(
                  color: text_color,
                  fontSize: ProgressTextStyle.font_size,
                  fontWeight: ProgressTextStyle.font_weight,
                  shadows: <Shadow>[
                    Shadow(
                      color: Colors.black.withValues(
                        alpha: is_dark
                            ? ProgressTextStyle.shadow_night_alpha
                            : ProgressTextStyle.shadow_light_alpha,
                      ),
                      blurRadius: ProgressTextStyle.shadow_blur_radius,
                      offset: ProgressTextStyle.shadow_offset,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
