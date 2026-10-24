// ignore_for_file: non_constant_identifier_names

import 'package:app/components/work_section_card/index.dart';
import 'package:app/pages/comics/detail/widgets/hot_comments/style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 标题和全部入口均按可用宽度换行，窄屏及大字号不压缩文字或触控区域。
class ComicHotCommentsHeader extends StatelessWidget {
  const ComicHotCommentsHeader({
    super.key,
    required this.is_dark,
    required this.on_comments,
    this.count,
  });

  final bool is_dark;
  final VoidCallback on_comments;
  final int? count;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      ComicHotCommentsStyle.horizontal_padding,
      ComicHotCommentsStyle.header_top,
      ComicHotCommentsStyle.horizontal_padding,
      0,
    ),
    child: LayoutBuilder(
      builder: (context, constraints) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WorkSectionHeading(
                  title: tr('comics.hot_comments'),
                  is_dark: is_dark,
                ),
                if (count != null) ...[
                  const SizedBox(height: ComicHotCommentsStyle.title_count_gap),
                  Text(
                    tr('comment.count_label', namedArgs: {'count': '$count'}),
                    style: TextStyle(
                      color: ComicHotCommentsStyle.secondary(is_dark),
                      fontSize: ComicHotCommentsStyle.localized_size(
                        context,
                        ComicHotCommentsStyle.count_size_cjk,
                        ComicHotCommentsStyle.count_size_alphabetic,
                      ),
                      fontWeight: ComicHotCommentsStyle.regular,
                      height: ComicHotCommentsStyle.line_height(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: ComicHotCommentsStyle.header_gap),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth:
                  constraints.maxWidth *
                  ComicHotCommentsStyle.action_max_fraction,
            ),
            child: TextButton(
              key: const ValueKey<String>('comic_detail_comments'),
              onPressed: on_comments,
              style: TextButton.styleFrom(
                foregroundColor: ComicHotCommentsStyle.secondary(is_dark),
                minimumSize: const Size(
                  0,
                  ComicHotCommentsStyle.control_min_height,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      tr('comics.see_all'),
                      style: TextStyle(
                        fontSize: ComicHotCommentsStyle.localized_size(
                          context,
                          ComicHotCommentsStyle.action_size_cjk,
                          ComicHotCommentsStyle.action_size_alphabetic,
                        ),
                        fontWeight: ComicHotCommentsStyle.regular,
                        height: ComicHotCommentsStyle.line_height(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: ComicHotCommentsStyle.action_icon_gap),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: ComicHotCommentsStyle.action_icon,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
