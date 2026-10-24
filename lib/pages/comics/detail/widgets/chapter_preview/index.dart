// ignore_for_file: non_constant_identifier_names

import 'package:app/config/color_config.dart';
import 'package:app/models/comics.dart';
import 'package:app/pages/comics/detail/style.dart';
import 'package:app/pages/comics/detail/widgets/chapter_preview/chapter_card.dart';
import 'package:app/pages/comics/detail/widgets/chapter_preview/style.dart';
import 'package:app/pages/comics/widgets/chapter_location_button/index.dart';
import 'package:app/util/language_util/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

part 'logic.dart';

/// TODO 详情顶部的可横滑章节带，当前阅读章离开视口时提供动画定位入口。
class ComicChapterPreview extends StatefulWidget {
  const ComicChapterPreview({
    super.key,
    required this.chapters,
    required this.completed,
    required this.on_chapters,
    required this.on_open,
    this.current_chapter_id,
    this.horizontal_padding = 0,
  });

  final List<ComicChapter> chapters;
  final bool completed;
  final VoidCallback on_chapters;
  final ValueChanged<ComicChapter> on_open;
  final int? current_chapter_id;

  /// 边距属于滚动内容，卡片可以一直移动到窗口边缘。
  final double horizontal_padding;

  @override
  State<ComicChapterPreview> createState() => _ComicChapterPreviewState();
}

class _ComicChapterPreviewState extends State<ComicChapterPreview>
    with _ComicChapterPreviewLogic {
  @override
  Widget build(BuildContext context) {
    final cjk = LanguageUtil.is_cjk_language(
      Localizations.localeOf(context).languageCode,
    );
    final line_height = cjk
        ? ComicChapterPreviewStyle.line_height_cjk
        : ComicChapterPreviewStyle.line_height_alphabetic;
    final count = tr(
      'comics.chapter_count_label',
      namedArgs: {'count': '${widget.chapters.length}'},
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.horizontal_padding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: ComicChapterPreviewStyle.status_dot_size,
                      height: ComicChapterPreviewStyle.status_dot_size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.completed
                            ? ColorConstants.successColor
                            : ColorConstants.themeColor,
                      ),
                    ),
                    const SizedBox(width: ComicChapterPreviewStyle.header_gap),
                    Flexible(
                      child: Text(
                        tr(
                          widget.completed
                              ? 'comics.completed'
                              : 'comics.ongoing',
                        ),
                        key: const ValueKey('comic_serialization_status'),
                        style: TextStyle(
                          fontSize: cjk
                              ? ComicChapterPreviewStyle.heading_size_cjk
                              : ComicChapterPreviewStyle
                                    .heading_size_alphabetic,
                          height: line_height,
                          fontWeight: ComicDetailStyle.weight_medium,
                          color: ComicDetailStyle.ink(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: ComicChapterPreviewStyle.header_gap),
              ComicChapterLocationButton(
                key: const ValueKey('comic_chapter_preview_location'),
                show: show_location_button,
                is_dark: Theme.of(context).brightness == Brightness.dark,
                on_tap: scroll_to_current,
              ),
              Flexible(
                child: TextButton(
                  key: const ValueKey('comic_detail_chapters'),
                  onPressed: widget.on_chapters,
                  style: TextButton.styleFrom(
                    padding: ComicChapterPreviewStyle.action_padding,
                    minimumSize: const Size(
                      0,
                      ComicChapterPreviewStyle.minimum_action_height,
                    ),
                    foregroundColor: ComicDetailStyle.muted(context),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          count,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: cjk
                                ? ComicChapterPreviewStyle.count_size_cjk
                                : ComicChapterPreviewStyle
                                      .count_size_alphabetic,
                            height: line_height,
                            fontWeight: ComicDetailStyle.weight_regular,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: ComicChapterPreviewStyle.arrow_size,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: ComicChapterPreviewStyle.header_gap),
        if (widget.chapters.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.horizontal_padding,
            ).add(ComicChapterPreviewStyle.action_padding),
            child: Text(
              tr('comics.empty_chapters'),
              style: TextStyle(color: ComicDetailStyle.muted(context)),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final width =
                  ((constraints.maxWidth - widget.horizontal_padding * 2) *
                          ComicChapterPreviewStyle.card_width_ratio)
                      .clamp(
                        ComicChapterPreviewStyle.card_min_width,
                        ComicChapterPreviewStyle.card_max_width,
                      )
                      .toDouble();
              update_rail_layout(
                viewport_width: constraints.maxWidth,
                card_width: width,
              );
              final scaler = MediaQuery.textScalerOf(context);
              final title_size = cjk
                  ? ComicChapterPreviewStyle.title_size_cjk
                  : ComicChapterPreviewStyle.title_size_alphabetic;
              final height =
                  width / ComicChapterPreviewStyle.image_ratio +
                  ComicChapterPreviewStyle.title_padding_v * 2 +
                  scaler.scale(title_size) *
                      line_height *
                      ComicChapterPreviewStyle.title_lines +
                  ComicChapterPreviewStyle.font_metric_allowance +
                  ComicChapterPreviewStyle.list_padding_top +
                  ComicChapterPreviewStyle.list_padding_bottom;
              return SizedBox(
                height: height,
                child: ListView.builder(
                  key: const ValueKey('comic_chapter_previews'),
                  controller: scroll_controller,
                  scrollDirection: Axis.horizontal,
                  primary: false,
                  padding: EdgeInsets.fromLTRB(
                    widget.horizontal_padding,
                    ComicChapterPreviewStyle.list_padding_top,
                    widget.horizontal_padding,
                    ComicChapterPreviewStyle.list_padding_bottom,
                  ),
                  itemExtent: width + ComicChapterPreviewStyle.gap,
                  itemCount: widget.chapters.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(
                      right: ComicChapterPreviewStyle.gap,
                    ),
                    child: ComicChapterPreviewCard(
                      key: ValueKey(
                        'comic_chapter_preview_${widget.chapters[index].id}',
                      ),
                      chapter: widget.chapters[index],
                      number: index + 1,
                      is_cjk: cjk,
                      selected:
                          widget.chapters[index].id ==
                          widget.current_chapter_id,
                      on_open: () => widget.on_open(widget.chapters[index]),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
