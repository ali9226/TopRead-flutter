import 'dart:math' as math;

import 'package:app/components/expandable_synopsis/style.dart';
import 'package:app/components/work_genres_section/style.dart';
import 'package:app/components/work_hero_glass_surface/index.dart';
import 'package:app/components/work_hero_stats/style.dart';
import 'package:app/components/work_introduction_hero/index.dart';
import 'package:app/components/work_reading_actions/style.dart';
import 'package:app/pages/comics/detail/style.dart';
import 'package:app/pages/read/widgets/introduction_section/widgets/author_section/style.dart';
import 'package:app/pages/short_story_read/widgets/introduction/style.dart';
import 'package:app/pages/short_story_read/style.dart';
import 'package:app/util/language_util/index.dart';
import 'package:app/config/color_config.dart';
import 'package:flutter/material.dart';

import 'kind.dart';
import 'pulse.dart';
import 'style.dart';
import 'text_line.dart';

/// 使用真实海报排版承载占位，封面比例、安全区和操作迁移均随真组件演进。
class WorkDetailSkeletonHero extends StatelessWidget {
  const WorkDetailSkeletonHero({
    super.key,
    required this.is_dark,
    required this.kind,
    this.on_back,
  });

  final bool is_dark;
  final WorkDetailSkeletonKind kind;
  final VoidCallback? on_back;

  @override
  Widget build(BuildContext context) {
    final cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    return WorkIntroductionHero(
      key: const ValueKey('work_detail_skeleton_hero'),
      is_dark: is_dark,
      surface_color: kind == WorkDetailSkeletonKind.short_story
          ? is_dark
                ? ShortStoryReadStyle.bg_dark_color
                : ShortStoryReadStyle.bg_light_color
          : null,
      is_loading: true,
      // 无业务标题时只借用标准两行档位，绝不把虚构标题展示给用户。
      title: '',
      on_back: on_back,
      cover: const SkeletonBlock(
        key: ValueKey('work_detail_skeleton_cover'),
        height: double.infinity,
        radius: 0,
        on_hero: true,
      ),
      backdrop: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: is_dark
                ? WorkDetailSkeletonStyle.backdrop_colors
                : [
                    ColorConstants.lightBackgroundColor,
                    ColorConstants.whiteColor,
                  ],
          ),
        ),
      ),
      title_builder: (context, style, on_hero) => Column(
        key: const ValueKey('work_detail_skeleton_title'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          WorkDetailSkeletonStyle.title_lines,
          (index) => SkeletonTextLine(
            font_size: style.fontSize!,
            line_height: style.height!,
            text_style: style,
            width_factor: index == WorkDetailSkeletonStyle.title_lines - 1
                ? cjk
                      ? WorkDetailSkeletonStyle.title_last_line_ratio_cjk
                      : WorkDetailSkeletonStyle.title_last_line_ratio_alphabetic
                : 1,
            on_hero: true,
          ),
        ),
      ),
      metadata_builder: (context, _) => _SkeletonAuthor(kind: kind, cjk: cjk),
      overflow_builder: (context, _) =>
          kind == WorkDetailSkeletonKind.short_story
          ? _SkeletonShortSynopsis(is_dark: is_dark, cjk: cjk)
          : _SkeletonStats(is_dark: is_dark, cjk: cjk),
      genres_builder: (context, _) => _SkeletonGenres(cjk: cjk),
      actions_builder: (context, _, compact) =>
          _SkeletonActions(compact: compact, cjk: cjk),
    );
  }
}

/// 长篇保留头像与关注，短篇及漫画沿用各自的纯作者文字高度。
class _SkeletonAuthor extends StatelessWidget {
  const _SkeletonAuthor({required this.kind, required this.cjk});

