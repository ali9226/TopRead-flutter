import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'style.dart';

/// TODO 标签只表达作品分类，同一主题色、完整换行，不表现为可点击筛选器。
class DirectoryBookGenreTags extends StatelessWidget {
  const DirectoryBookGenreTags({
    super.key,
    required this.tags,
    required this.is_dark,
    required this.is_cjk,
  });

  final List<String> tags;
  final bool is_dark;
  final bool is_cjk;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Semantics(
        header: true,
        child: Text(
          tr('comics.genres'),
          key: const ValueKey('directory_details_genres_heading'),
          style: DirectoryBookIntroductionStyle.genres_heading(
            dark: is_dark,
            cjk: is_cjk,
          ),
        ),
      ),
      const SizedBox(height: DirectoryBookIntroductionStyle.genres_heading_gap),
      Wrap(
        key: const ValueKey('directory_details_genres'),
        spacing: DirectoryBookIntroductionStyle.tag_spacing,
        runSpacing: DirectoryBookIntroductionStyle.tag_run_spacing,
        children: [
          for (final tag in tags)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DirectoryBookIntroductionStyle.tag_padding_h,
                vertical: DirectoryBookIntroductionStyle.tag_padding_v,
              ),
              decoration: BoxDecoration(
                color: DirectoryBookIntroductionStyle.tag_background(is_dark),
                border: Border.all(
                  color: DirectoryBookIntroductionStyle.tag_border(is_dark),
                  width: DirectoryBookIntroductionStyle.tag_border_width,
                ),
                borderRadius: BorderRadius.circular(
                  DirectoryBookIntroductionStyle.tag_radius,
                ),
              ),
              child: Text(
                tag,
                style: DirectoryBookIntroductionStyle.tag(
                  dark: is_dark,
                  cjk: is_cjk,
                ),
              ),
            ),
        ],
      ),
    ],
  );
}
