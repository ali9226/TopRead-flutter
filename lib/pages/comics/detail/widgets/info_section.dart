// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart';
import 'package:app/config/color_config.dart';
import 'package:flutter/material.dart';

import 'package:app/models/comics.dart';
import 'package:app/pages/comics/detail/style.dart';
import 'package:app/pages/comics/style.dart';

/// 作品信息区：标题、作者、数据胶囊、分类标签。
///
/// 所有文字按 CJK/拉丁语系切换字阶；分类标签沿用漫画卡片的彩色胶囊语言。
class ComicDetailInfoSection extends StatelessWidget {
  /// 作品详情数据。
  final ComicDetail detail;

  /// 当前是否为夜间模式。
  final bool is_dark;

  /// 当前界面是否为 CJK 语种。
  final bool is_cjk;

  const ComicDetailInfoSection({
    super.key,
    required this.detail,
    required this.is_dark,
    required this.is_cjk,
  });

  @override
  Widget build(BuildContext context) {
    final String display_title =
        detail.selected_language?.title.isNotEmpty == true
        ? detail.selected_language!.title
        : detail.comic.title;
    final bool show_original_title =
        display_title != detail.comic.title &&
        detail.comic.title.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// 主标题。
        Text(
          display_title,
          maxLines: ComicDetailStyle.title_max_lines,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: ComicsStyle.ink(context),
            fontSize: ComicDetailStyle.pick_font_size(
              is_cjk: is_cjk,
              cjk: ComicDetailStyle.title_font_size_cjk,
              alphabetic: ComicDetailStyle.title_font_size_alphabetic,
            ),
            height: ComicDetailStyle.pick_font_size(
              is_cjk: is_cjk,
              cjk: ComicDetailStyle.title_height_cjk,
              alphabetic: ComicDetailStyle.title_height_alphabetic,
            ),
            fontWeight: ComicDetailStyle.weight_medium,
            letterSpacing: is_cjk ? null : 0.2,
          ),
        ),

        /// 原标题（语种标题不同时展示）。
        if (show_original_title)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              detail.comic.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ComicsStyle.muted(context),
                fontSize: ComicDetailStyle.original_title_font_size,
                fontWeight: ComicDetailStyle.weight_regular,
              ),
            ),
          ),

        /// 作者行。
        Padding(
          padding: const EdgeInsets.only(
            top: ComicDetailStyle.author_top_spacing,
          ),
          child: Row(
            children: <Widget>[
              /// 作者头像占位：无远程头像时用主题色圆点。
              if (detail.comic.author_name.isNotEmpty)
                Container(
                  width: ComicDetailStyle.author_avatar_size,
                  height: ComicDetailStyle.author_avatar_size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ComicsStyle.outline(context)),
                  ),
                  child: Icon(
                    Icons.person_outline_rounded,
                    size: ComicDetailStyle.author_avatar_size * 0.62,
                    color: ComicsStyle.muted(context),
                  ),
                ),
              if (detail.comic.author_name.isNotEmpty)
                const SizedBox(width: ComicDetailStyle.author_avatar_gap),
              Expanded(
                child: Text(
                  detail.comic.author_name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ComicsStyle.muted(context),
                    fontSize: ComicDetailStyle.author_font_size,
                    fontWeight: ComicDetailStyle.weight_regular,
                  ),
                ),
              ),
            ],
          ),
        ),

        /// 数据胶囊：章节、语种、状态。
        Padding(
          padding: const EdgeInsets.only(
            top: ComicDetailStyle.stats_top_spacing,
          ),
          child: Wrap(
            spacing: ComicDetailStyle.stats_spacing,
            runSpacing: ComicDetailStyle.stats_spacing,
            children: <Widget>[
              _StatsPill(
                icon: Icons.menu_book_rounded,
                label: tr(
                  'comics.chapter_count',
                  namedArgs: <String, String>{
                    'count': '${detail.chapters.length}',
                  },
                ),
                is_dark: is_dark,
              ),
              _StatsPill(
                icon: Icons.translate_rounded,
                label: tr(
                  'comics.language_count',
                  namedArgs: <String, String>{
                    'count': '${detail.languages.length}',
                  },
                ),
                is_dark: is_dark,
              ),
              _StatsPill(
                icon: detail.comic.completion_status == 'completed'
                    ? Icons.check_circle_outline_rounded
                    : Icons.schedule_rounded,
                label: tr(
                  detail.comic.completion_status == 'completed'
                      ? 'comics.completed'
                      : 'comics.ongoing',
                ),
                is_dark: is_dark,
              ),
            ],
          ),
        ),

        /// 分类标签。
        if (detail.comic.categories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(
              top: ComicDetailStyle.tags_top_spacing,
            ),
            child: Wrap(
              spacing: ComicDetailStyle.tag_spacing,
              runSpacing: ComicDetailStyle.tag_run_spacing,
              children: <Widget>[
                for (int index = 0; index < detail.comic.categories.length; index++)
                  _CategoryPill(
                    label: ComicsStyle.category_name(
                      context,
                      detail.comic.categories[index],
                    ),
                    is_cjk: is_cjk,
                    is_dark: is_dark,
                    color_index: index,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 数据统计胶囊。
class _StatsPill extends StatelessWidget {
  /// 左侧图标。
  final IconData icon;

  /// 文案。
  final String label;

  /// 当前是否为夜间模式。
  final bool is_dark;

  const _StatsPill({
    required this.icon,
    required this.label,
    required this.is_dark,
  });

  @override
  Widget build(BuildContext context) {
    final Color background = is_dark
        ? Colors.white.withValues(alpha: ComicDetailStyle.stats_bg_dark_opacity)
        : const Color(0xFF161C28).withValues(
            alpha: ComicDetailStyle.stats_bg_light_opacity,
          );
    final Color foreground = is_dark
        ? Colors.white.withValues(alpha: 0.86)
        : const Color(0xFF3A4150);

    return Container(
      padding: ComicDetailStyle.stats_padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(ComicDetailStyle.stats_radius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                color: foreground,
                fontSize: ComicDetailStyle.stats_font_size,
                fontWeight: ComicDetailStyle.weight_regular,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 分类标签胶囊：多彩标签，颜色按序号取自 tagColorList。
class _CategoryPill extends StatelessWidget {
  /// 标签文案。
  final String label;

  /// 当前界面是否为 CJK 语种。
  final bool is_cjk;

  /// 当前是否为夜间模式。
  final bool is_dark;

  /// 标签序号，决定取色。
  final int color_index;

  const _CategoryPill({
    required this.label,
    required this.is_cjk,
    required this.is_dark,
    required this.color_index,
  });

  @override
  Widget build(BuildContext context) {
    // 与漫画卡片同款多彩标签：按标签序号取 tagColorList 颜色。
    final Color accent = ColorConstants.resolveTagColor(color_index);
    final Color background = accent.withValues(alpha: 0.12);

    return Container(
      padding: ComicDetailStyle.tag_padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(ComicDetailStyle.tag_radius),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontSize: ComicDetailStyle.pick_font_size(
            is_cjk: is_cjk,
            cjk: ComicDetailStyle.tag_font_size_cjk,
            alphabetic: ComicDetailStyle.tag_font_size_alphabetic,
          ),
          fontWeight: ComicDetailStyle.weight_regular,
        ),
      ),
    );
  }
}
