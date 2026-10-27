import 'package:app/components/work_about_section/style.dart';
import 'package:app/components/work_section_card/style.dart';
import 'package:app/pages/comics/detail/widgets/similar_comics/style.dart';
import 'package:app/pages/comics/widgets/comic_surface.dart';
import 'package:flutter/material.dart';

import 'pulse.dart';
import 'style.dart';
import 'text_line.dart';

/// TODO 更多推荐与实页一样由独立等高卡片组成，轨道延伸至阅读列边缘。
class ComicSkeletonRecommendations extends StatelessWidget {
  const ComicSkeletonRecommendations({
    super.key,
    required this.cjk,
    required this.is_dark,
  });
  final bool cjk;
  final bool is_dark;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('work_detail_skeleton_recommendations'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: WorkAboutSectionStyle.horizontal_padding,
        ),
        child: SkeletonTextLine(
          width: cjk
              ? WorkDetailSkeletonStyle.heading_width_cjk
              : WorkDetailSkeletonStyle.heading_width_alphabetic,
          font_size: cjk
              ? WorkSectionCardStyle.title_size_cjk
              : WorkSectionCardStyle.title_size_alphabetic,
          line_height: cjk
              ? WorkSectionCardStyle.title_height_cjk
              : WorkSectionCardStyle.title_height_alphabetic,
        ),
      ),
      const SizedBox(height: ComicSimilarComicsStyle.section_heading_gap),
      SizedBox(
        height:
            ComicSimilarComicsStyle.card_height(
              MediaQuery.textScalerOf(context),
              cjk,
            ) +
            ComicSimilarComicsStyle.shadow_padding * 2,
        child: ListView.separated(
          primary: false,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: ComicSimilarComicsStyle.horizontal_padding,
            vertical: ComicSimilarComicsStyle.shadow_padding,
          ),
          itemCount: WorkDetailSkeletonStyle.comic_rail_items,
          separatorBuilder: (_, _) =>
              const SizedBox(width: ComicSimilarComicsStyle.card_gap),
          itemBuilder: (_, index) => SizedBox(
            width: ComicSimilarComicsStyle.card_width,
            child: ComicSurface(
              is_dark: is_dark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SkeletonBlock(
                    height: ComicSimilarComicsStyle.cover_height,
                    radius: 0,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(
                      ComicSimilarComicsStyle.card_padding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: ComicSimilarComicsStyle.title_height(
                            MediaQuery.textScalerOf(context),
                            cjk,
                          ),
                          child: Column(
                            children: List.generate(
                              ComicSimilarComicsStyle.title_lines,
                              (line) => SkeletonTextLine(
                                font_size: cjk
                                    ? ComicSimilarComicsStyle.font_size_cjk
                                    : ComicSimilarComicsStyle
                                          .font_size_alphabetic,
                                line_height: cjk
                                    ? ComicSimilarComicsStyle.line_height_cjk
                                    : ComicSimilarComicsStyle
                                          .line_height_alphabetic,
                                width_factor: line == 0
                                    ? 1
                                    : WorkDetailSkeletonStyle
                                          .synopsis_last_line_ratio,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: ComicSimilarComicsStyle.author_gap,
                        ),
                        SizedBox(
                          height: ComicSimilarComicsStyle.author_height(
                            MediaQuery.textScalerOf(context),
                            cjk,
                          ),
                          child: SkeletonTextLine(
                            font_size: cjk
                                ? ComicSimilarComicsStyle.author_size_cjk
                                : ComicSimilarComicsStyle
                                      .author_size_alphabetic,
                            line_height: cjk
                                ? ComicSimilarComicsStyle.line_height_cjk
                                : ComicSimilarComicsStyle
                                      .line_height_alphabetic,
                            width_factor: WorkDetailSkeletonStyle
                                .synopsis_last_line_ratio,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
