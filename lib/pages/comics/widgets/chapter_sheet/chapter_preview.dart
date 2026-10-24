// ignore_for_file: non_constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/detail/style.dart';
import 'package:app/pages/comics/widgets/chapter_sheet/style.dart';
import 'package:app/pages/comics/widgets/comic_image.dart';
import 'package:app/pages/comics/widgets/thumbnail_cache.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 小横幅预览共用漫画图片的缓存、占位和重试；续读角标不占用标题宽度。
class ComicChapterPreview extends StatelessWidget {
  const ComicChapterPreview({
    super.key,
    required this.chapter,
    required this.selected,
    required this.compact,
    required this.cjk,
  });

  final ComicChapter chapter;
  final bool selected;
  final bool compact;
  final bool cjk;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(
      ComicChapterCatalogStyle.preview_radius,
    ),
    child: SizedBox(
      width: compact
          ? ComicChapterCatalogStyle.preview_compact_width
          : ComicChapterCatalogStyle.preview_width,
      height: compact
          ? ComicChapterCatalogStyle.preview_compact_height
          : ComicChapterCatalogStyle.preview_height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ComicImage(
            key: ValueKey('comic_chapter_preview_${chapter.id}'),
            url: chapter.preview_image?.image_url ?? '',
            semantic_label: chapter.title,
            cache_width: comic_thumbnail_cache_width(
              width: compact
                  ? ComicChapterCatalogStyle.preview_compact_width
                  : ComicChapterCatalogStyle.preview_width,
              device_pixel_ratio: MediaQuery.devicePixelRatioOf(context),
              image: chapter.preview_image,
            ),
          ),
          if (selected)
            PositionedDirectional(
              start: ComicChapterCatalogStyle.preview_badge_inset,
              end: ComicChapterCatalogStyle.preview_badge_inset,
              bottom: ComicChapterCatalogStyle.preview_badge_inset,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color:
                      ComicDetailStyle.card_background(
                        ComicDetailStyle.is_dark(context),
                      ).withValues(
                        alpha: ComicChapterCatalogStyle.preview_badge_opacity,
                      ),
                  borderRadius: BorderRadius.circular(
                    ComicChapterCatalogStyle.continue_radius,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(
                    ComicChapterCatalogStyle.preview_badge_padding,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      tr('short_story_read.reading'),
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: cjk
                            ? ComicChapterCatalogStyle.sort_size_cjk
                            : ComicChapterCatalogStyle.sort_size_alphabetic,
                        fontWeight: ComicDetailStyle.weight_regular,
                        color: ColorConstants.dangerColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
