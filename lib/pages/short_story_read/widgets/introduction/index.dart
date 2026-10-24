// ignore_for_file: non_constant_identifier_names

import 'package:app/components/novel_cover/index.dart';
import 'package:app/components/work_reading_actions/index.dart';
import 'package:app/components/title_with_story_id/index.dart';
import 'package:app/components/work_genres_section/index.dart';
import 'package:app/components/work_introduction_hero/index.dart';
import 'package:app/components/work_introduction_hero/style.dart';
import 'package:app/config/font_config.dart';
import 'package:app/models/short_story_item.dart';
import 'package:app/models/short_story_read_data.dart';
import 'package:app/pages/short_story_read/style.dart';
import 'package:app/util/language_util/index.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'logic.dart';
import 'style.dart';
import 'synopsis.dart';

/// 短篇封面区沿用同一个作品海报，阅读正文与进度仍由阅读页独立管理。
class ShortStoryIntroduction extends StatelessWidget {
  const ShortStoryIntroduction({
    super.key,
    required this.detail,
    required this.is_dark,
    required this.on_back,
    required this.on_favorite,
    this.on_share,
    this.on_read,
    this.continuing = false,
    this.on_comment,
    this.on_cover_replaced,
    this.favorite_loading = false,
    this.show_rating = true,
    this.show_comments = true,
    this.catalog_entries = const [],
    this.tags = const [],
    this.cover_image,
    this.backdrop_image,
  });

  final ShortStoryReadData detail;
  final bool is_dark;
  final VoidCallback on_back;
  final VoidCallback on_favorite;
  final VoidCallback? on_share;
  final VoidCallback? on_read;
  final bool continuing;
  final VoidCallback? on_comment;
  final void Function(String cover_url, int cover_width, int cover_height)?
  on_cover_replaced;
  final bool favorite_loading;

  /// 保留旧调用参数兼容；短篇封面已改为简介，不再展示统计。
  final bool show_rating;

  /// 保留旧调用参数兼容，封面简介不再渲染评论统计。
  final bool show_comments;
  final List<ShortStoryItem> catalog_entries;
  final List<String> tags;

  /// 测试和离线预览可注入本地图像；正式页面默认使用同一真实作品封面。
  final Widget? cover_image;
  final Widget? backdrop_image;

  @override
  Widget build(BuildContext context) => WorkIntroductionHero(
    key: const ValueKey('short_story_introduction'),
    is_dark: is_dark,
    surface_color: is_dark
        ? ShortStoryReadStyle.bg_dark_color
        : ShortStoryReadStyle.bg_light_color,
    title: detail.title,
    overlap: WorkIntroductionHeroStyle.default_overlap,
    cover:
        cover_image ??
        LayoutBuilder(
          builder: (context, constraints) => NovelCover(
            image_url: detail.cover_url,
            description: detail.introduction,
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            border_radius: 0,
            is_dark: is_dark,
          ),
        ),
    backdrop:
        backdrop_image ??
        (detail.cover_url.isEmpty
            ? const ColoredBox(
                color: ShortStoryIntroductionStyle.backdrop_placeholder,
              )
            : CachedNetworkImage(
                imageUrl: detail.cover_url,
                fit: BoxFit.cover,
                placeholder: (_, _) => const ColoredBox(
                  color: ShortStoryIntroductionStyle.backdrop_placeholder,
                ),
                errorWidget: (_, _, _) => const ColoredBox(
                  color: ShortStoryIntroductionStyle.backdrop_placeholder,
                ),
              )),
    title_builder: (context, style, on_hero) => TitleWithStoryId(
      key: const ValueKey('short_story_introduction_title'),
      title: detail.title,
      story_id: detail.id,
      title_style: style,
      on_cover_replaced: on_cover_replaced,
    ),
    metadata_builder: (context, on_hero) {
      final cjk = LanguageUtil.is_cjk_language(context.locale.languageCode);
      final foreground = ShortStoryIntroductionStyle.foreground(
        is_dark,
        on_hero,
      );
      final author = resolve_short_story_author_name(
        catalog_entries,
        detail.id,
      );
      if (author.isEmpty) return const SizedBox.shrink();
      return Text(
        author,
        key: const ValueKey('short_story_introduction_author'),
        style: TextStyle(
          color: foreground,
          fontSize: cjk
              ? ShortStoryIntroductionStyle.author_font_cjk
              : ShortStoryIntroductionStyle.author_font_alphabetic,
          height: cjk
              ? ShortStoryIntroductionStyle.line_height_cjk
              : ShortStoryIntroductionStyle.line_height_alphabetic,
          fontWeight: FontConfig.adjustedWeight(FontWeight.w400),
          shadows: on_hero ? WorkIntroductionHeroStyle.title_shadows : null,
        ),
      );
    },
    overflow_builder: detail.introduction.trim().isEmpty
        ? null
        : (context, on_hero) => ShortStorySynopsis(
            key: ValueKey('short_story_synopsis_${detail.id}'),
            description: detail.introduction,
            is_dark: is_dark,
            on_hero: on_hero,
          ),
    genres_builder: tags.isEmpty
        ? null
        : (context, on_hero) => WorkGenresSection(
            key: const ValueKey('short_story_hero_genres'),
            title: '',
            tags: tags,
            is_dark: is_dark,
            embedded: true,
          ),
    actions_builder: (context, on_hero, compact) => WorkReadingActions(
      compact: compact,
      on_read: on_read,
      on_favorite: on_favorite,
      favorited: detail.is_favorited,
      favorite_loading: favorite_loading,
      continuing: continuing,
      on_hero: on_hero,
      is_dark: is_dark,
      read_key: const ValueKey('short_story_hero_read'),
      favorite_key: const ValueKey('short_story_hero_favorite'),
    ),
    on_back: on_back,
    on_share: on_share,
  );
}
