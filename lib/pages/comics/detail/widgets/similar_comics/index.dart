// ignore_for_file: non_constant_identifier_names

import 'package:app/models/comics.dart';
import 'package:app/pages/comics/detail/widgets/similar_comics/comic_card.dart';
import 'package:app/pages/comics/detail/widgets/similar_comics/style.dart';
import 'package:app/util/language_util/index.dart';
import 'package:flutter/material.dart';

/// 整行不包卡片。边距随内容滚动，作品可以从窗口边缘滑出。
class ComicSimilarComicsRow extends StatelessWidget {
  const ComicSimilarComicsRow({
    super.key,
    required this.comics,
    this.on_tap,
    this.horizontal_padding = 0,
  });

  final List<ComicItem> comics;
  final ValueChanged<int>? on_tap;
  final double horizontal_padding;

  @override
  Widget build(BuildContext context) {
    final cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    return SizedBox(
      height:
          ComicSimilarComicsStyle.card_height(
            MediaQuery.textScalerOf(context),
            cjk,
          ) +
          ComicSimilarComicsStyle.shadow_padding * 2,
      child: ListView.separated(
        key: const ValueKey('comic_similar_scroll'),
        scrollDirection: Axis.horizontal,
        primary: false,
        padding: EdgeInsets.symmetric(
          horizontal: horizontal_padding,
          vertical: ComicSimilarComicsStyle.shadow_padding,
        ),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        itemCount: comics.length,
        separatorBuilder: (_, _) =>
            const SizedBox(width: ComicSimilarComicsStyle.card_gap),
        itemBuilder: (context, index) => ComicSimilarComicCard(
          key: ValueKey(comics[index].id),
          comic: comics[index],
          on_open: on_tap == null ? null : () => on_tap!(comics[index].id),
        ),
      ),
    );
  }
}
