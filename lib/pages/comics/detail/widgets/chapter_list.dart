// ignore_for_file: non_constant_identifier_names

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:app/models/comics.dart';
import 'package:app/pages/comics/detail/style.dart';
import 'package:app/pages/comics/style.dart';

/// 章节目录：编号 + 标题 + 页数，轻触进入阅读。
class ComicDetailChapterList extends StatelessWidget {
  /// 章节列表。
  final List<ComicChapter> chapters;

  /// 当前是否为夜间模式。
  final bool is_dark;

  /// 点击章节回调，参数为章节 id。
  final ValueChanged<int> on_open;

  const ComicDetailChapterList({
    super.key,
    required this.chapters,
    required this.is_dark,
    required this.on_open,
  });

  @override
  Widget build(BuildContext context) {
    if (chapters.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            tr('comics.empty_chapters'),
            style: TextStyle(
              color: ComicsStyle.muted(context),
              fontSize: ComicDetailStyle.chapter_meta_font_size,
            ),
          ),
        ),
      );
    }

    return Column(
      children: <Widget>[
        for (int index = 0; index < chapters.length; index++) ...<Widget>[
          if (index > 0)
            const SizedBox(height: ComicDetailStyle.chapter_spacing),
          _ChapterTile(
            number: index + 1,
            chapter: chapters[index],
            is_dark: is_dark,
            onTap: () => on_open(chapters[index].id),
          ),
        ],
      ],
    );
  }
}

/// 单个章节条目。
class _ChapterTile extends StatelessWidget {
  /// 章节序号（从 1 开始）。
  final int number;

  /// 章节数据。
  final ComicChapter chapter;

  /// 当前是否为夜间模式。
  final bool is_dark;

  /// 点击回调。
  final VoidCallback onTap;

  const _ChapterTile({
    required this.number,
    required this.chapter,
    required this.is_dark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color background = is_dark
        ? ComicDetailStyle.surface_dark
        : ComicDetailStyle.surface_light;
    final Color number_color = is_dark
        ? Colors.white.withValues(alpha: 0.36)
        : const Color(0xFF9AA3B2);

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(ComicDetailStyle.chapter_radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(ComicDetailStyle.chapter_radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ComicDetailStyle.chapter_padding_h,
            vertical: ComicDetailStyle.chapter_padding_v,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              /// 章节序号。
              SizedBox(
                width: ComicDetailStyle.chapter_number_width,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    number.toString().padLeft(2, '0'),
                    style: TextStyle(
                      color: number_color,
                      fontSize: ComicDetailStyle.chapter_number_font_size,
                      fontWeight: ComicDetailStyle.weight_medium,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ),
              ),

              /// 标题 + 页数。
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      chapter.title,
                      maxLines: ComicDetailStyle.chapter_title_max_lines,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ComicsStyle.ink(context),
                        fontSize: ComicDetailStyle.chapter_title_font_size,
                        height: 1.4,
                        fontWeight: ComicDetailStyle.weight_medium,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: ComicDetailStyle.chapter_meta_top_spacing,
                      ),
                      child: Text(
                        tr(
                          'comics.page_count',
                          namedArgs: <String, String>{
                            'count': '${chapter.page_count}',
                          },
                        ),
                        style: TextStyle(
                          color: ComicsStyle.muted(context),
                          fontSize: ComicDetailStyle.chapter_meta_font_size,
                          fontWeight: ComicDetailStyle.weight_regular,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              /// 右侧箭头。
              Icon(
                Icons.chevron_right_rounded,
                color: number_color,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
