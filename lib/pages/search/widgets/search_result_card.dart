// ignore_for_file: non_constant_identifier_names

import 'package:app/components/content_category_tag/index.dart';
import 'package:app/components/recommend_book_card/book_list_item.dart';
import 'package:app/components/recommend_book_card/index.dart';
import 'package:app/models/recommend_ranking_item.dart';
import 'package:app/models/work_search.dart';
import 'package:app/pages/comics/widgets/comic_card.dart';
import 'package:app/pages/search/style.dart';
import 'package:app/util/novel_navigation/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 搜索复用两类作品原有卡片，类型标签与分类、完结角标分别展示。
class SearchResultCard extends StatelessWidget {
  const SearchResultCard({
    super.key,
    required this.item,
    required this.is_dark,
  });

  final SearchResultItem item;
  final bool is_dark;

  @override
  Widget build(BuildContext context) {
    final novel = item.novel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ContentCategoryTag(
          label: tr(item.is_comic ? 'search.type_comic' : 'search.type_novel'),
          color: item.is_comic
              ? Style.comic_type_color
              : Style.novel_type_color,
          is_dark: is_dark,
        ),
        const SizedBox(height: Style.result_type_gap),
        if (item.comic != null)
          ComicCard(comic: item.comic!)
        else
          RecommendBookCard(
            item: _novel_card(novel!),
            is_dark: is_dark,
            on_tap: () => navigate_to_novel(
              id: novel.id,
              title: novel.title,
              publish_status: novel.publish_status,
            ),
          ),
      ],
    );
  }

  /// 小说的封面、评分、分类和短篇状态保持原有搜索卡片行为。
  BookListItem _novel_card(RecommendRankingItem novel) => BookListItem(
    id: item.id,
    story_id: novel.id,
    type: BookListItemType.book,
    title: novel.title,
    description: novel.introduction,
    cover_url: novel.cover_url,
    cover_width: novel.cover_width,
    cover_height: novel.cover_height,
    cover_badge: novel.publish_status == 2 ? tr('search.completed') : '',
    cover_meta_text: novel.score > 0
        ? tr(
            'search.score',
            namedArgs: {
              'score': novel.score
                  .toStringAsFixed(2)
                  .replaceAll(RegExp(r'0+$'), '')
                  .replaceAll(RegExp(r'\.$'), ''),
            },
          )
        : '',
    tag_list: novel.category_list
        .take(Style.result_category_count)
        .toList()
        .asMap()
        .entries
        .map(
          (entry) => BookListTagItem(
            label: entry.value,
            color:
                Style.result_tag_colors[(novel.id + entry.key) %
                    Style.result_tag_colors.length],
          ),
        )
        .toList(),
    ad_image_url_list: const [],
    publish_status: novel.publish_status,
  );
}
