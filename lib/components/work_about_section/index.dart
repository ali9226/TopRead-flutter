import 'package:app/components/expandable_synopsis/index.dart';
import 'package:app/components/work_genres_section/index.dart';
import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';

import 'style.dart';

export 'style.dart';

/// 简介与分类共用一个连续的正文区域，不叠加独立卡片、阴影或表面色。
class WorkAboutSection extends StatelessWidget {
  const WorkAboutSection({
    super.key,
    required this.description,
    required this.tags,
    required this.is_dark,
    this.title,
    this.surface_color,
    this.key_prefix = 'work_about',
    this.show_empty_description = true,
    this.collapsed_lines = 4,
    this.compact_toggle = false,
  });

  final String description;
  final List<String> tags;
  final bool is_dark;
  final String? title;
  final Color? surface_color;
  final String key_prefix;

  /// 短篇缺少简介时直接展示可用分类，不生成没有内容的占位区。
  final bool show_empty_description;
  final int collapsed_lines;
  final bool compact_toggle;

  @override
  Widget build(BuildContext context) {
    final has_description =
        show_empty_description || description.trim().isNotEmpty;
    final visible_tags = tags.where((tag) => tag.trim().isNotEmpty).toList();
    if (!has_description && visible_tags.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      key: ValueKey('${key_prefix}_content'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (has_description)
          ExpandableSynopsis(
            description: description,
            title: title ?? easy.tr('read.intro_title'),
            empty_description: easy.tr('comics.no_description'),
            expand_label: easy.tr('comics.show_more'),
            collapse_label: easy.tr('comics.show_less'),
            is_dark: is_dark,
            key_prefix: key_prefix,
            embedded: true,
            surface_color: surface_color,
            collapsed_lines: collapsed_lines,
            compact_toggle: compact_toggle,
          ),
        if (has_description && visible_tags.isNotEmpty) ...[
          const SizedBox(height: WorkAboutSectionStyle.divider_gap),
          Divider(
            height: WorkAboutSectionStyle.divider_width,
            thickness: WorkAboutSectionStyle.divider_width,
            color: WorkAboutSectionStyle.divider(is_dark),
          ),
          const SizedBox(height: WorkAboutSectionStyle.divider_gap),
        ],
        if (visible_tags.isNotEmpty)
          WorkGenresSection(
            title: easy.tr('comics.genres'),
            tags: visible_tags,
            is_dark: is_dark,
            embedded: true,
          ),
      ],
    );
  }
}
