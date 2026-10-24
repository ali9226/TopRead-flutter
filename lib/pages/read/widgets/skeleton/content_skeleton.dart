import 'package:app/components/work_detail_skeleton/index.dart';
import 'package:app/components/work_detail_skeleton/style.dart';
import 'package:app/pages/read/widgets/content/style.dart';
import 'package:app/pages/read/widgets/main_list/style.dart';
import 'package:app/util/language_util/index.dart';
import 'package:flutter/material.dart';

import 'style.dart';

/// 目录跳转只预示章节标题与真实段落排版，沿用首屏骨架的绘制时钟。
class ReadContentSkeleton extends StatelessWidget {
  const ReadContentSkeleton({super.key, required this.is_dark, this.font_size});

  final bool is_dark;

  /// 保持目录跳转前后正文的真实阅读设置字号。
  final double? font_size;

  @override
  Widget build(BuildContext context) {
    final cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    final line_height = cjk
        ? ContentStyle.reading_paragraph_height_cjk
        : ContentStyle.reading_paragraph_height_alphabetic;
    return SkeletonPulse(
      is_dark: is_dark,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          MainListStyle.page_horizontal_padding,
          MediaQuery.viewPaddingOf(context).top +
              ContentStyle.reading_padding.top +
              ContentStyle.reading_paragraph_top_spacing *
                  ReadSkeletonStyle.title_top_factor,
          MainListStyle.page_horizontal_padding,
          ContentStyle.reading_padding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SkeletonTextLine(
              font_size: ContentStyle.reading_title_font_size,
              line_height: ContentStyle.reading_paragraph_height,
              width_factor: ReadSkeletonStyle.chapter_title_width_ratio,
            ),
            const SizedBox(
              height:
                  ContentStyle.reading_paragraph_bottom_spacing *
                  ReadSkeletonStyle.title_bottom_factor,
            ),
            ...List.generate(
              WorkDetailSkeletonStyle.reading_line_ratios.length,
              (index) {
                final is_short_line =
                    WorkDetailSkeletonStyle.reading_line_ratios[index] < 1;
                final bottom_spacing = is_short_line
                    ? ContentStyle.reading_paragraph_bottom_spacing
                    : 0.0;
                return Padding(
                padding: EdgeInsets.only(bottom: bottom_spacing),
                child: SkeletonTextLine(
                  font_size:
                      font_size ?? ContentStyle.reading_paragraph_font_size,
                  line_height: line_height,
                  width_factor:
                      WorkDetailSkeletonStyle.reading_line_ratios[index],
                ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
