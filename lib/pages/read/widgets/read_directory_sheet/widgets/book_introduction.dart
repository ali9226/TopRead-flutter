import 'package:app/components/window_content_layout/index.dart';
import 'package:app/pages/read/utils/read_models.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'book_introduction/genre_tags.dart';
import 'book_introduction/logic.dart';
import 'book_introduction/style.dart';

/// TODO 目录详情使用连续纸面，分类和简介单独排版，作品统计只保留在 Hero。
class BookIntroduction extends StatelessWidget {
  const BookIntroduction({
    super.key,
    required this.detail,
    required this.is_dark,
  });

  final ReadDetail detail;
  final bool is_dark;

  @override
  Widget build(BuildContext context) {
    final cjk = LanguageUtil.is_cjk_language(context.locale.languageCode);
    final content = DirectoryBookIntroductionContent.from(
      tags: detail.tag_list,
      description: detail.intro_text,
    );
    return LayoutBuilder(
      builder: (context, constraints) => CustomScrollView(
        key: const PageStorageKey('directory_details_scroll'),
        slivers: [
          SliverPadding(
            padding: DirectoryBookIntroductionStyle.content_padding(
              constraints.maxWidth,
            ),
            sliver: SliverList.list(
              children: [
                if (content.tags.isNotEmpty) ...[
                  WindowReservedRegionPadding(
                    mode: WindowReservedRegionPaddingMode.heading,
                    retain_when_above_viewport: true,
                    child: DirectoryBookGenreTags(
                      tags: content.tags,
                      is_dark: is_dark,
                      is_cjk: cjk,
                    ),
                  ),
                  const SizedBox(
                    height: DirectoryBookIntroductionStyle.genres_bottom_gap,
                  ),
                  Divider(
                    height: DirectoryBookIntroductionStyle.divider_height,
                    thickness: DirectoryBookIntroductionStyle.divider_height,
                    color: DirectoryBookIntroductionStyle.divider(is_dark),
                  ),
                  const SizedBox(
                    height: DirectoryBookIntroductionStyle.section_gap,
                  ),
                ],
                WindowReservedRegionPadding(
                  mode: WindowReservedRegionPaddingMode.heading,
                  retain_when_above_viewport: true,
                  child: Semantics(
                    header: true,
                    child: Text(
                      tr('read.intro_title'),
                      key: const ValueKey('directory_details_about_heading'),
                      style: DirectoryBookIntroductionStyle.heading(
                        dark: is_dark,
                        cjk: cjk,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: DirectoryBookIntroductionStyle.heading_body_gap,
                ),
                if (content.paragraphs.isEmpty)
                  _paragraph(
                    tr('comics.no_description'),
                    index: 0,
                    cjk: cjk,
                    empty: true,
                  )
                else
                  for (
                    var index = 0;
                    index < content.paragraphs.length;
                    index++
                  ) ...[
                    if (index > 0)
                      const SizedBox(
                        height: DirectoryBookIntroductionStyle.paragraph_gap,
                      ),
                    _paragraph(
                      content.paragraphs[index],
                      index: index,
                      cjk: cjk,
                    ),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// TODO 简介完整展示，不裁切、折叠或改变作者在段内保留的换行。
  Widget _paragraph(
    String text, {
    required int index,
    required bool cjk,
    bool empty = false,
  }) => WindowReservedRegionPadding(
    mode: WindowReservedRegionPaddingMode.heading,
    retain_when_above_viewport: true,
    child: Text(
      text,
      key: ValueKey(
        empty
            ? 'directory_details_empty'
            : 'directory_details_paragraph_$index',
      ),
      style: DirectoryBookIntroductionStyle.paragraph(
        dark: is_dark,
        cjk: cjk,
        empty: empty,
      ),
    ),
  );
}
