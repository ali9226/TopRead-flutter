// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:app/components/window_content_layout/index.dart';
import 'package:app/util/language_util/index.dart';
import 'package:app/models/comics.dart';
import 'package:app/config/color_config.dart';
import 'package:app/pages/comics/detail/style.dart';
import 'package:app/pages/comics/widgets/comic_image.dart';

/// 海报 Hero：全幅封面背景 + 封面卡 + 标题/标签/统计/CTA。
///
/// 布局与设计图一致：封面铺满顶部，底部左侧浮动封面卡（含角标），
/// 右侧纵向排列标题、分类标签、统计数据、操作按钮。
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
    final String cover_url =
        detail.selected_language?.cover_url.isNotEmpty == true
        ? detail.selected_language!.cover_url
        : detail.comic.cover_url;
    final double top_padding = MediaQuery.paddingOf(context).top;
    final bool completed = detail.comic.completion_status == 'completed';
    final String title =
        detail.selected_language?.title.trim().isNotEmpty == true
        ? detail.selected_language!.title.trim()
        : detail.comic.title.trim();

    final width = MediaQuery.sizeOf(context).width.clamp(0.0, 600.0);
    final scale = (width / ComicDetailStyle.design_width).clamp(0.8, 1.0);
    final viewport_width = MediaQuery.sizeOf(context).width;
    final centered_inset = math.max(0.0, (viewport_width - width) / 2);
    final text_scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final cover_width = math.min(
      ComicDetailStyle.cover_max_width,
      width *
          (chapter_mode
              ? ComicDetailStyle.chapter_cover_width_ratio
              : ComicDetailStyle.cover_width_ratio),
    );
    final cover_height =
        cover_width *
        (chapter_mode
            ? ComicDetailStyle.chapter_cover_aspect_ratio
            : ComicDetailStyle.cover_aspect_ratio);
    final hero_height =
        math.min(
          math.min(
            MediaQuery.sizeOf(context).height *
                ComicDetailStyle.hero_viewport_ratio,
            chapter_mode
                ? ComicDetailStyle.chapter_hero_max_height
                : ComicDetailStyle.hero_max_height,
          ),
          width *
              (chapter_mode
                  ? ComicDetailStyle.chapter_hero_height_ratio
                  : ComicDetailStyle.hero_height_ratio),
        ) +
        top_padding +
        (text_scale - 1).clamp(0, 2) * 170;
    final cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    return SliverToBoxAdapter(
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : ComicDetailStyle.transition_duration,
        curve: Curves.easeInOutCubic,
        height: hero_height,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            cover_image ?? ComicImage(url: cover_url, semantic_label: title),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: ComicDetailStyle.hero_scrim_colors,
                  stops: ComicDetailStyle.hero_scrim_stops,
                ),
              ),
            ),
            Positioned(
              top: top_padding + 8,
              left: 16,
              right: 12,
              child: WindowReservedRegionPadding(
                child: Row(
                  children: <Widget>[
                    _NavButton(
                      icon: Icons.chevron_left_rounded,
                      label: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
                      is_dark: is_dark,
                      on_pressed: on_back,
                    ),
                    const Spacer(),
                    _NavButton(
                      icon: Icons.share_outlined,
                      label: easy.tr('comics.share'),
                      is_dark: is_dark,
                      on_pressed: on_share,
                    ),
                    if (chapter_mode)
                      _NavButton(
                        icon: (collected ?? detail.is_collected)
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        label: easy.tr(
                          (collected ?? detail.is_collected)
                              ? 'comics.collected'
                              : 'comics.collect',
                        ),
                        is_dark: is_dark,
                        on_pressed: collecting ? () {} : on_collect,
                        icon_color: ColorConstants.dangerColor,
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: centered_inset + width * ComicDetailStyle.hero_inset_ratio,
              right: centered_inset + width * ComicDetailStyle.hero_inset_ratio,
              bottom: ComicDetailStyle.hero_bottom_inset,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  SizedBox(
                    width: cover_width,
                    height: cover_height,
                    child: _CoverCard(
                      cover_url: cover_url,
                      title: title,
                      completed: completed,
                      cover_image: cover_image,
                    ),
                  ),
                  SizedBox(width: 14 * scale),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        WindowReservedRegionPadding(
                          child: Text(
                            _display_title(title, cjk),
                            semanticsLabel: title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: cjk ? null : 'Georgia',
                              fontFamilyFallback: const [
                                'Times New Roman',
                                'serif',
                              ],
                              fontSize: (cjk ? 23 : 25.5) * scale,
                              height: 1.03,
                              fontWeight: ComicDetailStyle.weight_semi_bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          detail.comic.author_name.trim().isEmpty
                              ? easy.tr('comics.unknown_author')
                              : detail.comic.author_name.trim(),
                          key: const ValueKey('comic_hero_author'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize:
                                ComicDetailStyle.author_name_font_size * scale,
                            fontWeight: ComicDetailStyle.weight_medium,
                          ),
                        ),
                        const SizedBox(height: 9),
                        _StatsRow(detail: detail),
                        if (!chapter_mode) ...[
                          const SizedBox(height: 9),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _ReadButton(
                                  on_pressed: on_read,
                                  can_read: can_read,
                                  continuing: continuing,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _SaveButton(
                                collected: collected ?? detail.is_collected,
                                busy: collecting,
                                on_pressed: on_collect,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// TODO 短拉丁标题使用两行编辑式排版，优先让首行更短；长标题交给自然换行。
  String _display_title(String title, bool cjk) {
    final words = title.split(RegExp(r'\s+'));
    if (cjk || words.length < 4 || words.length > 7 || title.length > 40) {
      return title;
    }
    final split = words.length ~/ 2;
    return '${words.take(split).join(' ')}\n${words.skip(split).join(' ')}';
  }
}

/// 顶部导航圆形按钮。
class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool is_dark;
  final Color icon_color;
  final VoidCallback on_pressed;
  const _NavButton({
    required this.icon,
    required this.label,
    required this.is_dark,
    required this.on_pressed,
    this.icon_color = Colors.white,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: GestureDetector(
      onTap: on_pressed,
      child: Container(
        width: ComicDetailStyle.nav_button_size,
        height: ComicDetailStyle.nav_button_size,
        padding: const EdgeInsets.all(5),
        child: Container(
          decoration: BoxDecoration(
            color: ComicDetailStyle.nav_button_background(is_dark),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: ComicDetailStyle.nav_button_icon_size,
            color: icon_color,
          ),
        ),
      ),
    ),
  );
}

/// 封面卡片 + 「Completed」角标。
class _CoverCard extends StatelessWidget {
  final String cover_url;
  final String title;
  final bool completed;
  final Widget? cover_image;
  const _CoverCard({
    required this.cover_url,
    required this.title,
    required this.completed,
    this.cover_image,
  });

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(ComicDetailStyle.cover_card_radius),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.9),
        width: 1.2,
      ),
      boxShadow: ComicDetailStyle.cover_card_shadows,
    ),
    child: Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(
            ComicDetailStyle.cover_card_radius,
          ),
          child:
              cover_image ?? ComicImage(url: cover_url, semantic_label: title),
        ),
        if (completed)
          Positioned(
            top: ComicDetailStyle.badge_margin,
            left: ComicDetailStyle.badge_margin,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ComicDetailStyle.badge_padding_h,
                vertical: ComicDetailStyle.badge_padding_v,
              ),
              decoration: BoxDecoration(
                color: ComicDetailStyle.accent(context),
                borderRadius: BorderRadius.circular(
                  ComicDetailStyle.badge_radius,
                ),
              ),
              child: Text(
                easy.tr('comics.completed'),
                style: TextStyle(
                  fontSize: ComicDetailStyle.badge_font_size,
                  fontWeight: ComicDetailStyle.weight_medium,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// 统计行：评分 / 浏览 / 收藏。
class _StatsRow extends StatelessWidget {
  final ComicDetail detail;
  const _StatsRow({required this.detail});

  @override
  Widget build(BuildContext context) {
    final String rating_text = detail.comic.rating > 0
        ? detail.comic.rating.toStringAsFixed(1)
        : '—';
    final String rating_count = ComicDetailStyle.format_count(
      detail.comic.rating_count,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: _StatItem(
            icon: Icons.star_rounded,
            icon_color: const Color(0xFFFFD431),
            value: rating_text,
            label: '$rating_count ${easy.tr('comics.ratings')}',
          ),
        ),
        _stat_divider(),
        Expanded(
          child: _StatItem(
            icon: Icons.local_fire_department_rounded,
            icon_color: const Color(0xFFFFD431),
            value: ComicDetailStyle.format_count(detail.comic.view_count),
            label: easy.tr('comics.views'),
          ),
        ),
        _stat_divider(),
        Expanded(
          child: _StatItem(
            icon: Icons.favorite_rounded,
            icon_color: ColorConstants.dangerColor,
            value: ComicDetailStyle.format_count(detail.comic.favorite_count),
            label: easy.tr('comics.favorites'),
          ),
        ),
      ],
    );
  }

  Widget _stat_divider() => Container(
    width: 0.5,
    height: 18,
    margin: const EdgeInsets.fromLTRB(5, 6, 5, 0),
    color: Colors.white.withValues(alpha: 0.28),
  );
}

/// 单个统计项：图标 + 数值 + 标签。
class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color icon_color;
  final String value;
  final String label;
  const _StatItem({
    required this.icon,
    required this.icon_color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          children: <Widget>[
            Icon(
              icon,
              size: ComicDetailStyle.stats_icon_size,
              color: icon_color,
            ),
            const SizedBox(width: 3),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: ComicDetailStyle.stats_value_font_size,
                fontWeight: ComicDetailStyle.weight_medium,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: ComicDetailStyle.hero_muted,
          fontSize: ComicDetailStyle.stats_label_font_size,
        ),
      ),
    ],
  );
}

/// 「Start reading」主 CTA。
class _ReadButton extends StatelessWidget {
  final VoidCallback on_pressed;
  final bool can_read;
  final bool continuing;
  const _ReadButton({
    required this.on_pressed,
    required this.can_read,
    required this.continuing,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: can_read ? on_pressed : null,
    child: Container(
      height: ComicDetailStyle.cta_height,
      padding: ComicDetailStyle.cta_padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF38B), Color(0xFFFFDC20), Color(0xFFFFBA23)],
        ),
        border: Border.all(color: const Color(0xFFFFF7B0), width: 1),
        boxShadow: const [
          BoxShadow(color: Color(0x66FFD021), blurRadius: 18, spreadRadius: 1),
        ],
        borderRadius: BorderRadius.circular(ComicDetailStyle.cta_radius),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.menu_book_rounded,
            size: ComicDetailStyle.cta_icon_size,
            color: Color(0xFF1A1A2E),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              easy.tr(
                !can_read
                    ? 'comics.unavailable'
                    : continuing
                    ? 'comics.continue_reading'
                    : 'comics.start_reading',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: ComicDetailStyle.cta_font_size,
                fontWeight: ComicDetailStyle.weight_semi_bold,
              ),
            ),
          ),
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0x997E5900),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );
}

/// 「Save」次级 CTA。
class _SaveButton extends StatelessWidget {
  final bool collected;
  final VoidCallback on_pressed;
  final bool busy;
  const _SaveButton({
    required this.collected,
    required this.on_pressed,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    toggled: collected,
    label: easy.tr(collected ? 'comics.collected' : 'comics.collect'),
    child: IconButton(
      key: const ValueKey('comic_save_button'),
      tooltip: easy.tr(collected ? 'comics.collected' : 'comics.collect'),
      onPressed: busy ? null : on_pressed,
      style: IconButton.styleFrom(
        minimumSize: const Size.square(ComicDetailStyle.cta_height),
        backgroundColor: Colors.black.withValues(alpha: 0.3),
        foregroundColor: Colors.white,
      ),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: Icon(
          collected ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          key: ValueKey(collected),
          size: ComicDetailStyle.save_icon_size,
          color: ColorConstants.dangerColor,
        ),
      ),
    ),
  );
}
