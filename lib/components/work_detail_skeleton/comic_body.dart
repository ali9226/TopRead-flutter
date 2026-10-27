import 'package:app/components/comment_list/style.dart';
import 'package:app/components/expandable_synopsis/style.dart';
import 'package:app/components/window_content_layout/index.dart';
import 'package:app/components/work_about_section/style.dart';
import 'package:app/pages/comics/detail/widgets/hot_comments/style.dart';
import 'package:app/pages/comics/widgets/comic_surface.dart';
import 'package:flutter/material.dart';

import 'comic_chapters.dart';
import 'comic_recommendations.dart';
import 'pulse.dart';
import 'style.dart';
import 'text_line.dart';

/// TODO 漫画首屏严格按实页的简介、章节、热评、更多推荐顺序占位。
class ComicDetailSkeletonBody extends StatelessWidget {
  const ComicDetailSkeletonBody({
    super.key,
    required this.is_dark,
    required this.cjk,
  });
  final bool is_dark;
  final bool cjk;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      top: WorkAboutSectionStyle.module_gap,
      bottom:
          WorkAboutSectionStyle.module_gap +
          MediaQuery.paddingOf(context).bottom,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WindowReservedRegionPadding(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: WorkAboutSectionStyle.horizontal_padding,
            ),
            child: _synopsis(),
          ),
        ),
        const SizedBox(height: WorkAboutSectionStyle.module_gap),
        ComicSkeletonChapters(cjk: cjk, is_dark: is_dark),
        const SizedBox(height: WorkAboutSectionStyle.module_gap),
        WindowReservedRegionPadding(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: WorkAboutSectionStyle.horizontal_padding,
            ),
            child: _comments(),
          ),
        ),
        const SizedBox(height: WorkAboutSectionStyle.module_gap),
        ComicSkeletonRecommendations(cjk: cjk, is_dark: is_dark),
      ],
    ),
  );

  Widget _synopsis() => Column(
    key: const ValueKey('work_detail_skeleton_synopsis'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Transform.translate(
        offset: const Offset(0, -ExpandableSynopsisStyle.compact_title_lift),
        child: Row(
          children: [
            const SkeletonBlock(
              width: ExpandableSynopsisStyle.compact_accent_width,
              height: ExpandableSynopsisStyle.compact_accent_height,
            ),
            const SizedBox(width: ExpandableSynopsisStyle.compact_accent_gap),
            Expanded(
              child: SkeletonTextLine(
                width: cjk
                    ? WorkDetailSkeletonStyle.heading_width_cjk
                    : WorkDetailSkeletonStyle.heading_width_alphabetic,
                font_size: cjk
                    ? ExpandableSynopsisStyle.embedded_title_size_cjk
                    : ExpandableSynopsisStyle.embedded_title_size_alphabetic,
                line_height: ExpandableSynopsisStyle.embedded_title_height,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: ExpandableSynopsisStyle.compact_title_gap),
      Column(
        key: const ValueKey('work_detail_skeleton_comic_synopsis_text'),
        children: List.generate(
          WorkDetailSkeletonStyle.comic_synopsis_lines,
          (index) => SkeletonTextLine(
            font_size: cjk
                ? ExpandableSynopsisStyle.embedded_font_size_cjk
                : ExpandableSynopsisStyle.embedded_font_size_alphabetic,
            line_height: cjk
                ? ExpandableSynopsisStyle.embedded_line_height_cjk
                : ExpandableSynopsisStyle.embedded_line_height_alphabetic,
            width_factor:
                index == WorkDetailSkeletonStyle.comic_synopsis_lines - 1
                ? WorkDetailSkeletonStyle.synopsis_last_line_ratio
                : 1,
          ),
        ),
      ),
      const SizedBox(height: ExpandableSynopsisStyle.compact_toggle_top_gap),
      SizedBox(
        height: ExpandableSynopsisStyle.toggle_extent,
        child: Center(
          child: Transform.translate(
            offset: const Offset(
              0,
              -ExpandableSynopsisStyle.compact_toggle_icon_lift,
            ),
            child: const SkeletonBlock(
              key: ValueKey('work_detail_skeleton_comic_synopsis_toggle'),
              width: ExpandableSynopsisStyle.compact_toggle_icon_size,
              height: ExpandableSynopsisStyle.compact_toggle_icon_size,
              radius: 0,
            ),
          ),
        ),
      ),
    ],
  );

  Widget _comments() => ComicSurface(
    is_dark: is_dark,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        ComicHotCommentsStyle.horizontal_padding,
        ComicHotCommentsStyle.header_top,
        ComicHotCommentsStyle.horizontal_padding,
        CommentListStyle.item_bottom_padding,
      ),
      child: Column(
        key: const ValueKey('work_detail_skeleton_comic_comments'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SkeletonTextLine(
            width: cjk
                ? WorkDetailSkeletonStyle.heading_width_cjk
                : WorkDetailSkeletonStyle.heading_width_alphabetic,
            font_size: cjk
                ? WorkAboutSectionStyle.heading_size_cjk
                : WorkAboutSectionStyle.heading_size_alphabetic,
            line_height: WorkAboutSectionStyle.heading_height,
          ),
          ...List.generate(
            ComicHotCommentsStyle.skeleton_count,
            (_) => Padding(
              padding: const EdgeInsets.only(
                top: CommentListStyle.item_top_padding,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBlock(
                    width: CommentListStyle.avatar_size,
                    height: CommentListStyle.avatar_size,
                    radius: CommentListStyle.avatar_radius,
                  ),
                  const SizedBox(width: CommentListStyle.avatar_content_gap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonTextLine(
                          width: WorkDetailSkeletonStyle.comment_name_width,
                          font_size: cjk
                              ? CommentListStyle.nickname_font_size_cjk
                              : CommentListStyle.nickname_font_size_alphabetic,
                          line_height:
                              WorkDetailSkeletonStyle.comic_comment_name_height,
                        ),
                        const SizedBox(
                          height: CommentListStyle.content_top_spacing,
                        ),
                        ...List.generate(
                          WorkDetailSkeletonStyle.comic_comment_lines,
                          (index) => SkeletonTextLine(
                            font_size: cjk
                                ? CommentListStyle.content_font_size_cjk
                                : CommentListStyle.content_font_size_alphabetic,
                            line_height: cjk
                                ? CommentListStyle.content_line_height_cjk
                                : CommentListStyle
                                      .content_line_height_alphabetic,
                            width_factor: index == 0
                                ? 1
                                : WorkDetailSkeletonStyle
                                      .comment_last_line_ratio,
                          ),
                        ),
                      ],
                    ),
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
