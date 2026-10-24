import 'package:app/components/network_cover_image/index.dart';
import 'package:app/components/title_with_story_id/index.dart';
import 'package:app/components/work_genres_section/index.dart';
import 'package:app/components/work_introduction_hero/index.dart';
import 'package:app/components/work_introduction_hero/style.dart';
import 'package:app/pages/read/logic.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/author_section/index.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/stat_section/index.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import './actions.dart';

/// 长篇仅提供原有数据与交互，海报和完整标题的响应式布局由三类作品共用。
class ReadIntroductionHero extends StatelessWidget {
  const ReadIntroductionHero({
    super.key,
    required this.is_dark,
    required this.detail,
    this.on_focus_changed,
    this.on_cover_replaced,
    this.on_back,
    this.on_share,
    this.on_read,
    this.on_favorite,
    this.favorited = false,
    this.favorite_loading = false,
    this.continuing = false,
    this.on_author_tap,
    this.on_rating_tap,
    this.bottom_overlap = WorkIntroductionHeroStyle.default_overlap,
  });
  final bool is_dark;
  final ReadDetail detail;
  final ValueChanged<bool>? on_focus_changed;
  final void Function(String cover_url, int cover_width, int cover_height)?
  on_cover_replaced;
  final VoidCallback? on_back;
  final VoidCallback? on_share;
  final VoidCallback? on_read;
  final VoidCallback? on_favorite;
  final bool favorited;
  final bool favorite_loading;
  final bool continuing;
  final VoidCallback? on_author_tap;
  final VoidCallback? on_rating_tap;
  final double bottom_overlap;

  @override
  Widget build(BuildContext context) => WorkIntroductionHero(
    key: const ValueKey('novel_introduction_hero'),
    is_dark: is_dark,
    title: detail.title,
    status_label: detail.status_text,
    status_key: const ValueKey('novel_hero_status'),
    overlap: bottom_overlap,
    on_back: on_back,
    on_share: on_share,
    backdrop: detail.cover_url.isEmpty
        ? const ColoredBox(color: WorkIntroductionHeroStyle.poster_background)
        : CachedNetworkImage(
            imageUrl: detail.cover_url,
            fit: BoxFit.cover,
            placeholder: (_, _) => const ColoredBox(
              color: WorkIntroductionHeroStyle.poster_background,
            ),
            errorWidget: (_, _, _) => const ColoredBox(
              color: WorkIntroductionHeroStyle.poster_background,
            ),
          ),
    cover: SizedBox.expand(
      key: const ValueKey('novel_hero_cover'),
      child: NetworkCoverImage(
        image_url: detail.cover_url,
        width: double.infinity,
        height: double.infinity,
        border_radius: WorkIntroductionHeroStyle.cover_radius,
        is_dark: is_dark,
        error_text: '${detail.story_id}',
      ),
    ),
    title_builder: (context, style, on_hero) => TitleWithStoryId(
      key: const ValueKey('novel_hero_title'),
      title: detail.title,
      story_id: detail.story_id,
      on_cover_replaced: on_cover_replaced,
      text_align: TextAlign.start,
      title_style: style,
    ),
    metadata_builder: (context, on_hero) => ReadAuthorSection(
      key: const ValueKey('novel_hero_author'),
      is_dark: is_dark,
      detail: detail,
      hero: on_hero,
      on_focus_changed: on_focus_changed,
      on_author_tap: on_author_tap,
    ),
    overflow_builder: (context, on_hero) => ReadStatSection(
      key: const ValueKey('novel_hero_stats'),
      is_dark: is_dark,
      detail: detail,
      hero: on_hero,
      on_rating_tap: on_rating_tap,
    ),
    genres_builder: detail.tag_list.isEmpty
        ? null
        : (context, on_hero) => WorkGenresSection(
            key: const ValueKey('novel_hero_genres'),
            title: '',
            tags: detail.tag_list,
            is_dark: is_dark,
            embedded: true,
          ),
    actions_builder: on_read == null && on_favorite == null
        ? null
        : (context, on_hero, compact) => ReadIntroductionActions(
            compact: compact,
            on_read: on_read,
            on_favorite: on_favorite,
            favorited: favorited,
            favorite_loading: favorite_loading,
            continuing: continuing,
            on_hero: on_hero,
            is_dark: is_dark,
          ),
  );
}
