// ignore_for_file: non_constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/detail/style.dart';
import 'package:app/pages/comics/detail/widgets/chapter_preview/style.dart';
import 'package:app/pages/comics/widgets/comic_image.dart';
import 'package:app/pages/comics/widgets/comic_surface.dart';
import 'package:app/pages/comics/widgets/thumbnail_cache.dart';
import 'package:flutter/material.dart';

/// 每章只加载首图；目录的排序编号与实际阅读路由保持一致。
class ComicChapterPreviewCard extends StatelessWidget {
  const ComicChapterPreviewCard({
    super.key,
    required this.chapter,
    required this.number,
    required this.is_cjk,
    required this.selected,
    required this.on_open,
  });

  final ComicChapter chapter;
  final int number;
  final bool is_cjk;
  final bool selected;
  final VoidCallback on_open;

  @override
  Widget build(BuildContext context) {
    final line_height = is_cjk
        ? ComicChapterPreviewStyle.line_height_cjk
        : ComicChapterPreviewStyle.line_height_alphabetic;
    final title_size = is_cjk
        ? ComicChapterPreviewStyle.title_size_cjk
        : ComicChapterPreviewStyle.title_size_alphabetic;
    final title_height =
        MediaQuery.textScalerOf(context).scale(title_size) *
            line_height *
            ComicChapterPreviewStyle.title_lines +
        ComicChapterPreviewStyle.font_metric_allowance;
    final title = '$number · ${chapter.title}';
    final radius = BorderRadius.circular(ComicChapterPreviewStyle.radius);
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: ComicSurface(
        key: ValueKey('comic_chapter_surface_${chapter.id}'),
        is_dark: ComicDetailStyle.is_dark(context),
        selected: selected,
        radius: ComicChapterPreviewStyle.radius,
        child: InkWell(
          onTap: on_open,
          borderRadius: radius,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: ComicChapterPreviewStyle.image_ratio,
                child: LayoutBuilder(
                  builder: (context, constraints) => ComicImage(
                    url: chapter.preview_image?.image_url ?? '',
                    semantic_label: chapter.title,
                    cache_width: comic_thumbnail_cache_width(
                      width: constraints.maxWidth,
                      device_pixel_ratio: MediaQuery.devicePixelRatioOf(
                        context,
                      ),
                      image: chapter.preview_image,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ComicChapterPreviewStyle.title_padding_h,
                  vertical: ComicChapterPreviewStyle.title_padding_v,
                ),
                child: SizedBox(
                  height: title_height,
                  child: Text(
                    title,
                    maxLines: ComicChapterPreviewStyle.title_lines,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: title_size,
                      height: line_height,
                      color: selected
                          ? ColorConstants.dangerColor
                          : ComicDetailStyle.ink(context),
                      fontWeight: ComicDetailStyle.weight_medium,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
