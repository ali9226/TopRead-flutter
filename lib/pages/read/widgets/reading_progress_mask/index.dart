import 'package:flutter/material.dart';
import 'package:app/pages/read/style.dart';
import './style.dart';

/// 阅读页底部进度渐变遮罩组件。
///
/// 用于在页面底部提供一个模糊遮罩效果，使正文与底部进度显示区域自然衔接。
/// 采用多段渐变模拟雾化过渡效果。
class ReadingProgressMask extends StatelessWidget {
  /// 当前是否为夜间主题，用于决定渐变基色。
  final bool is_dark;

  const ReadingProgressMask({super.key, required this.is_dark});

  @override
  Widget build(BuildContext context) {
    // 当前主题对应的页面背景色，作为渐变的基底颜色。
    final Color base_color = is_dark
        ? Style.dark_background_color
        : Style.light_background_color;

    return SizedBox(
      height: ProgressMaskStyle.reading_mask_height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          // 由下到上的五段透明度渐变，模拟阅读页底部雾化过渡效果。
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: <Color>[
              base_color.withValues(
                alpha: ProgressMaskStyle.reading_mask_bottom_alpha,
              ),
              base_color.withValues(
                alpha: ProgressMaskStyle.reading_mask_second_alpha,
              ),
              base_color.withValues(
                alpha: ProgressMaskStyle.reading_mask_third_alpha,
              ),
              base_color.withValues(
                alpha: ProgressMaskStyle.reading_mask_fourth_alpha,
              ),
              base_color.withValues(
                alpha: ProgressMaskStyle.reading_mask_top_alpha,
              ),
            ],
            stops: const <double>[
              ProgressMaskStyle.reading_mask_stop_one,
              ProgressMaskStyle.reading_mask_stop_two,
              ProgressMaskStyle.reading_mask_stop_three,
              ProgressMaskStyle.reading_mask_stop_four,
              ProgressMaskStyle.reading_mask_stop_five,
            ],
          ),
        ),
      ),
    );
  }
}
