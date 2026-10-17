// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app/components/svg_icon/index.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/detail/style.dart';
import 'package:app/pages/comics/style.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/tag_section/index.dart';

/// TODO 书名和作者沿用小说的居中信息层级，分类直接渲染同一小说组件。
class ComicDetailInfoSection extends StatelessWidget {
  final ComicDetail detail;
  final bool is_dark;
  final bool is_cjk;
  const ComicDetailInfoSection({
    super.key,
    required this.detail,
    required this.is_dark,
    required this.is_cjk,
  });

  @override
  Widget build(BuildContext context) {
    final title = detail.selected_language?.title.isNotEmpty == true
        ? detail.selected_language!.title
        : detail.comic.title;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          title,
          textAlign: TextAlign.center,
          style:
              ComicDetailStyle.text(
                context,
                size: is_cjk
                    ? ComicDetailStyle.title_font_size_cjk
                    : ComicDetailStyle.title_font_size_alphabetic,
                strong: true,
              ).copyWith(
                height: is_cjk
                    ? ComicDetailStyle.title_height_cjk
                    : ComicDetailStyle.title_height_alphabetic,
              ),
        ),
        if (title != detail.comic.title && detail.comic.title.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(
              top: ComicDetailStyle.original_title_spacing,
            ),
            child: Text(
              detail.comic.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ComicDetailStyle.label_style(
                context,
                is_cjk,
                color: ComicDetailStyle.muted(context),
              ),
            ),
          ),
        if (detail.comic.author_name.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(
              top: ComicDetailStyle.author_top_spacing,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SvgIcon(
                  name:
                      'avatar_${(detail.comic.author_id % ComicDetailStyle.author_avatar_variants).toString().padLeft(2, '0')}',
                  width: ComicDetailStyle.author_avatar_size,
                  height: ComicDetailStyle.author_avatar_size,
                ),
                const SizedBox(width: ComicDetailStyle.author_avatar_gap),
                Flexible(
                  child: Text(
                    detail.comic.author_name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ComicDetailStyle.label_style(
                      context,
                      is_cjk,
                      color: ComicDetailStyle.muted(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(
            top: ComicDetailStyle.stats_top_spacing,
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: ComicDetailStyle.stats_spacing,
            runSpacing: ComicDetailStyle.stats_spacing,
            children: <Widget>[
              _Metadata(
                label: tr(
                  'comics.chapter_count',
                  namedArgs: {'count': '${detail.chapters.length}'},
                ),
                is_cjk: is_cjk,
              ),
              _Metadata(
                label: tr(
                  'comics.language_count',
                  namedArgs: {'count': '${detail.languages.length}'},
                ),
                is_cjk: is_cjk,
              ),
              _Metadata(
                label: tr(
                  detail.comic.completion_status == 'completed'
                      ? 'comics.completed'
                      : 'comics.ongoing',
                ),
                is_cjk: is_cjk,
              ),
            ],
          ),
        ),
        if (detail.comic.categories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(
              top: ComicDetailStyle.tags_top_spacing,
            ),
            child: ReadTagSection(
              is_dark: is_dark,
              tag_list: detail.comic.categories
                  .map(
                    (category) => ComicsStyle.category_name(context, category),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

/// TODO 统计使用中性文字而非三套胶囊，保证分类仍是这一行唯一彩色标签。
class _Metadata extends StatelessWidget {
  const _Metadata({required this.label, required this.is_cjk});
  final String label;
  final bool is_cjk;
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: ComicDetailStyle.label_style(
      context,
      is_cjk,
      color: ComicDetailStyle.muted(context),
    ),
  );
}
