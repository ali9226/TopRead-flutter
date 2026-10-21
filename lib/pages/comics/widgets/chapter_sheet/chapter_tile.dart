// ignore_for_file: non_constant_identifier_names

import 'package:app/components/catalog_card/index.dart';
import 'package:app/config/color_config.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/detail/style.dart';
import 'package:app/pages/comics/widgets/chapter_sheet/style.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// TODO 与短篇目录共用独立卡片表面、标题与次级信息层级；当前章节沿用dangerColor高亮。
class ComicDetailChapterTile extends StatelessWidget {
  const ComicDetailChapterTile({
    super.key,
    required this.number,
    required this.chapter,
    required this.is_dark,
    this.selected = false,
    required this.on_open,
  });
  final int number;
  final ComicChapter chapter;
  final bool is_dark;
  final bool selected;
  final VoidCallback on_open;

  @override
  Widget build(BuildContext context) {
    final cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    final date = DateTime.tryParse(chapter.update_time);
    final metadata = [
      if (date != null) DateFormat('yyyy-MM-dd').format(date),
      tr('comics.image_count', namedArgs: {'count': '${chapter.page_count}'}),
    ].join('  ·  ');
    final ink = selected
        ? ColorConstants.dangerColor
        : ComicDetailStyle.ink(context);
    return CatalogCardSurface(
      is_dark: is_dark,
      selected: selected,
      child: InkWell(
        onTap: on_open,
        splashColor: ColorConstants.themeColor.withValues(alpha: 0.12),
        highlightColor: ColorConstants.themeColor.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.all(ComicChapterCatalogStyle.card_padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      chapter.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: cjk
                            ? ComicChapterCatalogStyle.title_size_cjk
                            : ComicChapterCatalogStyle.title_size_alphabetic,
                        height: ComicChapterCatalogStyle.title_height,
                        fontWeight: ComicDetailStyle.weight_medium,
                        color: ink,
                      ),
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: ComicChapterCatalogStyle.toolbar_gap),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 88),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: ColorConstants.dangerColor.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(
                          ComicChapterCatalogStyle.continue_radius,
                        ),
                      ),
                      child: Text(
                        tr('short_story_read.reading'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: ComicChapterCatalogStyle.sort_size_cjk,
                          fontWeight: ComicDetailStyle.weight_regular,
                          color: ColorConstants.dangerColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: ComicChapterCatalogStyle.metadata_gap),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      metadata,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: cjk
                            ? ComicChapterCatalogStyle.metadata_size_cjk
                            : ComicChapterCatalogStyle.metadata_size_alphabetic,
                        height: ComicChapterCatalogStyle.metadata_height,
                        color: ComicDetailStyle.muted(context),
                        fontWeight: ComicDetailStyle.weight_regular,
                      ),
                    ),
                  ),
                  const SizedBox(width: ComicChapterCatalogStyle.toolbar_gap),
                  Text(
                    '$number',
                    style: TextStyle(
                      fontSize: ComicChapterCatalogStyle.number_size,
                      height: ComicChapterCatalogStyle.metadata_height,
                      color: ComicDetailStyle.muted(context),
                      fontWeight: ComicDetailStyle.weight_regular,
                    ),
                  ),
                  const SizedBox(width: ComicChapterCatalogStyle.toolbar_gap),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: ComicChapterCatalogStyle.arrow_size,
                    color: ComicDetailStyle.muted(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
