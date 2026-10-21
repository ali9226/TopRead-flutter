// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:app/components/content_category_tag/index.dart';
import 'package:app/pages/comics/detail/widgets/warm_paper.dart';
import 'package:app/pages/comics/detail/widgets/about_story/index.dart';
import 'package:app/pages/comics/detail/widgets/similar_comics/index.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/detail/style.dart';

/// TODO 简介页内容：故事简介、类型和相似漫画；纸面金叶作为内容背景。
class ComicDetailOverviewTab extends StatelessWidget {
  final VoidCallback? on_author;
  final ComicDetail detail;
  final bool is_dark;
  final List<ComicItem> similar_comics;
  final VoidCallback? on_see_all_similar;
  final ValueChanged<int>? on_similar_tap;
  const ComicDetailOverviewTab({
    super.key,
    required this.detail,
    this.on_author,
    required this.is_dark,
    this.similar_comics = const <ComicItem>[],
    this.on_see_all_similar,
    this.on_similar_tap,
  });

  @override
  Widget build(BuildContext context) {
    final String description =
        detail.selected_language?.description.trim() ?? '';
    final List<String> genre_names = detail.comic.categories
        .map((cat) => _category_name(context, cat))
        .toList();

    return ComicWarmPaper(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ComicDetailStyle.content_padding_h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            /// About this story
            ComicAboutStory(description: description),
            const SizedBox(height: ComicDetailStyle.section_spacing),

            /// Genres
            if (genre_names.isNotEmpty) ...<Widget>[
              _SectionTitle(title: tr('comics.genres')),
              const SizedBox(height: ComicDetailStyle.section_title_gap),
              _GenresRow(names: genre_names, content_id: detail.comic.id),
              const SizedBox(height: ComicDetailStyle.section_spacing),
            ],

            /// Similar comics
            if (similar_comics.isNotEmpty) ...<Widget>[
              _SectionTitle(
                title: tr('comics.similar_comics'),
                trailing_text: tr('comics.see_all'),
                trailing: Icons.chevron_right_rounded,
                on_trailing: on_see_all_similar,
              ),
              const SizedBox(height: ComicDetailStyle.section_title_gap),
              ComicSimilarComicsRow(
                comics: similar_comics,
                on_tap: on_similar_tap,
              ),
              const SizedBox(height: ComicDetailStyle.section_spacing),
            ],
          ],
        ),
      ),
    );
  }

  String _category_name(BuildContext context, Map<String, dynamic> cat) {
    final String code = Localizations.localeOf(context).languageCode;
    final Map<String, dynamic> translations = cat['translations'] is Map
        ? Map<String, dynamic>.from(cat['translations'] as Map)
        : <String, dynamic>{};
    return translations[code]?.toString() ?? cat['name']?.toString() ?? '';
  }
}

/// 区块标题：金色强调条 + 标题 + 可选尾部（箭头/文字）。
class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData? trailing;
  final String? trailing_text;
  final VoidCallback? on_trailing;
  const _SectionTitle({
    required this.title,
    this.trailing,
    this.trailing_text,
    this.on_trailing,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Container(
        width: ComicDetailStyle.section_accent_width,
        height: ComicDetailStyle.section_accent_height,
        decoration: BoxDecoration(
          color: ComicDetailStyle.accent(context),
          borderRadius: BorderRadius.circular(
            ComicDetailStyle.section_accent_radius,
          ),
        ),
      ),
      const SizedBox(width: ComicDetailStyle.section_accent_gap),
      Expanded(
        child: Text(
          title,
          style: TextStyle(
            fontSize: ComicDetailStyle.section_title_font_size,
            fontWeight: ComicDetailStyle.weight_semi_bold,
            color: ComicDetailStyle.ink(context),
          ),
        ),
      ),
      if (trailing_text != null)
        InkWell(
          onTap: on_trailing,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              trailing_text!,
              style: TextStyle(
                fontSize: ComicDetailStyle.similar_see_all_font_size,
                color: ComicDetailStyle.muted(context),
              ),
            ),
          ),
        ),
      if (trailing != null)
        GestureDetector(
          onTap: on_trailing,
          child: Icon(
            trailing,
            size: 22,
            color: ComicDetailStyle.muted(context),
          ),
        ),
    ],
  );
}

/// Genres 彩色胶囊行。
class _GenresRow extends StatelessWidget {
  final List<String> names;
  final int content_id;
  const _GenresRow({required this.names, required this.content_id});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: ContentCategoryTagStyle.spacing,
    runSpacing: ContentCategoryTagStyle.spacing,
    children: List<Widget>.generate(
      names.length,
      (index) => ContentCategoryTag(
        label: names[index],
        color: ContentCategoryTagStyle.color_for(
          content_id: content_id,
          index: index,
        ),
      ),
    ),
  );
}
