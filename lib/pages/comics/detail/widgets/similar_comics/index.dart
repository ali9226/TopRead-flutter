// ignore_for_file: non_constant_identifier_names

import 'package:app/models/comics.dart';
import 'package:app/pages/comics/detail/style.dart';
import 'package:app/pages/comics/widgets/comic_image.dart';
import 'package:app/pages/comics/detail/widgets/similar_comics/style.dart';
import 'package:app/util/language_util/index.dart';
import 'package:flutter/material.dart';

/// TODO 推荐漫画按实际字体自然撑高，不估算两行标题的像素高度，支持字体缩放与多语种。
class ComicSimilarComicsRow extends StatelessWidget {
  const ComicSimilarComicsRow({super.key, required this.comics, this.on_tap});

  /// TODO 已加载推荐，数量由推荐接口控制，横向内容不抢占详情页的纵向滚动。
  final List<ComicItem> comics;
  final ValueChanged<int>? on_tap;

  @override
  Widget build(BuildContext context) {
    final cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (var index = 0; index < comics.length; index++) ...<Widget>[
            if (index > 0)
              const SizedBox(width: ComicDetailStyle.similar_spacing),
            SizedBox(
              width: ComicSimilarComicsStyle.card_width,
              child: InkWell(
                borderRadius: BorderRadius.circular(
                  ComicDetailStyle.similar_cover_radius,
                ),
                onTap: on_tap == null ? null : () => on_tap!(comics[index].id),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        ComicDetailStyle.similar_cover_radius,
                      ),
                      child: SizedBox(
                        width: ComicSimilarComicsStyle.card_width,
                        height: ComicSimilarComicsStyle.cover_height,
                        child: ComicImage(
                          url: comics[index].cover_url,
                          semantic_label: comics[index].title,
                        ),
                      ),
                    ),
                    const SizedBox(height: ComicDetailStyle.similar_title_gap),
                    Text(
                      comics[index].title,
                      maxLines: ComicSimilarComicsStyle.title_lines,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: cjk
                            ? ComicSimilarComicsStyle.font_size_cjk
                            : ComicSimilarComicsStyle.font_size_alphabetic,
                        height: cjk
                            ? ComicSimilarComicsStyle.line_height_cjk
                            : ComicSimilarComicsStyle.line_height_alphabetic,
                        fontWeight: ComicDetailStyle.weight_regular,
                        color: ComicDetailStyle.ink(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
