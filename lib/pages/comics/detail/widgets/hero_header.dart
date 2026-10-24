// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:app/components/work_introduction_hero/index.dart';
import 'package:app/components/work_introduction_hero/style.dart';
import 'package:app/components/work_hero_stats/index.dart';
import 'package:app/components/work_genres_section/index.dart';
import 'package:app/components/work_reading_actions/index.dart';
import 'package:app/util/language_util/index.dart';
import 'package:app/models/comics.dart';
import 'package:app/config/color_config.dart';
import 'package:app/pages/comics/detail/style.dart';
import 'package:app/pages/comics/widgets/comic_image.dart';

/// 三种作品简介共用自然增高海报，完整标题与作者始终在封面右侧排版。
class ComicDetailHeroHeader extends StatelessWidget {
  final ComicDetail detail;
  final VoidCallback on_back;
  final VoidCallback on_share;
  final VoidCallback on_read;
  final VoidCallback on_collect;
  final bool is_dark;
  final Widget? cover_image;
  final bool? collected;
  final bool collecting;
  final bool can_read;
  final bool continuing;
  final bool chapter_mode;
  const ComicDetailHeroHeader({
    super.key,
    required this.detail,
    required this.on_back,
    required this.on_share,
    VoidCallback? on_more,
    required this.on_read,
    required this.on_collect,
    required this.is_dark,
    this.cover_image,
    this.collected,
    this.collecting = false,
    this.can_read = true,
    this.continuing = false,
    this.chapter_mode = false,
  });

  @override
  Widget build(BuildContext context) {
    final cover_url = detail.selected_language?.cover_url.isNotEmpty == true
        ? detail.selected_language!.cover_url
        : detail.comic.cover_url;
    final title = detail.selected_language?.title.trim().isNotEmpty == true
        ? detail.selected_language!.title.trim()
        : detail.comic.title.trim();
    return SliverToBoxAdapter(
      child: WorkIntroductionHero(
        is_dark: is_dark,
        title: title,
        backdrop:
            cover_image ?? ComicImage(url: cover_url, semantic_label: title),
        cover: cover_image ?? ComicImage(url: cover_url, semantic_label: title),
        on_back: on_back,
        on_share: on_share,
        title_builder: (context, style, on_hero) =>
            Text(title, semanticsLabel: title, style: style),
        metadata_builder: (context, on_hero) {
          final cjk = LanguageUtil.is_cjk_language(
            Localizations.localeOf(context).languageCode,
          );
          return Text(
            detail.comic.author_name.trim().isEmpty
                ? easy.tr('comics.unknown_author')
                : detail.comic.author_name.trim(),
            key: const ValueKey('comic_hero_author'),
            style: TextStyle(
              color: on_hero
                  ? ColorConstants.whiteColor
                  : ComicDetailStyle.ink(context),
              fontSize: cjk
                  ? ComicDetailStyle.hero_author_size_cjk
                  : ComicDetailStyle.hero_author_size_alphabetic,
              height: ComicDetailStyle.hero_metadata_line_height,
              fontWeight: ComicDetailStyle.weight_medium,
              shadows: on_hero ? WorkIntroductionHeroStyle.title_shadows : null,
            ),
          );
        },
        overflow_builder: (context, on_hero) {
          final String rating_text = detail.comic.rating > 0
              ? detail.comic.rating.toStringAsFixed(1)
              : '—';
          final String rating_count = ComicDetailStyle.format_count(
            detail.comic.rating_count,
          );
          return WorkHeroStatsRow(
            on_hero: on_hero,
            is_dark: ComicDetailStyle.is_dark(context),
            items: [
              WorkHeroStat(
                icon: Icons.star_rounded,
                value: rating_text,
                label: '$rating_count ${easy.tr('comics.ratings')}',
              ),
              WorkHeroStat(
                icon: Icons.local_fire_department_rounded,
                value: ComicDetailStyle.format_count(detail.comic.view_count),
                label: easy.tr('comics.views'),
              ),
              WorkHeroStat(
                icon: Icons.favorite_rounded,
                icon_color: ColorConstants.dangerColor,
                value: ComicDetailStyle.format_count(
                  detail.comic.favorite_count,
                ),
                label: easy.tr('comics.favorites'),
              ),
            ],
          );
        },
        genres_builder: () {
          final genre_names = detail.comic.categories
              .map((category) {
                final code = Localizations.localeOf(context).languageCode;
                final translations = category['translations'];
                return (translations is Map
                        ? translations[code]?.toString()
                        : null) ??
                    category['name']?.toString() ??
                    '';
              })
              .where((name) => name.trim().isNotEmpty)
              .toList();
          if (genre_names.isEmpty) return null;
          return (context, on_hero) => WorkGenresSection(
            key: const ValueKey('comic_hero_genres'),
            title: '',
            tags: genre_names,
            is_dark: is_dark,
            embedded: true,
          );
        }(),
        actions_builder: (context, on_hero, compact) => WorkReadingActions(
          compact: compact,
          on_read: chapter_mode ? null : on_read,
          on_favorite: on_collect,
          can_read: can_read,
          continuing: continuing,
          favorited: collected ?? detail.is_collected,
          favorite_loading: collecting,
          on_hero: on_hero,
          is_dark: is_dark,
          read_key: const ValueKey('comic_read_button'),
          favorite_key: const ValueKey('comic_save_button'),
        ),
      ),
    );
  }
}
