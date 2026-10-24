import 'package:app/components/work_detail_skeleton/index.dart';
import 'package:app/components/work_detail_skeleton/style.dart';
import 'package:app/pages/short_story_read/style.dart';
import 'package:app/util/language_util/index.dart';
import 'package:flutter/material.dart';

/// 卡片内的正文加载沿用真实短篇字号与段距，与页面初次加载的封面骨架分开。
class SkeletonContent extends StatelessWidget {
  const SkeletonContent({super.key, required this.is_dark, this.font_size});

  final bool is_dark;

  /// 由真实阅读设置传入，缺省才使用语种对应字号。
  final double? font_size;

  @override
  Widget build(BuildContext context) {
    final cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    return SkeletonPulse(
      is_dark: is_dark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          WorkDetailSkeletonStyle.reading_line_ratios.length,
          (index) {
            final is_short_line =
                WorkDetailSkeletonStyle.reading_line_ratios[index] < 1;
            final bottom_spacing = is_short_line
                ? ShortStoryReadStyle.paragraph_spacing
                : 0.0;
            return Padding(
            padding: EdgeInsets.only(bottom: bottom_spacing),
            child: SkeletonTextLine(
              font_size:
                  font_size ??
                  (cjk
                      ? ShortStoryReadStyle.body_font_size_cjk
                      : ShortStoryReadStyle.body_font_size_alphabetic),
              line_height: cjk
                  ? ShortStoryReadStyle.body_height_cjk
                  : ShortStoryReadStyle.body_height_alphabetic,
              width_factor: WorkDetailSkeletonStyle.reading_line_ratios[index],
            ),
            );
          },
        ),
      ),
    );
  }
}
