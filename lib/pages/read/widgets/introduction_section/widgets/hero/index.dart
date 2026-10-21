// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;
import 'package:app/components/network_cover_image/index.dart';
import 'package:app/components/title_with_story_id/index.dart';
import 'package:app/components/window_content_layout/index.dart';
import 'package:app/config/font_config.dart';
import 'package:app/pages/read/logic.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/author_section/index.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/hero/style.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/stat_section/index.dart';
import 'package:app/util/language_util/index.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/hero/actions.dart';

/// TODO 原生长篇数据的简介海报；只重排既有书名、作者和统计，保留调试ID与换封面入口。
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
    this.on_author_tap,
    this.on_rating_tap,
    this.bottom_overlap = 0,
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
  final VoidCallback? on_author_tap;
  final VoidCallback? on_rating_tap;

  /// 内容面板会覆盖的装饰高度；为封面和按钮保留原有底部呼吸空间。
  final double bottom_overlap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final content_width = math.min(
        width,
        ReadIntroductionHeroStyle.max_content_width,
      );
      final inset =
          (width - content_width) / 2 +
          content_width * ReadIntroductionHeroStyle.horizontal_inset_ratio;
      final scale = (content_width / ReadIntroductionHeroStyle.scale_base_width)
          .clamp(ReadIntroductionHeroStyle.min_scale, 1.0);
      final cover_width = math.min(
        ReadIntroductionHeroStyle.cover_max_width,
        content_width * ReadIntroductionHeroStyle.cover_width_ratio,
      );
      final top_safe = MediaQuery.paddingOf(context).top;
      final cjk = LanguageUtil.is_cjk_language(
        Localizations.localeOf(context).languageCode,
      );
      final backdrop_space = math.max(
        top_safe +
            ReadIntroductionHeroStyle.nav_size +
            ReadIntroductionHeroStyle.nav_content_gap,
        math.min(
              content_width * ReadIntroductionHeroStyle.backdrop_height_ratio,
              ReadIntroductionHeroStyle.backdrop_max_height,
            ) +
            top_safe,
      );
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          key: const ValueKey('novel_introduction_hero'),
          children: [
            Positioned.fill(
              child: detail.cover_url.isEmpty
                  ? const ColoredBox(color: Color(0xFF29292C))
                  : CachedNetworkImage(
                      imageUrl: detail.cover_url,
                      fit: BoxFit.cover,
                      placeholder: (_, _) =>
                          const ColoredBox(color: Color(0xFF29292C)),
                      errorWidget: (_, _, _) =>
                          const ColoredBox(color: Color(0xFF29292C)),
                    ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: ReadIntroductionHeroStyle.scrim_colors,
                    stops: ReadIntroductionHeroStyle.scrim_stops,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                inset,
                backdrop_space,
                inset,
                ReadIntroductionHeroStyle.content_bottom + bottom_overlap,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    key: const ValueKey('novel_hero_cover'),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        ReadIntroductionHeroStyle.cover_radius,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      boxShadow: ReadIntroductionHeroStyle.cover_shadow,
                    ),
                    child: NetworkCoverImage(
                      image_url: detail.cover_url,
                      width: cover_width,
                      height:
                          cover_width *
                          ReadIntroductionHeroStyle.cover_aspect_ratio,
                      border_radius: ReadIntroductionHeroStyle.cover_radius,
                      is_dark: is_dark,
                      error_text: '${detail.story_id}',
                    ),
                  ),
                  const SizedBox(width: ReadIntroductionHeroStyle.content_gap),
                  Expanded(
                    child: WindowReservedRegionPadding(
                      child: Column(
                        key: const ValueKey('novel_hero_metadata'),
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TitleWithStoryId(
                            key: const ValueKey('novel_hero_title'),
                            title: detail.title,
                            story_id: detail.story_id,
                            on_cover_replaced: on_cover_replaced,
                            text_align: TextAlign.start,
                            title_style: TextStyle(
                              color: Colors.white,
                              fontFamily: cjk ? null : 'Georgia',
                              fontFamilyFallback: cjk
                                  ? null
                                  : const ['Times New Roman', 'serif'],
                              fontSize:
                                  (cjk
                                      ? ReadIntroductionHeroStyle.title_size_cjk
                                      : ReadIntroductionHeroStyle
                                            .title_size_alphabetic) *
                                  scale,
                              height: cjk
                                  ? ReadIntroductionHeroStyle.title_height_cjk
                                  : ReadIntroductionHeroStyle
                                        .title_height_alphabetic,
                              fontWeight: FontConfig.adjustedWeight(
                                FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: ReadIntroductionHeroStyle.title_author_gap,
                          ),
                          ReadAuthorSection(
                            key: const ValueKey('novel_hero_author'),
                            is_dark: is_dark,
                            detail: detail,
                            hero: true,
                            on_focus_changed: on_focus_changed,
                            on_author_tap: on_author_tap,
                          ),
                          const SizedBox(
                            height: ReadIntroductionHeroStyle.author_stats_gap,
                          ),
                          ReadStatSection(
                            key: const ValueKey('novel_hero_stats'),
                            is_dark: is_dark,
                            detail: detail,
                            hero: true,
                            on_rating_tap: on_rating_tap,
                          ),
                          if (on_read != null || on_favorite != null) ...[
                            const SizedBox(
                              height:
                                  ReadIntroductionHeroStyle.author_stats_gap,
                            ),
                            ReadIntroductionActions(
                              on_read: on_read,
                              on_favorite: on_favorite,
                              favorited: favorited,
                              favorite_loading: favorite_loading,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (on_back != null || on_share != null)
              Positioned(
                top: top_safe + ReadIntroductionHeroStyle.nav_top,
                left: ReadIntroductionHeroStyle.nav_inset,
                right: ReadIntroductionHeroStyle.nav_inset,
                child: WindowReservedRegionPadding(
                  child: Row(
                    children: [
                      if (on_back != null)
                        _navigation(
                          context,
                          icon: Icons.chevron_left_rounded,
                          label: MaterialLocalizations.of(
                            context,
                          ).backButtonTooltip,
                          on_tap: on_back!,
                        ),
                      const Spacer(),
                      if (on_share != null)
                        _navigation(
                          context,
                          icon: Icons.share_outlined,
                          label: MaterialLocalizations.of(
                            context,
                          ).shareButtonLabel,
                          on_tap: on_share!,
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );

  /// TODO 命中区始终44像素，视觉圆形内缩，沿用漫画海报导航的对比度与安全区处理。
  Widget _navigation(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback on_tap,
  }) => SizedBox.square(
    dimension: ReadIntroductionHeroStyle.nav_size,
    child: Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: on_tap,
          child: Padding(
            padding: const EdgeInsets.all(
              ReadIntroductionHeroStyle.nav_visual_inset,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: ReadIntroductionHeroStyle.nav_icon_size,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
