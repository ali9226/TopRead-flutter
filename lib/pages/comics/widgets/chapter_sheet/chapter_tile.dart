// ignore_for_file: non_constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/detail/style.dart';
import 'package:app/pages/comics/widgets/chapter_sheet/style.dart';
import 'package:app/pages/comics/widgets/chapter_sheet/chapter_preview.dart';
import 'package:app/pages/comics/widgets/comic_surface.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 目录仅展示章节首图、标题和明确的页数，箭头固定在卡片最右侧。
class ComicDetailChapterTile extends StatelessWidget {
  const ComicDetailChapterTile({
    super.key,
    required this.number,
    required this.chapter,
    required this.is_dark,
    this.selected = false,
    required this.on_open,
  });

  /// 原始章节序号供排序与调用方识别，不作为无说明的数字展示。
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
    final metadata = tr(
      'comics.image_count',
      namedArgs: {'count': '${chapter.page_count}'},
    );
    final ink = selected
        ? ColorConstants.dangerColor
        : ComicDetailStyle.ink(context);
    return ComicSurface(
      is_dark: is_dark,
      selected: selected,
      child: InkWell(
        onTap: on_open,
        splashColor: ColorConstants.themeColor.withValues(alpha: 0.12),
        highlightColor: ColorConstants.themeColor.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.all(ComicChapterCatalogStyle.card_padding),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact =
                  constraints.maxWidth <
                      ComicChapterCatalogStyle.preview_compact_content_width ||
                  MediaQuery.textScalerOf(context).scale(1) >
                      ComicChapterCatalogStyle.compact_scale;
              return Row(
                children: [
                  ComicChapterPreview(
                    chapter: chapter,
                    selected: selected,
                    compact: compact,
                    cjk: cjk,
                  ),
                  const SizedBox(width: ComicChapterCatalogStyle.content_gap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          chapter.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: cjk
                                ? ComicChapterCatalogStyle.title_size_cjk
                                : ComicChapterCatalogStyle
                                      .title_size_alphabetic,
                            height: ComicChapterCatalogStyle.title_height,
                            fontWeight: ComicDetailStyle.weight_medium,
                            color: ink,
                          ),
                        ),
                        const SizedBox(
                          height: ComicChapterCatalogStyle.metadata_gap,
                        ),
                        Text(
                          metadata,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: cjk
                                ? ComicChapterCatalogStyle.metadata_size_cjk
                                : ComicChapterCatalogStyle
                                      .metadata_size_alphabetic,
                            height: ComicChapterCatalogStyle.metadata_height,
                            color: ComicDetailStyle.muted(context),
                            fontWeight: ComicDetailStyle.weight_regular,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: ComicChapterCatalogStyle.toolbar_gap),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: ComicChapterCatalogStyle.arrow_size,
                    color: ComicDetailStyle.muted(context),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
