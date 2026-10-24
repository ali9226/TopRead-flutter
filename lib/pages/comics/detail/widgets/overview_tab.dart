import 'package:app/components/work_about_section/style.dart';
import 'package:app/components/work_section_card/index.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/detail/style.dart';
import 'package:app/pages/comics/comments/logic.dart';
import 'package:app/pages/comics/detail/widgets/about_story/index.dart';
import 'package:app/pages/comics/detail/widgets/chapter_preview/index.dart';
import 'package:app/pages/comics/detail/widgets/hot_comments/index.dart';
import 'package:app/pages/comics/detail/widgets/similar_comics/index.dart';
import 'package:app/pages/comics/detail/widgets/similar_comics/style.dart';
import 'package:app/pages/comics/detail/widgets/warm_paper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 简介紧接封面；横向内容使用完整窗口宽度，各卡片的边距随内容滚动。
class ComicDetailOverviewTab extends StatelessWidget {
  const ComicDetailOverviewTab({
    super.key,
    required this.detail,
    required this.is_dark,
    this.chapters = const [],
    this.current_chapter_id,
    this.on_chapters,
    this.on_open_chapter,
    this.on_comments,
    this.comments_revision = 0,
    this.comments_controller,
    this.on_author,
    this.similar_comics = const [],
    this.on_see_all_similar,
    this.on_similar_tap,
  });

  final ComicDetail detail;
  final bool is_dark;
  final List<ComicChapter> chapters;
  final int? current_chapter_id;
  final VoidCallback? on_chapters;
  final ValueChanged<ComicChapter>? on_open_chapter;
  final VoidCallback? on_comments;
  final int comments_revision;
  final ComicCommentsLogic? comments_controller;
  final VoidCallback? on_author;
  final List<ComicItem> similar_comics;
  final VoidCallback? on_see_all_similar;
  final ValueChanged<int>? on_similar_tap;

  Widget _inset(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: WorkAboutSectionStyle.horizontal_padding,
    ),
    child: child,
  );

  @override
  Widget build(BuildContext context) => ComicWarmPaper(
    child: Padding(
      padding: const EdgeInsets.symmetric(
        vertical: WorkAboutSectionStyle.module_gap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _inset(
            ComicAboutStory(
              description:
                  detail.selected_language?.description.trim().isNotEmpty ==
                      true
                  ? detail.selected_language!.description.trim()
                  : detail.comic.description.trim(),
              embedded: true,
              is_dark: is_dark,
            ),
          ),
          if (on_chapters != null && on_open_chapter != null) ...[
            const SizedBox(height: WorkAboutSectionStyle.module_gap),
            ComicChapterPreview(
              chapters: chapters,
              completed: detail.comic.completion_status == 'completed',
              current_chapter_id: current_chapter_id,
              on_chapters: on_chapters!,
              on_open: on_open_chapter!,
              horizontal_padding: WorkAboutSectionStyle.horizontal_padding,
            ),
          ],
          if (on_comments != null) ...[
            const SizedBox(height: WorkAboutSectionStyle.module_gap),
            _inset(
              ComicHotComments(
                comic_id: detail.comic.id,
                is_dark: is_dark,
                on_comments: on_comments!,
                refresh_revision: comments_revision,
                controller: comments_controller,
              ),
            ),
          ],
          if (similar_comics.isNotEmpty) ...[
            const SizedBox(height: WorkAboutSectionStyle.module_gap),
            _inset(
              WorkSectionHeading(
                title: tr('comics.similar_comics'),
                is_dark: is_dark,
                trailing: TextButton(
                  onPressed: on_see_all_similar,
                  child: Text(
                    tr('comics.see_all'),
                    style: TextStyle(
                      color: ComicDetailStyle.muted(context),
                      fontSize: ComicDetailStyle.similar_see_all_font_size,
                      fontWeight: ComicDetailStyle.weight_regular,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: ComicSimilarComicsStyle.section_heading_gap),
            ComicSimilarComicsRow(
              comics: similar_comics,
              on_tap: on_similar_tap,
              horizontal_padding: ComicSimilarComicsStyle.horizontal_padding,
            ),
          ],
        ],
      ),
    ),
  );
}