  final WorkDetailSkeletonKind kind;
  final bool cjk;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final name_width = scaler.scale(
      cjk
          ? WorkDetailSkeletonStyle.name_width_cjk
          : WorkDetailSkeletonStyle.name_width_alphabetic,
    );
    if (kind != WorkDetailSkeletonKind.novel) {
      final is_short_story = kind == WorkDetailSkeletonKind.short_story;
      return SkeletonTextLine(
        font_size: is_short_story
            ? cjk
                  ? ShortStoryIntroductionStyle.author_font_cjk
                  : ShortStoryIntroductionStyle.author_font_alphabetic
            : cjk
            ? ComicDetailStyle.hero_author_size_cjk
            : ComicDetailStyle.hero_author_size_alphabetic,
        line_height: is_short_story
            ? cjk
                  ? ShortStoryIntroductionStyle.line_height_cjk
                  : ShortStoryIntroductionStyle.line_height_alphabetic
            : ComicDetailStyle.hero_metadata_line_height,
        width: name_width,
        on_hero: true,
      );
    }
    final follow_width = scaler.scale(
      cjk
          ? WorkDetailSkeletonStyle.follow_width_cjk
          : WorkDetailSkeletonStyle.follow_width_alphabetic,
    );
    final follow_height =
        scaler.scale(AuthorStyle.follow_tag_font_size) +
        AuthorStyle.follow_tag_vertical_padding * 2;
    final author = Row(
      children: [
        const SkeletonBlock(
          width: AuthorStyle.author_avatar_size,
          height: AuthorStyle.author_avatar_size,
          radius: AuthorStyle.author_avatar_size,
          on_hero: true,
        ),
        const SizedBox(width: AuthorStyle.author_name_left_spacing),
        Expanded(
          child: SkeletonTextLine(
            font_size: cjk
                ? AuthorStyle.hero_name_size_cjk
                : AuthorStyle.hero_name_size_alphabetic,
            line_height: cjk
                ? AuthorStyle.author_name_height_cjk
                : AuthorStyle.author_name_height_alphabetic,
            width: name_width,
            on_hero: true,
          ),
        ),
      ],
    );
    final follow = SkeletonBlock(
      width: follow_width,
      height: follow_height,
      radius: AuthorStyle.follow_tag_radius,
      on_hero: true,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final required_width =
            AuthorStyle.author_avatar_size +
            AuthorStyle.author_name_left_spacing +
            name_width +
            AuthorStyle.follow_tag_left_spacing +
            follow_width;
        if (constraints.maxWidth < required_width) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              author,
              const SizedBox(height: AuthorStyle.follow_tag_top_spacing),
              follow,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: author),
            const SizedBox(width: AuthorStyle.follow_tag_left_spacing),
            follow,
          ],
        );
      },
    );
  }
}

/// 短篇在封面玻璃区直接预示简介，不再占位已经移除的三列统计。
class _SkeletonShortSynopsis extends StatelessWidget {
  const _SkeletonShortSynopsis({required this.is_dark, required this.cjk});

  final bool is_dark;
  final bool cjk;

