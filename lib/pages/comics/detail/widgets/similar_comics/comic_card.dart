// ignore_for_file: non_constant_identifier_names

import 'package:app/pages/comics/widgets/comic_surface.dart';
import 'package:app/pages/comics/widgets/comic_surface_style.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/detail/style.dart';
import 'package:app/pages/comics/detail/widgets/similar_comics/style.dart';
import 'package:app/pages/comics/widgets/comic_image.dart';
import 'package:app/util/language_util/index.dart';
import 'package:flutter/material.dart';

/// 每部推荐作品独立成卡，封面、标题与作者一起响应点击。
class ComicSimilarComicCard extends StatelessWidget {
  const ComicSimilarComicCard({super.key, required this.comic, this.on_open});
  final ComicItem comic;
  final VoidCallback? on_open;

  @override
  Widget build(BuildContext context) {
    final cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    final radius = BorderRadius.circular(ComicSurfaceStyle.card_radius);
    final scaler = MediaQuery.textScalerOf(context);
    return SizedBox(
      width: ComicSimilarComicsStyle.card_width,
      height: ComicSimilarComicsStyle.card_height(scaler, cjk),
      child: ComicSurface(
        key: ValueKey('comic_similar_card_${comic.id}'),
        is_dark: ComicDetailStyle.is_dark(context),
        child: InkWell(
          borderRadius: radius,
          onTap: on_open,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(ComicSurfaceStyle.card_radius),
                ),
                child: SizedBox(
                  width: ComicSimilarComicsStyle.card_width,
                  height: ComicSimilarComicsStyle.cover_height,
                  child: ComicImage(
                    url: comic.cover_url,
                    semantic_label: comic.title,
                    cache_width:
                        (ComicSimilarComicsStyle.card_width *
                                MediaQuery.devicePixelRatioOf(context))
                            .ceil(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(
                  ComicSimilarComicsStyle.card_padding,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: ComicSimilarComicsStyle.title_height(scaler, cjk),
                      child: Text(
                        comic.title,
                        maxLines: ComicSimilarComicsStyle.title_lines,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: cjk
                              ? ComicSimilarComicsStyle.font_size_cjk
                              : ComicSimilarComicsStyle.font_size_alphabetic,
                          height: cjk
                              ? ComicSimilarComicsStyle.line_height_cjk
                              : ComicSimilarComicsStyle.line_height_alphabetic,
                          fontWeight: ComicDetailStyle.weight_medium,
                          color: ComicDetailStyle.ink(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: ComicSimilarComicsStyle.author_gap),
                    SizedBox(
                      height: ComicSimilarComicsStyle.author_height(
                        scaler,
                        cjk,
                      ),
                      child: Text(
                        comic.author_name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: cjk
                              ? ComicSimilarComicsStyle.author_size_cjk
                              : ComicSimilarComicsStyle.author_size_alphabetic,
                          height: cjk
                              ? ComicSimilarComicsStyle.line_height_cjk
                              : ComicSimilarComicsStyle.line_height_alphabetic,
                          fontWeight: ComicDetailStyle.weight_regular,
                          color: ComicDetailStyle.muted(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
