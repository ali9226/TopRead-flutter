import 'package:app/components/window_content_layout/index.dart';
import 'package:app/components/work_about_section/style.dart';
import 'package:app/pages/comics/detail/widgets/chapter_preview/style.dart';
import 'package:app/pages/comics/widgets/comic_surface.dart';
import 'package:flutter/material.dart';

import 'pulse.dart';
import 'style.dart';
import 'text_line.dart';

/// TODO 章节骨架沿用真实4:3首图、单行标题和横向轨道尺寸，不再预示已删除的快捷按钮。
class ComicSkeletonChapters extends StatelessWidget {
  const ComicSkeletonChapters({
    super.key,
    required this.cjk,
    required this.is_dark,
  });
  final bool cjk;
  final bool is_dark;

  @override
  Widget build(BuildContext context) {
    final line_height = cjk
        ? ComicChapterPreviewStyle.line_height_cjk
        : ComicChapterPreviewStyle.line_height_alphabetic;
    final title_size = cjk
        ? ComicChapterPreviewStyle.title_size_cjk
        : ComicChapterPreviewStyle.title_size_alphabetic;
    return Column(
      key: const ValueKey('work_detail_skeleton_chapters'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WindowReservedRegionPadding(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: WorkAboutSectionStyle.horizontal_padding,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: ComicChapterPreviewStyle.minimum_action_height,
              ),
              child: Row(
                children: [
                  const SkeletonBlock(
                    width: ComicChapterPreviewStyle.status_dot_size,
                    height: ComicChapterPreviewStyle.status_dot_size,
                    radius: ComicChapterPreviewStyle.status_dot_size,
                  ),
                  const SizedBox(width: ComicChapterPreviewStyle.header_gap),
                  Expanded(
                    child: SkeletonTextLine(
                      width: cjk
                          ? WorkDetailSkeletonStyle.heading_width_cjk
                          : WorkDetailSkeletonStyle.heading_width_alphabetic,
                      font_size: cjk
                          ? ComicChapterPreviewStyle.heading_size_cjk
                          : ComicChapterPreviewStyle.heading_size_alphabetic,
                      line_height: line_height,
                    ),
                  ),
                  const SizedBox(width: ComicChapterPreviewStyle.header_gap),
                  Flexible(
                    child: SkeletonTextLine(
                      width: cjk
                          ? WorkDetailSkeletonStyle.label_width_cjk
                          : WorkDetailSkeletonStyle.label_width_alphabetic,
                      font_size: cjk
                          ? ComicChapterPreviewStyle.count_size_cjk
                          : ComicChapterPreviewStyle.count_size_alphabetic,
                      line_height: line_height,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: ComicChapterPreviewStyle.header_gap),
        LayoutBuilder(
          builder: (context, constraints) {
            final width =
                ((constraints.maxWidth -
                            WorkAboutSectionStyle.horizontal_padding * 2) *
                        ComicChapterPreviewStyle.card_width_ratio)
                    .clamp(
                      ComicChapterPreviewStyle.card_min_width,
                      ComicChapterPreviewStyle.card_max_width,
                    )
                    .toDouble();
            final title_height =
                MediaQuery.textScalerOf(context).scale(title_size) *
                    line_height *
                    ComicChapterPreviewStyle.title_lines +
                ComicChapterPreviewStyle.font_metric_allowance;
            final height =
                width / ComicChapterPreviewStyle.image_ratio +
                ComicChapterPreviewStyle.title_padding_v * 2 +
                title_height +
                ComicChapterPreviewStyle.list_padding_top +
                ComicChapterPreviewStyle.list_padding_bottom;
            return SizedBox(
              height: height,
              child: ListView.separated(
                key: const ValueKey('work_detail_skeleton_chapter_rail'),
                primary: false,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  WorkAboutSectionStyle.horizontal_padding,
                  ComicChapterPreviewStyle.list_padding_top,
                  WorkAboutSectionStyle.horizontal_padding,
                  ComicChapterPreviewStyle.list_padding_bottom,
                ),
                itemCount: WorkDetailSkeletonStyle.comic_rail_items,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: ComicChapterPreviewStyle.gap),
                itemBuilder: (_, index) => SizedBox(
                  key: ValueKey('work_detail_skeleton_chapter_$index'),
                  width: width,
                  child: ComicSurface(
                    is_dark: is_dark,
                    radius: ComicChapterPreviewStyle.radius,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AspectRatio(
                          aspectRatio: ComicChapterPreviewStyle.image_ratio,
                          child: SkeletonBlock(
                            key: ValueKey(
                              'work_detail_skeleton_chapter_image_$index',
                            ),
                            height: double.infinity,
                            radius: 0,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal:
                                ComicChapterPreviewStyle.title_padding_h,
                            vertical: ComicChapterPreviewStyle.title_padding_v,
                          ),
                          child: SizedBox(
                            height: title_height,
                            child: SkeletonTextLine(
                              font_size: title_size,
                              line_height: line_height,
                              width_factor: WorkDetailSkeletonStyle
                                  .synopsis_last_line_ratio,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