  @override
  Widget build(BuildContext context) => WorkHeroGlassSurface(
    key: const ValueKey('work_detail_skeleton_hero_synopsis'),
    on_hero: is_dark,
    is_dark: is_dark,
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ShortStoryIntroductionStyle.synopsis_padding_h,
        vertical: ShortStoryIntroductionStyle.synopsis_padding_v,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: SkeletonTextLine(
                  width: MediaQuery.textScalerOf(context).scale(
                    cjk
                        ? WorkDetailSkeletonStyle
                              .short_synopsis_heading_width_cjk
                        : WorkDetailSkeletonStyle
                              .short_synopsis_heading_width_alphabetic,
                  ),
                  font_size: cjk
                      ? ShortStoryIntroductionStyle.synopsis_title_size_cjk
                      : ShortStoryIntroductionStyle
                            .synopsis_title_size_alphabetic,
                  line_height:
                      ShortStoryIntroductionStyle.synopsis_title_height,
                  on_hero: true,
                ),
              ),
              SizedBox(
                width: ExpandableSynopsisStyle.toggle_extent,
                height: ExpandableSynopsisStyle.toggle_extent,
                child: Center(
                  child: Transform.translate(
                    offset: const Offset(
                      0,
                      -ExpandableSynopsisStyle.compact_toggle_icon_lift,
                    ),
                    child: const SkeletonBlock(
                      width: ExpandableSynopsisStyle.compact_toggle_icon_size,
                      height: ExpandableSynopsisStyle.compact_toggle_icon_size,
                      on_hero: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: ShortStoryIntroductionStyle.synopsis_heading_gap,
          ),
          Column(
            key: const ValueKey('work_detail_skeleton_hero_synopsis_text'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(
              ShortStoryIntroductionStyle.synopsis_collapsed_lines,
              (index) => SkeletonTextLine(
                font_size: cjk
                    ? ShortStoryIntroductionStyle.synopsis_size_cjk
                    : ShortStoryIntroductionStyle.synopsis_size_alphabetic,
                line_height: cjk
                    ? ShortStoryIntroductionStyle.synopsis_height_cjk
                    : ShortStoryIntroductionStyle.synopsis_height_alphabetic,
                width_factor:
                    index ==
                        ShortStoryIntroductionStyle.synopsis_collapsed_lines - 1
                    ? WorkDetailSkeletonStyle.synopsis_last_line_ratio
                    : 1,
                on_hero: true,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// 统计与真实玻璃面板共用外沿、间距及最小单项宽度。
class _SkeletonStats extends StatelessWidget {
  const _SkeletonStats({required this.is_dark, required this.cjk});

  final bool is_dark;
  final bool cjk;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: const ValueKey('work_detail_skeleton_stats'),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(WorkHeroStatsStyle.radius),
      border: Border.all(
        color: WorkHeroStatsStyle.surface_border(
          on_hero: is_dark,
          is_dark: is_dark,
        ),
        width: WorkHeroStatsStyle.surface_border_width,
      ),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: WorkHeroStatsStyle.surface_colors(
          on_hero: is_dark,
          is_dark: is_dark,
        ),
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: WorkHeroStatsStyle.surface_padding_h,
        vertical: WorkHeroStatsStyle.surface_padding_v,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final min_width = math.max(
            WorkHeroStatsStyle.item_min_width,
            MediaQuery.textScalerOf(
                  context,
                ).scale(WorkDetailSkeletonStyle.value_width) +
                WorkHeroStatsStyle.item_padding_h * 2,
          );
          final columns = math.max(
            1,
            math.min(
              WorkDetailSkeletonStyle.stat_count,
              (constraints.maxWidth / min_width).floor(),
            ),
          );
          return Wrap(
            runSpacing: WorkHeroStatsStyle.row_gap,
            children: List.generate(
              WorkDetailSkeletonStyle.stat_count,
              (index) => SizedBox(
                width: math.max(
                  0,
                  constraints.maxWidth / columns -
                      WorkHeroStatsStyle.layout_tolerance,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: WorkHeroStatsStyle.item_min_height,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: WorkHeroStatsStyle.item_padding_h,
                    ),
                    child: Column(
                      children: [
                        SkeletonTextLine(
                          font_size: cjk
                              ? WorkHeroStatsStyle.value_size_cjk
                              : WorkHeroStatsStyle.value_size_alphabetic,
                          line_height: cjk
                              ? WorkHeroStatsStyle.value_height_cjk
                              : WorkHeroStatsStyle.value_height_alphabetic,
                          width: WorkDetailSkeletonStyle.value_width,
                          alignment: Alignment.center,
                          on_hero: true,
                        ),
                        const SizedBox(
                          height: WorkHeroStatsStyle.icon_label_gap,
                        ),
                        SkeletonTextLine(
                          font_size: cjk
                              ? WorkHeroStatsStyle.label_size_cjk
                              : WorkHeroStatsStyle.label_size_alphabetic,
                          line_height: cjk
                              ? WorkHeroStatsStyle.label_height_cjk
                              : WorkHeroStatsStyle.label_height_alphabetic,
                          width: cjk
                              ? WorkDetailSkeletonStyle.label_width_cjk
                              : WorkDetailSkeletonStyle.label_width_alphabetic,
                          alignment: Alignment.center,
                          on_hero: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _SkeletonGenres extends StatelessWidget {
  const _SkeletonGenres({required this.cjk});
  final bool cjk;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final height = math.max(
      WorkGenresSectionStyle.hero_tag_min_height,
      scaler.scale(
            cjk
                ? WorkGenresSectionStyle.hero_tag_font_cjk
                : WorkGenresSectionStyle.hero_tag_font_alphabetic,
          ) +
          WorkGenresSectionStyle.hero_tag_padding_v * 2,
    );
    return Wrap(
      key: const ValueKey('work_detail_skeleton_genres'),
      spacing: WorkGenresSectionStyle.hero_tag_spacing,
      runSpacing: WorkGenresSectionStyle.hero_tag_run_spacing,
      children:
          (cjk
                  ? WorkDetailSkeletonStyle.tag_widths_cjk
                  : WorkDetailSkeletonStyle.tag_widths_alphabetic)
              .map(
                (width) => SkeletonBlock(
                  width: scaler.scale(width),
                  height: height,
                  radius: WorkGenresSectionStyle.tag_radius,
                  on_hero: true,
                ),
              )
              .toList(),
    );
  }
}

class _SkeletonActions extends StatelessWidget {
  const _SkeletonActions({required this.compact, required this.cjk});
  final bool compact;
  final bool cjk;

  @override
  Widget build(BuildContext context) {
    final extent = compact
        ? WorkReadingActionsStyle.compact_height
        : WorkReadingActionsStyle.height;
    final radius = compact
        ? WorkReadingActionsStyle.compact_radius
        : WorkReadingActionsStyle.radius;
    final font_size = compact
        ? cjk
              ? WorkReadingActionsStyle.compact_font_size_cjk
              : WorkReadingActionsStyle.compact_font_size_alphabetic
        : cjk
        ? WorkReadingActionsStyle.font_size_cjk
        : WorkReadingActionsStyle.font_size_alphabetic;
    final height = math.max(
      extent,
      MediaQuery.textScalerOf(context).scale(font_size) *
              (cjk
                  ? WorkReadingActionsStyle.line_height_cjk
                  : WorkReadingActionsStyle.line_height_alphabetic) +
          WorkReadingActionsStyle.vertical_padding * 2,
    );
    final gap = compact
        ? WorkReadingActionsStyle.compact_gap
        : WorkReadingActionsStyle.gap;
    final primary = SkeletonBlock(
      height: height,
      radius: radius,
      on_hero: true,
    );
    final favorite = SkeletonBlock(
      width: extent,
      height: extent,
      radius: radius,
      on_hero: true,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <
            (compact
                ? WorkReadingActionsStyle.compact_min_inline_width
                : WorkReadingActionsStyle.min_inline_width)) {
          return Column(
            key: const ValueKey('work_detail_skeleton_actions'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              primary,
              SizedBox(height: gap),
              Align(alignment: AlignmentDirectional.centerEnd, child: favorite),
            ],
          );
        }
        return Row(
          key: const ValueKey('work_detail_skeleton_actions'),
          children: [
            Expanded(child: primary),
            SizedBox(width: gap),
            favorite,
          ],
        );
      },
    );
  }
}
