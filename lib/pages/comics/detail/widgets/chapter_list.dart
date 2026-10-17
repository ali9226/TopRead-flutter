// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/detail/style.dart';
import 'package:app/pages/comics/style.dart';

/// Sliver目录只构建可见章节，千章作品不会在首屏创建全部图片或文字组件。
class ComicDetailChapterList extends StatelessWidget {
  final List<ComicChapter> chapters;
  final bool is_dark;
  final int resume_chapter_id;
  final ValueChanged<int> on_open;
  const ComicDetailChapterList({
    super.key,
    required this.chapters,
    required this.is_dark,
    this.resume_chapter_id = 0,
    required this.on_open,
  });
  @override
  Widget build(BuildContext context) {
    if (chapters.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: ComicDetailStyle.section_top_spacing,
          ),
          child: Center(
            child: Text(
              tr('comics.empty_chapters'),
              style: ComicDetailStyle.label_style(
                context,
                ComicsStyle.is_cjk(context),
                color: ComicDetailStyle.muted(context),
              ),
            ),
          ),
        ),
      );
    }
    return SliverList.separated(
      itemCount: chapters.length,
      separatorBuilder: (context, index) => Divider(
        height: ComicDetailStyle.chapter_separator_height,
        thickness: ComicDetailStyle.chapter_separator_height,
        color: ComicDetailStyle.outline(context),
      ),
      itemBuilder: (context, index) => ComicDetailChapterTile(
        key: ValueKey('comic_detail_chapter_${chapters[index].id}'),
        number: index + 1,
        chapter: chapters[index],
        is_dark: is_dark,
        selected: chapters[index].id == resume_chapter_id,
        on_open: () => on_open(chapters[index].id),
      ),
    );
  }
}

/// 章节图标与序号对齐，完整标题保留在无障碍语义中，辅助大字号会自然增高。
class ComicDetailChapterTile extends StatelessWidget {
  final int number;
  final ComicChapter chapter;
  final bool is_dark;
  final bool selected;
  final VoidCallback on_open;
  const ComicDetailChapterTile({
    super.key,
    required this.number,
    required this.chapter,
    required this.is_dark,
    this.selected = false,
    required this.on_open,
  });
  @override
  Widget build(BuildContext context) {
    final is_cjk = ComicsStyle.is_cjk(context);
    final foreground = ComicDetailStyle.ink(context);
    final secondary = ComicDetailStyle.muted(context);
    return Semantics(
      button: true,
      selected: selected,
      label: chapter.title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: on_open,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: ComicDetailStyle.touch_target,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: ComicDetailStyle.chapter_padding_v,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    width: ComicDetailStyle.chapter_marker_width,
                    child: selected
                        ? Container(
                            width: ComicDetailStyle.chapter_marker_width,
                            height: ComicDetailStyle.chapter_marker_height,
                            decoration: BoxDecoration(
                              color: ColorConstants.dangerColor,
                              borderRadius: BorderRadius.circular(
                                ComicDetailStyle.chapter_marker_radius,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: ComicDetailStyle.chapter_marker_gap),
                  SizedBox(
                    width: ComicDetailStyle.chapter_number_width,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        number.toString().padLeft(2, '0'),
                        style:
                            ComicDetailStyle.label_style(
                              context,
                              is_cjk,
                              color: selected ? foreground : secondary,
                            ).copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: ComicDetailStyle.chapter_title_gap),
                  Expanded(
                    child: Text(
                      chapter.title,
                      maxLines: ComicDetailStyle.chapter_title_max_lines,
                      overflow: TextOverflow.ellipsis,
                      style: ComicDetailStyle.text(
                        context,
                        size: ComicDetailStyle.chapter_title_font_size,
                        color: foreground,
                      ),
                    ),
                  ),
                  const SizedBox(width: ComicDetailStyle.chapter_title_gap),
                  Text(
                    tr(
                      'comics.page_count',
                      namedArgs: {'count': '${chapter.page_count}'},
                    ),
                    style: ComicDetailStyle.label_style(
                      context,
                      is_cjk,
                      color: secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
